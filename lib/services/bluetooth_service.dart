import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/sensor_record.dart';
import '../theme/app_theme.dart';
import 'storage_service.dart';

class BluetoothService extends ChangeNotifier {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  BluetoothDevice? _device;
  bool _connecting = false;
  bool _acknowledged = false;
  Timer? _simTimer;

  final StreamController<SensorRecord> _dataCtrl = StreamController.broadcast();
  Stream<SensorRecord> get dataStream => _dataCtrl.stream;

  BluetoothDevice? get device => _device;
  bool get isConnected => _connection?.isConnected ?? false;
  bool get isConnecting => _connecting;
  bool get acknowledged => _acknowledged;

  void setAcknowledged(bool v) {
    _acknowledged = v;
    notifyListeners();
  }

  Future<void> ensureOn() async {
    if (!(await _bluetooth.isEnabled ?? false)) {
      await _bluetooth.requestEnable();
    }
  }

  Future<List<BluetoothDevice>> discover() async {
    await ensureOn();
    return await _bluetooth.getBondedDevices();
  }

  Future<void> connect(BluetoothDevice device) async {
    await ensureOn();
    _connecting = true;
    notifyListeners();
    try {
      _device = device;
      _connection = await BluetoothConnection.toAddress(device.address);
      _connecting = false;
      notifyListeners();
      _listenToIncoming();
    } catch (e) {
      _connecting = false;
      notifyListeners();
      rethrow;
    }
  }

  void _listenToIncoming() {
    _connection?.input?.listen((Uint8List data) async {
      final text = utf8.decode(data);
      for (final line in const LineSplitter().convert(text)) {
        try {
          final map = jsonDecode(line) as Map<String, dynamic>;
          _handleJson(map);
        } catch (_) {}
      }
    }).onDone(() {
      _connection = null;
      notifyListeners();
      if (kDebugMode) _startSimulator();
    });

    if (kDebugMode && !isConnected) _startSimulator();
  }

  void _handleJson(Map<String, dynamic> map) async {
    final rec = SensorRecord.fromJson(map);
    await StorageService.instance.addRecord(rec);
    _dataCtrl.add(rec);
  }

  Future<void> disconnect() async {
    _simTimer?.cancel();
    _simTimer = null;
    await _connection?.finish();
    _connection = null;
    _device = null;
    notifyListeners();
  }

  // ─────────── Simulation (Debug only) ───────────
  void _startSimulator() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(
      Duration(seconds: StorageService.instance.updateRateSec),
      (_) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final temp = 25 + 10 * (0.5 + 0.5 * (now % 7000) / 7000);
        final dist = 10 + 50 * ((now % 9000) / 9000);
        final tilt = (now % 3000) / 100.0; // simulate 0–30°
        final double riskScore =
            (100 - dist).clamp(0, 100) * 0.4 + (temp - 20) * 3;
        final int risk = riskScore.clamp(0, 100).round();
        final status = AppTheme.statusText(risk);
        final map = {
          "distance": double.parse(dist.toStringAsFixed(1)),
          "temperature": double.parse(temp.toStringAsFixed(1)),
          "tilt": double.parse(tilt.toStringAsFixed(1)),
          "risk": risk,
          "status": status,
        };
        _handleJson(map);
      },
    );
  }

  /// Allows injecting fake JSON during tests.
  @visibleForTesting
  void injectTestData(Map<String, dynamic> json) => _handleJson(json);

  /// Cleans up timers and streams (for tests).
  @visibleForTesting
  Future<void> disposeForTest() async {
    _simTimer?.cancel();
    await _dataCtrl.close();
  }
}
