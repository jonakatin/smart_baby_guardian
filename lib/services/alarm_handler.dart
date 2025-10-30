import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class AlarmHandler {
  AlarmHandler._();

  static final AlarmHandler instance = AlarmHandler._();

  static const MethodChannel _channel = MethodChannel('com.smartbabyguard/alarm');
  static const String _alarmAsset = 'sounds/high_alarm.wav';
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    try {
      await _channel.invokeMethod('initialize', <String, Object>{'asset': _alarmAsset});
      _initialized = true;
    } on PlatformException {
      // Ignore and rely on best-effort behaviour on unsupported platforms.
    }
  }

  Future<void> startAlarm({double volume = 1.0, bool vibrate = true}) async {
    final double clamped = volume.clamp(0.0, 1.0);
    try {
      await _channel.invokeMethod('start', <String, Object>{
        'asset': _alarmAsset,
        'volume': clamped,
      });
    } on PlatformException {
      // Ignore failures to keep the alarm workflow responsive.
    }
    if (vibrate && (await Vibration.hasVibrator())) {
      Vibration.vibrate(
        pattern: const [300, 200, 300, 200],
        intensities: const [128, 0, 128, 0],
        repeat: 0,
      );
    }
  }

  Future<void> updateVolume(double volume) async {
    final double clamped = volume.clamp(0.0, 1.0);
    try {
      await _channel.invokeMethod('setVolume', <String, Object>{'volume': clamped});
    } on PlatformException {
      // No-op on unsupported platforms.
    }
  }

  Future<void> stopAlarm() async {
    try {
      await _channel.invokeMethod('stop');
    } on PlatformException {
      // Ignore failures.
    }
    if (await Vibration.hasVibrator()) {
      Vibration.cancel();
    }
  }

  Future<void> dispose() async {
    await stopAlarm();
    try {
      await _channel.invokeMethod('dispose');
    } on PlatformException {
      // Ignored.
    }
  }
}
