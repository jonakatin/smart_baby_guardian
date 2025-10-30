import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';

import '../models/reading.dart';
import 'storage_service.dart';

class AlertService extends ChangeNotifier {
  AlertService() {
    _loadFromStorage();
  }

  final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  Timer? _vibrationTimer;
  bool _alertActive = false;

  bool _soundEnabled = true;
  bool _flashEnabled = true;
  bool _vibrateEnabled = true;
  double _volume = 1;

  final StorageService _storage = StorageService.instance;

  bool get soundEnabled => _soundEnabled;
  bool get flashEnabled => _flashEnabled;
  bool get vibrateEnabled => _vibrateEnabled;
  bool get alertActive => _alertActive;
  double get volume => _volume;

  Future<void> handleReading(Reading reading) async {
    final bool needsAlert = reading.temperature > 37 || reading.distance < 15;
    if (needsAlert) {
      await _startAlert();
    } else {
      await _stopAlert();
    }
  }

  Future<void> _startAlert() async {
    if (_alertActive) {
      return;
    }
    _alertActive = true;
    if (_soundEnabled) {
      try {
        await _player.play(
          AssetSource('sounds/high_alarm.wav'),
          volume: _volume,
        );
      } catch (_) {}
    }
    if (_flashEnabled) {
      await _toggleTorch(true);
    }
    if (_vibrateEnabled) {
      _startVibration();
    }
    notifyListeners();
  }

  Future<void> _stopAlert() async {
    if (!_alertActive) {
      return;
    }
    _alertActive = false;
    try {
      await _player.stop();
    } catch (_) {}
    await _toggleTorch(false);
    _stopVibration();
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    _storage.soundAlerts = value;
    if (!value) {
      _player.stop();
    } else if (_alertActive) {
      unawaited(_player.play(AssetSource('sounds/high_alarm.wav'), volume: _volume));
    }
    notifyListeners();
  }

  void setFlashEnabled(bool value) {
    _flashEnabled = value;
    _storage.flashAlerts = value;
    if (!value) {
      unawaited(_toggleTorch(false));
    } else if (_alertActive) {
      unawaited(_toggleTorch(true));
    }
    notifyListeners();
  }

  void setVibrateEnabled(bool value) {
    _vibrateEnabled = value;
    _storage.vibrateAlerts = value;
    if (!value) {
      _stopVibration();
    } else if (_alertActive) {
      _startVibration();
    }
    notifyListeners();
  }

  void setVolume(double value) {
    _volume = value.clamp(0, 1).toDouble();
    _storage.alarmVolume = _volume;
    if (_alertActive && _soundEnabled) {
      unawaited(_player.setVolume(_volume));
    }
    notifyListeners();
  }

  void reloadFromStorage() {
    _loadFromStorage();
    if (_alertActive) {
      if (_soundEnabled) {
        unawaited(_player.setVolume(_volume));
      } else {
        unawaited(_player.stop());
      }
      if (_flashEnabled) {
        unawaited(_toggleTorch(true));
      } else {
        unawaited(_toggleTorch(false));
      }
      if (_vibrateEnabled) {
        _startVibration();
      } else {
        _stopVibration();
      }
    }
    notifyListeners();
  }

  Future<void> disposeAlert() async {
    try {
      await _player.dispose();
    } catch (_) {}
    _stopVibration();
    await _toggleTorch(false);
  }

  void _startVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_vibrateEnabled) {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator) {
          Vibration.vibrate(pattern: const [0, 300, 200, 300]);
        }
      }
    });
  }

  void _stopVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    Vibration.cancel();
  }

  Future<void> _toggleTorch(bool enable) async {
    try {
      if (!await TorchLight.isTorchAvailable()) {
        return;
      }
      if (enable && _flashEnabled) {
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
