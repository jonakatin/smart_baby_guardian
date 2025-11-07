import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class AlarmHandler {
  AlarmHandler._();

  static final AlarmHandler instance = AlarmHandler._();

  static const MethodChannel _channel =
      MethodChannel('com.smarttemperatureguard/alarm');

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  String? _activeSource;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    await _player.setLoopMode(LoopMode.one);
    _initialized = true;
  }

  Future<void> startAlarm({
    String? soundPath,
    double volume = 1.0,
    bool vibrate = true,
  }) async {
    await init();
    final double clamped = volume.clamp(0, 1).toDouble();
    await _player.setVolume(clamped);

    if (soundPath != null && soundPath.isNotEmpty) {
      await _playSound(soundPath);
    } else {
      await _player.stop();
      _activeSource = null;
    }

    if (vibrate) {
      try {
        await _channel.invokeMethod('startVibration');
      } on PlatformException catch (error) {
        debugPrint('Vibration start failed: ${error.message}');
      }
    } else {
      await _stopVibration();
    }
  }

  Future<void> updateVolume(double volume) async {
    final double clamped = volume.clamp(0, 1).toDouble();
    await _player.setVolume(clamped);
  }

  Future<void> stopAlarm() async {
    await _player.stop();
    _activeSource = null;
    await _stopVibration();
  }

  Future<void> dispose() async {
    await stopAlarm();
    await _player.dispose();
  }

  Future<void> _playSound(String path) async {
    if (_activeSource == path && _player.playing) {
      return;
    }
    try {
      if (_activeSource != path) {
        await _player.stop();
        if (path.startsWith('content://')) {
          await _player.setAudioSource(AudioSource.uri(Uri.parse(path)));
        } else {
          final file = File(path);
          if (await file.exists()) {
            await _player.setAudioSource(AudioSource.uri(Uri.file(file.path)));
          } else {
            await _player.setAudioSource(AudioSource.uri(Uri.parse(path)));
          }
        }
        _activeSource = path;
      }
      if (!_player.playing) {
        await _player.seek(Duration.zero);
        await _player.play();
      }
    } catch (error, stackTrace) {
      debugPrint('Unable to play alarm sound: $error');
      debugPrintStack(stackTrace: stackTrace);
      _activeSource = null;
    }
  }

  Future<void> _stopVibration() async {
    try {
      await _channel.invokeMethod('stopVibration');
    } on PlatformException catch (error) {
      debugPrint('Vibration stop failed: ${error.message}');
    }
  }
}
