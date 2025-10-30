import 'dart:async';

import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';

import '../models/reading.dart';
import 'alarm_handler.dart';
import 'storage_service.dart';

class AlertService extends ChangeNotifier {
  AlertService() {
    _loadFromStorage();
    unawaited(_alarmHandler.init());
  }

  final AlarmHandler _alarmHandler = AlarmHandler.instance;
  final StorageService _storage = StorageService.instance;

  bool _alertActive = false;
  DateTime? _acknowledgedUntil;

  bool _soundEnabled = true;
  bool _flashEnabled = true;
  bool _vibrateEnabled = true;
  double _volume = 1;

  bool get soundEnabled => _soundEnabled;
  bool get flashEnabled => _flashEnabled;
  bool get vibrateEnabled => _vibrateEnabled;
  bool get alertActive => _alertActive;
  double get volume => _volume;

  Future<void> handleReading(Reading reading) async {
    final bool needsAlert = reading.temperature > 37 || reading.distance < 15;
    if (!needsAlert) {
      _acknowledgedUntil = null;
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
      if (_flashEnabled) {
        await _toggleTorch(true);
      }
      await _updateAlarmOutputs();
      notifyListeners();
      return;
    }

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
      unawaited(_toggleTorch(value));
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
    if (_alertActive && _soundEnabled) {
      unawaited(_alarmHandler.updateVolume(_volume));
    }
    notifyListeners();
  }

  void reloadFromStorage() {
    _loadFromStorage();
    if (_alertActive) {
      if (_flashEnabled) {
        unawaited(_toggleTorch(true));
      } else {
        unawaited(_toggleTorch(false));
      }
      unawaited(_updateAlarmOutputs());
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
    if (!_soundEnabled && !_vibrateEnabled) {
      await _alarmHandler.stopAlarm();
      return;
    }
    final double volume = _soundEnabled ? _volume : 0;
    await _alarmHandler.startAlarm(volume: volume, vibrate: _vibrateEnabled);
  }

  Future<void> _toggleTorch(bool enable) async {
    try {
      if (!await TorchLight.isTorchAvailable()) {
        return;
      }
      if (enable) {
        await TorchLight.enableTorch();
      } else {
        await TorchLight.disableTorch();
      }
    } catch (_) {}
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
