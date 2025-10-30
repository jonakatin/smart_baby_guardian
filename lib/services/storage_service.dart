import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reading.dart';

class StorageService extends ChangeNotifier {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _readingsBoxName = 'readings_box';
  static const String _settingsBoxName = 'settings_box';

  static const String _themeModeKey = 'themeMode';
  static const String _alarmVolumeKey = 'alarmVolume';
  static const String _autoAckKey = 'autoAck';
  static const String _autoConnectKey = 'autoConnect';
  static const String _updateRateKey = 'updateRateSec';
  static const String _soundAlertsKey = 'soundAlerts';
  static const String _flashAlertsKey = 'flashAlerts';
  static const String _vibrateAlertsKey = 'vibrateAlerts';

  late Box<Reading> _readingsBox;
  late Box<dynamic> _settingsBox;

  ValueListenable<Box<Reading>> get listenable => _readingsBox.listenable();
  Box<dynamic> get settingsBox => _settingsBox;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(ReadingAdapter().typeId)) {
      Hive.registerAdapter(ReadingAdapter());
    }
    _readingsBox = await Hive.openBox<Reading>(_readingsBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
  }

  Future<void> addReading(Reading reading) async {
    await _readingsBox.add(reading);
  }

  List<Reading> getReadings() {
    final items = _readingsBox.values.toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> clear() async {
    await _readingsBox.clear();
  }

  ThemeMode get themeMode {
    final stored = _settingsBox.get(_themeModeKey, defaultValue: ThemeMode.system.name) as String;
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  set themeMode(ThemeMode mode) {
    _settingsBox.put(_themeModeKey, mode.name);
    notifyListeners();
  }

  double get alarmVolume => (_settingsBox.get(_alarmVolumeKey) as double?) ?? 1.0;

  set alarmVolume(double value) {
    final clamped = value.clamp(0, 1).toDouble();
    _settingsBox.put(_alarmVolumeKey, clamped);
    notifyListeners();
  }

  bool get autoAck => (_settingsBox.get(_autoAckKey) as bool?) ?? false;

  set autoAck(bool value) {
    _settingsBox.put(_autoAckKey, value);
    notifyListeners();
  }

  bool get autoConnect => (_settingsBox.get(_autoConnectKey) as bool?) ?? true;

  set autoConnect(bool value) {
    _settingsBox.put(_autoConnectKey, value);
    notifyListeners();
  }

  int get updateRateSec => (_settingsBox.get(_updateRateKey) as int?) ?? 1;

  set updateRateSec(int value) {
    _settingsBox.put(_updateRateKey, value);
    notifyListeners();
  }

  bool get soundAlerts => (_settingsBox.get(_soundAlertsKey) as bool?) ?? true;

  set soundAlerts(bool value) {
    _settingsBox.put(_soundAlertsKey, value);
    notifyListeners();
  }

  bool get flashAlerts => (_settingsBox.get(_flashAlertsKey) as bool?) ?? true;

  set flashAlerts(bool value) {
    _settingsBox.put(_flashAlertsKey, value);
    notifyListeners();
  }

  bool get vibrateAlerts => (_settingsBox.get(_vibrateAlertsKey) as bool?) ?? true;

  set vibrateAlerts(bool value) {
    _settingsBox.put(_vibrateAlertsKey, value);
    notifyListeners();
  }

  Future<void> resetSettings() async {
    await _settingsBox.clear();
    notifyListeners();
  }
}
