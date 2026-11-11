import 'package:audioplayers/audioplayers.dart';

/// Backsound latihan yang diputar berulang selama sesi berlangsung.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  bool _started = false;

  Future<void> start() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.35);
      await _player.play(AssetSource('audio/backsound.wav'));
      _started = true;
    } catch (_) {
      _started = false;
    }
  }

  Future<void> pause() async {
    if (!_started) return;
    try {
      await _player.pause();
    } catch (_) {
      // diabaikan
    }
  }

  Future<void> resume() async {
    if (!_started) return;
    try {
      await _player.resume();
    } catch (_) {
      // diabaikan
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // diabaikan
    }
    _started = false;
  }

  Future<void> setMuted(bool muted) async {
    try {
      await _player.setVolume(muted ? 0 : 0.35);
    } catch (_) {
      // diabaikan
    }
  }
}
