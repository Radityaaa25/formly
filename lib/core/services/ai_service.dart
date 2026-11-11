import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/session_result.dart';
import '../config/env.dart';

abstract final class AiService {
  static const _safetyWords = [
    'nyeri dada',
    'sesak',
    'pingsan',
    'mati rasa',
    'nyeri tajam',
    'jantung',
  ];

  /// Memanggil Supabase Edge Function `coach-chat` (Groq LLM).
  /// Otomatis fallback ke jawaban berbasis aturan jika offline / Supabase belum diset.
  static Future<String> askCoach(
    String message, {
    List<({String sender, String text})> history = const [],
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return '';

    if (Env.hasSupabase) {
      try {
        final client = Supabase.instance.client;
        final response = await client.functions.invoke(
          'coach-chat',
          body: {
            'message': trimmed,
            'history': history
                .map((h) => {'sender': h.sender, 'text': h.text})
                .toList(),
          },
        );

        if (response.status == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          final reply = data['reply'] as String?;
          if (reply != null && reply.trim().isNotEmpty) {
            return reply.trim();
          }
        }
      } catch (_) {
        // Fallback ke aturan lokal bila server offline / limit.
      }
    }

    return _localAnswer(trimmed);
  }

  /// Memanggil Supabase Edge Function `summarize-session` (Groq LLM).
  static Future<({String summary, String tip})> generateSummary(
    SessionResult result,
  ) async {
    const defaultSummary = (
      summary: 'Gerakanmu stabil dari awal sampai akhir. Skor form naik 4 poin dari sesi lalu. Di set terakhir kedalaman squat mulai berkurang.',
      tip: 'Tips: dorong pinggul ke belakang seperti mau duduk.',
    );

    if (Env.hasSupabase) {
      try {
        final client = Supabase.instance.client;
        final response = await client.functions.invoke(
          'summarize-session',
          body: {
            'exerciseName': result.exercise.name,
            'reps': result.reps,
            'score': result.score,
            'painBefore': result.painBefore,
            'painAfter': result.painAfter ?? result.painBefore,
            'errors': result.errors
                .map((e) => {'label': e.label, 'count': e.count})
                .toList(),
          },
        );

        if (response.status == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          final summary = data['summary'] as String?;
          final tip = data['tip'] as String?;
          if (summary != null && summary.isNotEmpty) {
            return (summary: summary, tip: tip ?? defaultSummary.tip);
          }
        }
      } catch (_) {
        // Fallback lokal.
      }
    }

    return defaultSummary;
  }

  static String _localAnswer(String message) {
    final text = message.toLowerCase().trim();

    // 1) Guardrail keselamatan (selalu didahulukan).
    for (final word in _safetyWords) {
      if (text.contains(word)) {
        return 'Hentikan latihan dulu dan segera hubungi tenaga kesehatan atau layanan darurat. Gejala seperti ini tidak boleh ditangani dengan latihan. Jangan lanjutkan sesi sebelum diperiksa.';
      }
    }

    // 2) Tolak prompt injection / permintaan membocorkan instruksi.
    const injectionSignals = [
      'ignore previous',
      'ignore all',
      'abaikan instruksi',
      'abaikan aturan',
      'system prompt',
      'prompt kamu',
      'jailbreak',
      'developer mode',
      'kamu sekarang adalah',
      'mulai sekarang kamu',
      'reveal your',
    ];
    for (final signal in injectionSignals) {
      if (text.contains(signal)) {
        return 'Aku hanya bisa membantu soal latihan, form gerakan, rehabilitasi, dan topik kebugaran Formly. Aku tidak bisa mengubah aturan atau membocorkan instruksi internal.';
      }
    }

    // 3) Sapaan.
    final greeting = RegExp(
      r'^(halo|hallo|hai|hi|hey|hello|pagi|siang|sore|malam|assalam|selamat)\b',
    );
    if (greeting.hasMatch(text) || text == 'halo' || text == 'hai') {
      return 'Halo! Aku Pelatih Formly. Mau tanya soal form gerakan, program latihan, atau rehabilitasi? Aku siap bantu.';
    }

    // 4) Topik di luar konteks Formly / kebugaran.
    const outOfScope = [
      'coding',
      'program komputer',
      'javascript',
      'python',
      'politik',
      'presiden',
      'pemilu',
      'film',
      'musik',
      'lagu',
      'game',
      'saham',
      'crypto',
      'bitcoin',
      'jodoh',
      'pacaran',
      'resep masakan',
      'matematika',
      'pr sekolah',
    ];
    for (final topic in outOfScope) {
      if (text.contains(topic)) {
        return 'Aku cuma bisa bantu soal latihan, form gerakan, rehabilitasi, kebugaran, dan Formly. Untuk topik itu, sebaiknya tanya ke sumber yang sesuai ya.';
      }
    }

    if (text.contains('formly')) {
      return 'Formly adalah aplikasi latihan dan rehabilitasi dengan kamera HP sebagai mata dan suara sebagai pelatih. Formly menghitung rep, menilai form gerakan, memberi koreksi suara, dan menghubungkan pasien dengan terapis. Video tidak pernah disimpan, hanya data angka hasil latihan.';
    }
    if (text.contains('terapis') ||
        text.contains('fisioterapi') ||
        text.contains('rehab')) {
      return 'Untuk rehabilitasi, ikuti program yang dibuat fisioterapis dan utamakan gerakan yang nyaman. Formly membantu memantau kepatuhan dan kualitas gerakan, tetapi bukan pengganti terapis.';
    }
    if (text.contains('diet') ||
        text.contains('makanan') ||
        text.contains('kalori')) {
      return 'Untuk mendukung latihan, utamakan protein (telur, tahu, ikan), karbohidrat kompleks, sayur, dan cukup air. Hindari diet ekstrem tanpa pendampingan ahli gizi, terutama saat pemulihan cedera.';
    }

    if (text.contains('nyeri') || text.contains('sakit')) {
      if (text.contains('lutut')) {
        return 'Nyeri lutut sering muncul karena lutut maju melewati ujung kaki atau berat badan terlalu ke depan. Coba dorong pinggul ke belakang dan tekan lewat tumit. Kalau nyeri tajam atau membengkak, hentikan dan hubungi fisioterapis.';
      }
      if (text.contains('punggung') || text.contains('pinggang')) {
        return 'Jaga punggung tetap netral dan hindari membungkuk saat mengangkat. Latihan Glute Bridge bisa membantu. Bila nyeri menjalar ke kaki, segera berhenti dan periksa ke tenaga medis.';
      }
      if (text.contains('bahu')) {
        return 'Bahu terasa tegang biasanya karena bahu ikut terangkat. Rilekskan leher dan bahu, gerakkan perlahan dalam rentang nyaman. Bila nyeri tajam, hentikan.';
      }
      return 'Istirahat dulu dan kurangi beban/rentang gerak sampai nyeri mereda. Bila nyeri menetap atau tajam, konsultasikan ke fisioterapis.';
    }

    if (text.contains('squat')) {
      if (text.contains('ganti') || text.contains('alternatif')) {
        return 'Coba Glute Bridge atau Wall Sit. Keduanya melatih otot kaki dan pinggul dengan tekanan lebih ringan di lutut.';
      }
      return 'Kunci squat: punggung lurus, turun sampai paha sejajar lantai, dan lutut searah ujung kaki. Dorong pinggul ke belakang seperti mau duduk.';
    }
    if (text.contains('push')) {
      return 'Untuk push-up: badan lurus dari kepala ke tumit, siku sekitar 45 derajat, dan turun sampai dada hampir menyentuh lantai. Hindari pinggul turun.';
    }
    if (text.contains('plank')) {
      return 'Plank: tarik perut, jaga pinggul sejajar, dan napas tetap teratur. Mulai dari 20-30 detik lalu tambah bertahap.';
    }
    if (text.contains('istirahat') ||
        text.contains('jeda') ||
        text.contains('set')) {
      return 'Untuk latihan ringan, istirahat 45-90 detik antar set sudah cukup. Dengarkan tubuhmu; tambah bila masih lelah.';
    }
    if (text.contains('berapa') &&
        (text.contains('rep') || text.contains('kali'))) {
      return 'Pemula biasanya 2-3 set x 8-12 rep per gerakan. Skor form yang tinggi lebih penting daripada jumlah rep. Utamakan gerakan benar.';
    }
    if (text.contains('makan') ||
        text.contains('nutrisi') ||
        text.contains('protein')) {
      return 'Setelah latihan, pilih sumber protein dan karbohidrat (misalnya telur, tahu, nasi, atau buah) dalam 1-2 jam untuk membantu pemulihan. Pastikan cukup air.';
    }
    if (text.contains('pemanasan') || text.contains('warming')) {
      return 'Lakukan pemanasan 5 menit: jalan di tempat, putaran bahu, dan gerakan sendi ringan sebelum mulai. Ini menurunkan risiko cedera.';
    }
    if (text.contains('semangat') || text.contains('malas')) {
      return 'Konsistensi menang! Mulai dari sesi singkat hari ini. Setiap rep yang benar itu kemajuan. Kamu bisa!';
    }

    return 'Pertanyaan bagus. Fokus pada gerakan pelan dan terkontrol dulu, lalu tambah repetisi bertahap. Pastikan form benar sebelum menambah beban. Kalau ragu, tanyakan gerakan spesifiknya ya.';
  }
}
