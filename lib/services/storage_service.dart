import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/sensor_record.dart';

class StorageService extends ChangeNotifier {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _historyBoxName = 'sensor_history';
  static const String _settingsBoxName = 'settings_box';

  static const String _themeModeKey = 'themeMode';
  static const String _alarmVolumeKey = 'alarmVolume';
  static const String _autoAckKey = 'autoAck';
  static const String _autoConnectKey = 'autoConnect';
  static const String _updateRateKey = 'updateRateSec';
  static const String _soundAlertsKey = 'soundAlerts';
  static const String _flashAlertsKey = 'flashAlerts';
  static const String _vibrateAlertsKey = 'vibrateAlerts';
  static const String _temperatureThresholdKey = 'temperatureThreshold';
  static const String _distanceThresholdKey = 'distanceThreshold';
  static const String _soundFilePathKey = 'soundFilePath';

  static const int _maxRecords = 500;

  late Box<SensorRecord> _historyBox;
  late Box<dynamic> _settingsBox;

  ValueListenable<Box<SensorRecord>> get listenable => _historyBox.listenable();
  Box<dynamic> get settingsBox => _settingsBox;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(SensorRecordAdapter().typeId)) {
      Hive.registerAdapter(SensorRecordAdapter());
    }
    _historyBox = await Hive.openBox<SensorRecord>(_historyBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
  }

  Future<void> addRecord(SensorRecord record) async {
    await _historyBox.add(record);
    if (_historyBox.length > _maxRecords) {
      final overflow = _historyBox.length - _maxRecords;
      if (overflow > 0) {
        final keys = _historyBox.keys.cast<int>().toList()..sort();
        await _historyBox.deleteAll(keys.take(overflow));
      }
    }
    notifyListeners();
  }

  List<SensorRecord> getRecords({DateTime? since}) {
    final items = _historyBox.values.toList();
    items.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (since == null) {
      return items;
    }
    return items
        .where((record) => !record.timestamp.isBefore(since))
        .toList();
  }

  Future<void> clearHistory() async {
    await _historyBox.clear();
    notifyListeners();
  }

  ThemeMode get themeMode {
    final stored =
        _settingsBox.get(_themeModeKey, defaultValue: ThemeMode.system.name) as String;
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

  double get temperatureThreshold =>
      (_settingsBox.get(_temperatureThresholdKey) as double?) ?? 27.0;

  set temperatureThreshold(double value) {
    _settingsBox.put(_temperatureThresholdKey, value);
    notifyListeners();
  }

  double get distanceThreshold =>
      (_settingsBox.get(_distanceThresholdKey) as double?) ?? 15.0;

  set distanceThreshold(double value) {
    _settingsBox.put(_distanceThresholdKey, value);
    notifyListeners();
  }

  String? get soundFilePath => _settingsBox.get(_soundFilePathKey) as String?;

  set soundFilePath(String? path) {
    if (path == null) {
      _settingsBox.delete(_soundFilePathKey);
    } else {
      _settingsBox.put(_soundFilePathKey, path);
    }
    notifyListeners();
  }

  Future<void> resetSettings() async {
    await _settingsBox.clear();
    notifyListeners();
  }
}
