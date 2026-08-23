import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Clinical Audio & Sound Feedback Service — JMR Technologies
/// Provides realistic auditory feedback for dial steppers, neutrality flash,
/// incorrect selections, and timer notifications.
class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool soundEnabled = true;

  static Future<void> init() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      if (kDebugMode) {
        print('AudioService init error: ');
      }
    }
  }

  /// Play stepper click / dial tick
  static Future<void> playTick() async {
    if (!soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/test_tick.mp3'));
    } catch (_) {
      // Graceful fallback
    }
  }

  /// Play incorrect answer buzzer
  static Future<void> playWrong() async {
    if (!soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/eyetesting_wrong_selection.mp3'));
    } catch (_) {
      // Graceful fallback
    }
  }

  /// Play success chime / neutrality flash tone
  static Future<void> playSuccess() async {
    if (!soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/dolphin.wav'));
    } catch (_) {
      // Graceful fallback
    }
  }

  /// Play exam timeout alert
  static Future<void> playTimeout() async {
    if (!soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/test_wrongbuzzer.wav'));
    } catch (_) {
      // Graceful fallback
    }
  }

  /// Play rooster reminder alert
  static Future<void> playReminder() async {
    if (!soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/rooster.wav'));
    } catch (_) {
      // Graceful fallback
    }
  }
}
