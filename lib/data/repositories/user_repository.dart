import 'package:supabase_flutter/supabase_flutter.dart';

import '../../state/auth_state.dart';
import '../models/exercise.dart';
import '../models/program.dart';
import '../models/session_result.dart';
import '../models/user_profile.dart';
import '../../core/config/env.dart';

abstract final class UserRepository {
  static SupabaseClient get _client => Supabase.instance.client;

  static bool get _signedIn {
    if (!Env.hasSupabase) return false;
    try {
      return _client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  static String _fallbackName(User user) {
    final metaName = (user.userMetadata?['full_name'] as String?)?.trim() ?? '';
    if (metaName.isNotEmpty) return metaName;
    final email = user.email ?? '';
    if (email.contains('@')) return email.split('@').first;
    return 'Pengguna Formly';
  }

  /// Ambil profil dari public.profiles. Kalau belum ada (mis. trigger lama
  /// gagal), buat baris profil baru supaya aplikasi tidak menampilkan data dummy.
  static Future<UserProfile?> loadProfile() async {
    if (!_signedIn) return null;
    final user = _client.auth.currentUser!;
    final fallback = UserProfile(
      id: user.id,
      fullName: _fallbackName(user),
      role: AppRole.self,
    );

    try {
      final row = await _client
          .from('profiles')
          .select('id, full_name, role, created_at')
          .eq('id', user.id)
          .maybeSingle();

      if (row == null) {
        await _client.from('profiles').upsert({
          'id': user.id,
          'full_name': fallback.fullName,
          'role': AppRole.self.dbValue,
        }, onConflict: 'id');
        await _client.from('user_streaks').upsert({
          'user_id': user.id,
          'current_streak': 0,
          'longest_streak': 0,
        }, onConflict: 'user_id');
        return fallback;
      }

      final name = (row['full_name'] as String?)?.trim() ?? '';
      return UserProfile(
        id: user.id,
        fullName: name.isEmpty ? fallback.fullName : name,
        role: AppRoleLabel.fromDb(row['role'] as String?),
        createdAt: row['created_at'] == null
            ? null
            : DateTime.tryParse(row['created_at'].toString()),
      );
    } catch (_) {
      return fallback;
    }
  }

  static Future<UserDashboard> loadDashboard() async {
    if (!_signedIn) return const UserDashboard();
    final user = _client.auth.currentUser!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    try {
      final streakRow = await _client
          .from('user_streaks')
          .select('current_streak, longest_streak, freezes_available')
          .eq('user_id', user.id)
          .maybeSingle();

      final sessionRows = await _client
          .from('sessions')
          .select('completed_at, avg_score, total_reps')
          .eq('user_id', user.id)
          .gte(
            'completed_at',
            monday.toUtc().toIso8601String(),
          );

      final scoreSum = <String, int>{};
      final scoreCount = <String, int>{};
      final repsSum = <String, int>{};
      final sessionsPerDay = <String, int>{};
      var todaySessions = 0;

      for (final row in sessionRows) {
        final completedAt = DateTime.tryParse(
          row['completed_at']?.toString() ?? '',
        )?.toLocal();
        if (completedAt == null) continue;
        final date = DateTime(completedAt.year, completedAt.month, completedAt.day);
        final key = _dayKey(date);
        final score = (row['avg_score'] as num?)?.toInt() ?? 0;
        final reps = (row['total_reps'] as num?)?.toInt() ?? 0;
        scoreSum[key] = (scoreSum[key] ?? 0) + score;
        scoreCount[key] = (scoreCount[key] ?? 0) + 1;
        repsSum[key] = (repsSum[key] ?? 0) + reps;
        sessionsPerDay[key] = (sessionsPerDay[key] ?? 0) + 1;
        if (date == today) todaySessions++;
      }

      final week = <DayStat>[];
      final activeDays = <bool>[];
      for (var i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final key = _dayKey(date);
        final count = sessionsPerDay[key] ?? 0;
        final avg = count == 0 ? 0 : (scoreSum[key]! / count).round();
        week.add(
          DayStat(
            date: date,
            score: avg,
            reps: repsSum[key] ?? 0,
            sessions: count,
          ),
        );
        activeDays.add(count > 0);
      }

      var xp = 0;
      final xpRows = await _client
          .from('xp_events')
          .select('amount')
          .eq('user_id', user.id);
      for (final row in xpRows) {
        xp += (row['amount'] as num?)?.toInt() ?? 0;
      }

      final badgeRows = await _client
          .from('user_badges')
          .select('badge_id')
          .eq('user_id', user.id);
      final badges = <String>{
        for (final row in badgeRows) row['badge_id']?.toString() ?? '',
      }..removeWhere((id) => id.isEmpty);

      var totalSessions = 0;
      try {
        final countRow = await _client
            .from('sessions')
            .select('id')
            .eq('user_id', user.id)
            .count(CountOption.exact);
        totalSessions = countRow.count;
      } catch (_) {
        totalSessions = sessionRows.length;
      }

      return UserDashboard(
        currentStreak: (streakRow?['current_streak'] as num?)?.toInt() ?? 0,
        longestStreak: (streakRow?['longest_streak'] as num?)?.toInt() ?? 0,
        freezes: (streakRow?['freezes_available'] as num?)?.toInt() ?? 0,
        xp: xp,
        totalSessions: totalSessions,
        todaySessions: todaySessions,
        week: week,
        activeDays: activeDays,
        badges: badges,
      );
    } catch (_) {
      return const UserDashboard();
    }
  }

  static Future<List<Exercise>> loadExercises() async {
    if (!_signedIn) return const [];
    try {
      final rows = await _client
          .from('exercises')
          .select(
            'id, name, difficulty, side, kind, icon, placement_guide, tips',
          )
          .order('name');
      return rows.map(_exerciseFromRow).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<RehabProgramItem>?> loadRehabProgram() async {
    if (!_signedIn) return null;
    final user = _client.auth.currentUser!;
    try {
      final row = await _client
          .from('programs')
          .select(
            'id, title, program_items(exercise_id, sets, reps, sort_order)',
          )
          .eq('patient_id', user.id)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;

      final items = (row['program_items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList()
        ..sort(
          (a, b) => ((a['sort_order'] as num?)?.toInt() ?? 0).compareTo(
            (b['sort_order'] as num?)?.toInt() ?? 0,
          ),
        );

      final result = <RehabProgramItem>[];
      for (final item in items) {
        final exerciseId = item['exercise_id']?.toString() ?? '';
        if (exerciseId.isEmpty) continue;
        result.add(
          RehabProgramItem(
            exerciseId: exerciseId,
            name: _exerciseName(exerciseId),
            sets: (item['sets'] as num?)?.toInt() ?? 3,
            reps: (item['reps'] as num?)?.toInt() ?? 10,
            done: false,
          ),
        );
      }
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  /// Simpan sesi latihan. Trigger database akan menghitung streak & XP.
  static Future<bool> saveSession(SessionResult result) async {
    if (!_signedIn) return false;
    final user = _client.auth.currentUser!;
    final now = DateTime.now();
    try {
      await _client.from('sessions').insert({
        'user_id': user.id,
        'exercise_id': result.exercise.id,
        'started_at': now
            .subtract(Duration(seconds: result.durationSeconds))
            .toUtc()
            .toIso8601String(),
        'completed_at': now.toUtc().toIso8601String(),
        'avg_score': result.score,
        'total_reps': result.reps,
        'duration_seconds': result.durationSeconds,
        'pain_before': result.painBefore,
        'pain_after': result.painAfter,
        'is_valid_session': true,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static Exercise _exerciseFromRow(Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? 'squat';
    return Exercise(
      id: id,
      name: row['name']?.toString() ?? id,
      difficulty: _difficultyFromDb(row['difficulty']?.toString()),
      side: _sideFromDb(row['side']?.toString()),
      kind: row['kind']?.toString() == 'timed'
          ? ExerciseKind.timed
          : ExerciseKind.reps,
      icon: _iconFromDb(row['icon']?.toString(), id),
      placement: row['placement_guide']?.toString() ?? '',
      tips: (row['tips'] as List<dynamic>? ?? [])
          .map((tip) => tip.toString())
          .toList(),
    );
  }

  static ExerciseDifficulty _difficultyFromDb(String? value) {
    return switch (value?.toLowerCase()) {
      'mudah' || 'easy' => ExerciseDifficulty.easy,
      'sulit' || 'hard' => ExerciseDifficulty.hard,
      _ => ExerciseDifficulty.medium,
    };
  }

  static ExerciseSide _sideFromDb(String? value) {
    return switch (value?.toLowerCase()) {
      'depan' || 'front' => ExerciseSide.front,
      _ => ExerciseSide.side,
    };
  }

  static ExerciseIconType _iconFromDb(String? value, String id) {
    final key = value ?? id;
    return ExerciseIconType.values.firstWhere(
      (type) => type.name == key,
      orElse: () => ExerciseIconType.squat,
    );
  }

  static String _exerciseName(String id) {
    return switch (id) {
      'squat' => 'Squat',
      'pushup' => 'Push-up',
      'plank' => 'Plank',
      'arm' => 'Angkat Lengan',
      'lunge' => 'Lunge',
      'bridge' => 'Glute Bridge',
      'knee' => 'Tekuk Lutut',
      'shoulder' => 'Putar Bahu',
      _ => id,
    };
  }
}
