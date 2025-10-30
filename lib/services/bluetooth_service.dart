import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../models/reading.dart';
import 'storage_service.dart';

class BluetoothService extends ChangeNotifier {
  BluetoothService();

  static const String targetDeviceName = 'SmartBabyGuard';

  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  BluetoothDevice? _device;

  final StreamController<Reading> _dataController =
      StreamController.broadcast();
  StreamSubscription<Uint8List>? _inputSubscription;
  String _incomingBuffer = '';

  Reading? _latestReading;
  String? _bannerMessage;
  bool _isConnecting = false;
  bool _autoReconnecting = false;
  bool _manualDisconnect = false;

  Stream<Reading> get readingsStream => _dataController.stream;
  Reading? get latestReading => _latestReading;
  BluetoothDevice? get device => _device;
  bool get isConnected => _connection?.isConnected ?? false;
  bool get isConnecting => _isConnecting;
  bool get isAutoReconnecting => _autoReconnecting;
  String? get bannerMessage => _bannerMessage;

  Future<void> ensureOn() async {
    final enabled = await _bluetooth.isEnabled ?? false;
    if (!enabled) {
      await _bluetooth.requestEnable();
    }
  }

  Future<void> connectTo([String deviceName = targetDeviceName]) async {
    if (_isConnecting) {
      return;
    }
    _manualDisconnect = false;
    _isConnecting = true;
    _bannerMessage = null;
    notifyListeners();
    try {
      await ensureOn();
      final devices = await _bluetooth.getBondedDevices();
      final BluetoothDevice device = devices.firstWhere(
        (d) => d.name == deviceName,
        orElse: () => throw Exception('Device not paired'),
      );
      final connection = await BluetoothConnection.toAddress(device.address);
      _device = device;
      _connection = connection;
      _isConnecting = false;
      _autoReconnecting = false;
      _bannerMessage = null;
      notifyListeners();
      _listenToIncoming();
    } catch (error) {
      _isConnecting = false;
      _connection = null;
      _device = null;
      _bannerMessage = 'Disconnected – Tap to Reconnect';
      notifyListeners();
      rethrow;
    }
  }

  void _listenToIncoming() {
    _inputSubscription?.cancel();
    _inputSubscription = _connection?.input?.listen((Uint8List data) {
      _incomingBuffer += utf8.decode(data);
      _processIncomingBuffer();
    }, onDone: _handleDisconnected, onError: (_) => _handleDisconnected());
  }

  void handleBluetoothData(String data) {
    if (data.contains('TEMP:') && data.contains('DIST:')) {
      final parts = data.split(',');
      if (parts.length >= 2) {
        final tempPart = parts[0];
        final distPart = parts[1];
        final temp =
            double.tryParse(tempPart.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        final dist =
            double.tryParse(distPart.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        if (temp > 0 && dist > 0) {
          _onNewReading(temp, dist);
        }
      }
    }
  }

  void _onNewReading(double temperature, double distance) {
    final reading = Reading(
      timestamp: DateTime.now(),
      temperature: double.parse(temperature.toStringAsFixed(1)),
      distance: double.parse(distance.toStringAsFixed(1)),
    );
    _latestReading = reading;
    _dataController.add(reading);
    unawaited(StorageService.instance.addReading(reading));
    notifyListeners();
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _bannerMessage = 'Disconnected – Tap to Reconnect';
    _autoReconnecting = false;
    _isConnecting = false;
    await _disposeConnection();
    notifyListeners();
  }

  void _handleDisconnected() {
    _disposeConnection();
    _isConnecting = false;
    if (_manualDisconnect) {
      _autoReconnecting = false;
      _bannerMessage = 'Disconnected – Tap to Reconnect';
      notifyListeners();
      return;
    }
    _startAutoReconnect();
  }

  Future<void> _disposeConnection() async {
    await _inputSubscription?.cancel();
    _inputSubscription = null;
    await _connection?.finish();
    _connection = null;
    _device = null;
    _incomingBuffer = '';
  }

  void _startAutoReconnect() {
    if (_autoReconnecting) {
      return;
    }
    _autoReconnecting = true;
    _bannerMessage = 'Reconnecting to SmartBabyGuard…';
    notifyListeners();
    unawaited(_autoReconnect());
  }

  Future<void> _autoReconnect() async {
    for (int attempt = 0; attempt < 3; attempt++) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        await connectTo(targetDeviceName);
        if (isConnected) {
          break;
        }
      } catch (_) {}
    }
    if (isConnected) {
      _autoReconnecting = false;
      _bannerMessage = null;
    } else {
      _autoReconnecting = false;
      _bannerMessage = 'Disconnected – Tap to Reconnect';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _dataController.close();
    _disposeConnection();
    super.dispose();
  }

  void _processIncomingBuffer() {
    final regex = RegExp(r'TEMP:[^,]+,\s*DIST:[^\r\n]+');
    final matches = regex.allMatches(_incomingBuffer).toList();
    if (matches.isEmpty) {
      return;
    }
    var processedIndex = 0;
    for (final match in matches) {
      final message = _incomingBuffer.substring(match.start, match.end).trim();
      handleBluetoothData(message);
      processedIndex = match.end;
    }
    _incomingBuffer = _incomingBuffer
        .substring(processedIndex)
        .replaceFirst(RegExp(r'^[\r\n]+'), '');
  }
}
