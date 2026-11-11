import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/mock_data.dart';
import '../data/models/exercise.dart';
import '../data/models/program.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/user_repository.dart';

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  return UserRepository.loadProfile();
});

final userDashboardProvider = FutureProvider<UserDashboard>((ref) async {
  return UserRepository.loadDashboard();
});

final exerciseCatalogProvider = FutureProvider<List<Exercise>>((ref) async {
  final remote = await UserRepository.loadExercises();
  return remote.isEmpty ? MockData.exercises : remote;
});

final rehabProgramProvider = FutureProvider<List<RehabProgramItem>>((
  ref,
) async {
  final remote = await UserRepository.loadRehabProgram();
  return remote ?? MockData.rehabProgram;
});

/// Variasi gerakan buatan pengguna. Disimpan di perangkat agar tetap cepat
/// dan tidak mengotori katalog gerakan global.
class CustomExercise {
  const CustomExercise({
    required this.id,
    required this.name,
    required this.baseExerciseId,
    required this.sets,
    required this.reps,
    this.note = '',
    required this.createdAt,
  });

  final String id;
  final String name;
  final String baseExerciseId;
  final int sets;
  final int reps;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseExerciseId': baseExerciseId,
    'sets': sets,
    'reps': reps,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CustomExercise.fromJson(Map<String, dynamic> json) {
    return CustomExercise(
      id: json['id']?.toString() ?? const Uuid().v4(),
      name: json['name']?.toString() ?? 'Variasi Baru',
      baseExerciseId: json['baseExerciseId']?.toString() ?? 'squat',
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      reps: (json['reps'] as num?)?.toInt() ?? 10,
      note: json['note']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class CustomExercisesNotifier extends AsyncNotifier<List<CustomExercise>> {
  static const _key = 'formly_custom_exercises';

  @override
  Future<List<CustomExercise>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CustomExercise.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(CustomExercise exercise) async {
    final current = state.value ?? const <CustomExercise>[];
    final next = [...current, exercise];
    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> remove(String id) async {
    final current = state.value ?? const <CustomExercise>[];
    final next = current.where((item) => item.id != id).toList();
    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> _persist(List<CustomExercise> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}

final customExercisesProvider =
    AsyncNotifierProvider<CustomExercisesNotifier, List<CustomExercise>>(
      CustomExercisesNotifier.new,
    );
