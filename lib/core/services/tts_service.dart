import 'package:flutter_tts/flutter_tts.dart';

/// Pembungkus TTS on-device (`flutter_tts`) dengan locale Indonesia.
///
/// Semua panggilan dibungkus try/catch: bila mesin TTS id-ID tidak tersedia,
/// aplikasi tetap jalan dan mengandalkan teks di layar (fallback PRD 10.1).
class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  FlutterTts? _tts;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init({double volume = 1.0, double speechRate = 0.5}) async {
    try {
      final tts = _tts ??= FlutterTts();
      await tts.setLanguage('id-ID');
      await tts.setVolume(volume);
      await tts.setSpeechRate(speechRate);
      await tts.setPitch(1.0);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_ready || text.isEmpty) return;
    try {
      await _tts?.stop();
      await _tts?.speak(text);
    } catch (_) {
      // diabaikan, teks tetap tampil di layar
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {
      // diabaikan
    }
  }

  Future<void> dispose() async {
    try {
      await _tts?.stop();
    } catch (_) {
      // diabaikan
    }
  }
}
