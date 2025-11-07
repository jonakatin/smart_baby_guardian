import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sensor_record.dart';
import 'alarm_handler.dart';
import 'permission_service.dart';
import 'storage_service.dart';
import 'torch_service.dart';

class AlertService extends ChangeNotifier {
  AlertService() {
    _loadFromStorage();
    unawaited(_alarmHandler.init());
  }

  final AlarmHandler _alarmHandler = AlarmHandler.instance;
  final StorageService _storage = StorageService.instance;
  final TorchService _torchService = TorchService.instance;

  bool _alertActive = false;
  DateTime? _acknowledgedUntil;

  bool _soundEnabled = true;
  bool _flashEnabled = true;
  bool _vibrateEnabled = true;
  double _volume = 1.0;

  bool get soundEnabled => _soundEnabled;
  bool get flashEnabled => _flashEnabled;
  bool get vibrateEnabled => _vibrateEnabled;
  bool get alertActive => _alertActive;
  double get volume => _volume;

  double get temperatureThreshold => _storage.temperatureThreshold;
  double get distanceThreshold => _storage.distanceThreshold;
  String? get soundFilePath => _storage.soundFilePath;

  Future<void> handleReading(SensorRecord record) async {
    final bool trigger = record.temperature > temperatureThreshold &&
        record.distance < distanceThreshold;
    if (!trigger) {
      if (record.distance > distanceThreshold) {
        _acknowledgedUntil = null;
      }
      await _stopAlert();
      return;
    }

    if (_storage.autoAck) {
      acknowledgeAlert();
      return;
    }

    if (_acknowledgedUntil != null &&
        DateTime.now().isBefore(_acknowledgedUntil!)) {
      return;
    }

    await _startAlert();
  }

  Future<void> _startAlert() async {
    if (!_alertActive) {
      _alertActive = true;
      notifyListeners();
    }
    await _ensurePermissions();
    await _updateAlarmOutputs();
    if (_flashEnabled) {
      await _toggleTorch(true);
    }
  }

  Future<void> _stopAlert() async {
    if (!_alertActive) {
      return;
    }
    _alertActive = false;
    await _alarmHandler.stopAlarm();
    await _toggleTorch(false);
    notifyListeners();
  }

  void acknowledgeAlert({Duration duration = const Duration(minutes: 2)}) {
    _acknowledgedUntil = DateTime.now().add(duration);
    unawaited(_stopAlert());
  }

  void setSoundEnabled(bool value) {
    if (_soundEnabled == value) {
      return;
    }
    _soundEnabled = value;
    _storage.soundAlerts = value;
    if (_alertActive) {
      unawaited(_updateAlarmOutputs());
    }
    notifyListeners();
  }

  void setFlashEnabled(bool value) {
    if (_flashEnabled == value) {
      return;
    }
    _flashEnabled = value;
    _storage.flashAlerts = value;
    if (_alertActive) {
      unawaited(() async {
        if (value) {
          await _ensurePermissions(requestTorch: true);
          await _toggleTorch(true);
        } else {
          await _toggleTorch(false);
        }
      }());
    }
    notifyListeners();
  }

  void setVibrateEnabled(bool value) {
    if (_vibrateEnabled == value) {
      return;
    }
    _vibrateEnabled = value;
    _storage.vibrateAlerts = value;
    if (_alertActive) {
      unawaited(_updateAlarmOutputs());
    }
    notifyListeners();
  }

  void setVolume(double value) {
    final double clamped = value.clamp(0, 1).toDouble();
    if (_volume == clamped) {
      return;
    }
    _volume = clamped;
    _storage.alarmVolume = _volume;
    if (_alertActive) {
      unawaited(_updateAlarmOutputs());
    }
    notifyListeners();
  }

  void setTemperatureThreshold(double value) {
    _storage.temperatureThreshold = value;
    notifyListeners();
  }

  void setDistanceThreshold(double value) {
    _storage.distanceThreshold = value;
    notifyListeners();
  }

  Future<void> setSoundFilePath(String? path) async {
    _storage.soundFilePath = path;
    if (_alertActive) {
      await _updateAlarmOutputs();
    }
    notifyListeners();
  }

  void reloadFromStorage() {
    _loadFromStorage();
    if (_alertActive) {
      unawaited(_updateAlarmOutputs());
      unawaited(_toggleTorch(_flashEnabled));
    }
    notifyListeners();
  }

  Future<void> disposeAlert() async {
    await _alarmHandler.dispose();
    await _toggleTorch(false);
  }

  Future<void> _updateAlarmOutputs() async {
    if (!_alertActive) {
      return;
    }
    final String? path = _soundEnabled ? _storage.soundFilePath : null;
    await _alarmHandler.startAlarm(
      soundPath: path,
      volume: _volume,
      vibrate: _vibrateEnabled,
    );
  }

  Future<void> _toggleTorch(bool enable) async {
    try {
      if (!await _torchService.isTorchAvailable()) {
        return;
      }
      if (enable) {
        await _torchService.enableTorch();
      } else {
        await _torchService.disableTorch();
      }
    } catch (_) {}
  }

  Future<void> _ensurePermissions({bool requestTorch = false}) async {
    await PermissionService.requestBluetoothPermissions();
    if (_soundEnabled && _storage.soundFilePath != null) {
      await PermissionService.requestStoragePermission();
    }
    if (_vibrateEnabled) {
      await PermissionService.requestVibrationPermission();
    }
    if (requestTorch || _flashEnabled) {
      await PermissionService.requestCameraPermission();
    }
  }

  @override
  void dispose() {
    unawaited(disposeAlert());
    super.dispose();
  }

  void _loadFromStorage() {
    _soundEnabled = _storage.soundAlerts;
    _flashEnabled = _storage.flashAlerts;
    _vibrateEnabled = _storage.vibrateAlerts;
    _volume = _storage.alarmVolume;
  }
}
