import 'dart:convert';

import 'package:flutter/services.dart';

/// Konfigurasi runtime.
///
/// Urutan prioritas:
/// 1. `--dart-define=SUPABASE_URL=...` (menang jika diisi)
/// 2. File `assets/config/env.json`
///
/// Contoh isi `assets/config/env.json`:
/// ```json
/// {
///   "SUPABASE_URL": "https://xxxx.supabase.co",
///   "SUPABASE_ANON_KEY": "eyJhbGciOi..."
/// }
/// ```
abstract final class Env {
  static const String _defineUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _defineKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String supabaseUrl = '';
  static String supabaseAnonKey = '';

  static bool get hasSupabase =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static bool get useMockData => !hasSupabase;

  static Future<void> load() async {
    supabaseUrl = _defineUrl;
    supabaseAnonKey = _defineKey;

    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) return;

    try {
      final raw = await rootBundle.loadString('assets/config/env.json');
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        final url = (data['SUPABASE_URL'] ?? '').toString().trim();
        final key = (data['SUPABASE_ANON_KEY'] ?? '').toString().trim();
        if (url.isNotEmpty) supabaseUrl = url;
        if (key.isNotEmpty) supabaseAnonKey = key;
      }
    } catch (_) {
      // File konfigurasi belum ada: aplikasi berjalan dengan data mock lokal.
    }
  }
}
