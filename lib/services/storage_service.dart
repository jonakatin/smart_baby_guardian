import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sensor_record.dart';
import 'package:flutter/material.dart';

class StorageService {
  static final StorageService instance = StorageService._();
  StorageService._();

  late Box<SensorRecord> recordsBox;
  late Box settingsBox;

  final _settingsCtrl = StreamController<void>.broadcast();
  Stream<void> get settingsStream => _settingsCtrl.stream;

  Future<void> init() async {
    await Hive.deleteBoxFromDisk('records');
    recordsBox = await Hive.openBox<SensorRecord>('records');
    settingsBox = await Hive.openBox('settings');

    // Defaults
    settingsBox.putIfAbsent('themeMode', () => 'system');
    settingsBox.putIfAbsent('alarmVolume', () => 1.0);
    settingsBox.putIfAbsent('vibration', () => true);
    settingsBox.putIfAbsent('autoAck', () => false);
    settingsBox.putIfAbsent('autoConnect', () => true);
    settingsBox.putIfAbsent('updateRateSec', () => 1);

    settingsBox.watch().listen((_) => _settingsCtrl.add(null));
  }

  ThemeMode get themeMode {
    final v = (settingsBox.get('themeMode') as String);
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  set themeMode(ThemeMode mode) {
    settingsBox.put(
        'themeMode',
        switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          _ => 'system',
        });
  }

  double get alarmVolume => (settingsBox.get('alarmVolume') as num).toDouble();
  set alarmVolume(double v) =>
      settingsBox.put('alarmVolume', v.clamp(0.0, 1.0));

  bool get vibration => settingsBox.get('vibration') as bool;
  set vibration(bool v) => settingsBox.put('vibration', v);

  bool get autoAck => settingsBox.get('autoAck') as bool;
  set autoAck(bool v) => settingsBox.put('autoAck', v);

  bool get autoConnect => settingsBox.get('autoConnect') as bool;
  set autoConnect(bool v) => settingsBox.put('autoConnect', v);

  int get updateRateSec => settingsBox.get('updateRateSec') as int;
  set updateRateSec(int v) => settingsBox.put('updateRateSec', v);

  Future<void> addRecord(SensorRecord r) async {
    await recordsBox.add(r);
    if (recordsBox.length > 1000) {
      final toDelete = recordsBox.length - 1000;
      final keys = recordsBox.keys.take(toDelete).toList();
      await recordsBox.deleteAll(keys);
    }
  }

  List<SensorRecord> get allDesc =>
      recordsBox.values.toList().reversed.toList();

  Future<void> clearHistory() async => recordsBox.clear();

  (double avgTemp, double avgRisk)? sessionAverages() {
    final data = recordsBox.values;
    if (data.isEmpty) return null;
    final t =
        data.map((e) => e.temperature).reduce((a, b) => a + b) / data.length;
    final r = data.map((e) => e.risk.toDouble()).reduce((a, b) => a + b) /
        data.length;
    return (t, r);
  }
}

extension on Box {
  T putIfAbsent<T>(String key, T Function() ifAbsent) {
    if (containsKey(key)) {
      return get(key) as T;
    }
    final value = ifAbsent();
    put(key, value);
    return value;
  }
}
