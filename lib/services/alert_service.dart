import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../models/reading.dart';

/// torch_light package not available; provide a minimal stub so code compiles.
/// This stub disables torch functionality — replace with the real package
/// or platform-specific implementation if you need flashlight support.
class TorchLight {
  static Future<bool> isTorchAvailable() async => false;
  static Future<void> enableTorch() async {}
  static Future<void> disableTorch() async {}
}

class AlertService extends ChangeNotifier {
  AlertService();

  final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  Timer? _vibrationTimer;
  bool _alertActive = false;

  bool _soundEnabled = true;
  bool _flashEnabled = true;
  bool _vibrateEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get flashEnabled => _flashEnabled;
  bool get vibrateEnabled => _vibrateEnabled;
  bool get alertActive => _alertActive;

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
        await _player.play(AssetSource('sounds/high_alarm.wav'), volume: 1);
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
    if (!value) {
      _player.stop();
    } else if (_alertActive) {
      unawaited(_player.play(AssetSource('sounds/high_alarm.wav'), volume: 1));
    }
    notifyListeners();
  }

  void setFlashEnabled(bool value) {
    _flashEnabled = value;
    if (!value) {
      unawaited(_toggleTorch(false));
    } else if (_alertActive) {
      unawaited(_toggleTorch(true));
    }
    notifyListeners();
  }

  void setVibrateEnabled(bool value) {
    _vibrateEnabled = value;
    if (!value) {
      _stopVibration();
    } else if (_alertActive) {
      _startVibration();
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
}
