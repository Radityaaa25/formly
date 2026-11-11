import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../data/models/program.dart';
import '../data/models/session_result.dart';

enum AppMode { workout, rehab }

extension AppModeLabel on AppMode {
  String get label => switch (this) {
    AppMode.workout => 'Workout',
    AppMode.rehab => 'Rehab',
  };
}

class AppModeNotifier extends Notifier<AppMode> {
  @override
  AppMode build() => AppMode.workout;

  void setMode(AppMode mode) => state = mode;
}

final appModeProvider = NotifierProvider<AppModeNotifier, AppMode>(
  AppModeNotifier.new,
);

class LastSessionNotifier extends Notifier<SessionResult?> {
  @override
  SessionResult? build() => null;

  void setResult(SessionResult result) => state = result;
  void clear() => state = null;
}

final lastSessionProvider =
    NotifierProvider<LastSessionNotifier, SessionResult?>(
      LastSessionNotifier.new,
    );

class AppSettings {
  const AppSettings({
    this.volume = 70,
    this.speechRate = 50,
    this.detailedCorrections = false,
    this.silentMode = false,
    this.reminderEnabled = true,
    this.reminderTime = '18:30',
  });

  final int volume;
  final int speechRate;
  final bool detailedCorrections;
  final bool silentMode;
  final bool reminderEnabled;
  final String reminderTime;

  AppSettings copyWith({
    int? volume,
    int? speechRate,
    bool? detailedCorrections,
    bool? silentMode,
    bool? reminderEnabled,
    String? reminderTime,
  }) {
    return AppSettings(
      volume: volume ?? this.volume,
      speechRate: speechRate ?? this.speechRate,
      detailedCorrections: detailedCorrections ?? this.detailedCorrections,
      silentMode: silentMode ?? this.silentMode,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void update(AppSettings settings) => state = settings;
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class TherapistProgramsNotifier extends Notifier<List<TherapistProgram>> {
  @override
  List<TherapistProgram> build() => MockData.therapistPrograms;

  void save(TherapistProgram program, {int? editingId}) {
    if (editingId == null) {
      state = [...state, program];
      return;
    }
    state = [
      for (final item in state)
        if (item.id == editingId)
          TherapistProgram(
            id: editingId,
            patientId: program.patientId,
            patientName: program.patientName,
            exerciseIds: program.exerciseIds,
            sets: program.sets,
            reps: program.reps,
            days: program.days,
          )
        else
          item,
    ];
  }

  void remove(int id) {
    state = state.where((program) => program.id != id).toList();
  }
}

final therapistProgramsProvider =
    NotifierProvider<TherapistProgramsNotifier, List<TherapistProgram>>(
      TherapistProgramsNotifier.new,
    );
