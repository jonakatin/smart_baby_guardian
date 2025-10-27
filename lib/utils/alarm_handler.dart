import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class AlarmHandler {
  AlarmHandler._();
  static final AlarmHandler instance = AlarmHandler._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> init() async {
    await _player.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> startAlarm({double volume = 1.0, bool vibrate = true}) async {
    // Play asset (loop)
    await _player.setVolume(volume.clamp(0.0, 1.0));
    await _player.play(AssetSource('sounds/high_alarm.wav'));
    if (vibrate && await Vibration.hasVibrator()) {
      Vibration.vibrate(
        pattern: [300, 200, 300, 200],
        intensities: [128, 0, 128, 0],
        repeat: 0,
      );
    }
  }

  Future<void> stopAlarm() async {
    await _player.stop();
    if (await Vibration.hasVibrator()) {
      Vibration.cancel();
    }
  }
}
