class RehabProgramItem {
  const RehabProgramItem({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.done,
  });

  final String exerciseId;
  final String name;
  final int sets;
  final int reps;
  final bool done;
}

class TherapistProgram {
  const TherapistProgram({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.exerciseIds,
    required this.sets,
    required this.reps,
    required this.days,
  });

  final int id;
  final String patientId;
  final String patientName;
  final List<String> exerciseIds;
  final int sets;
  final int reps;
  final List<String> days;

  TherapistProgram copyWith({
    String? patientId,
    String? patientName,
    List<String>? exerciseIds,
    int? sets,
    int? reps,
    List<String>? days,
  }) {
    return TherapistProgram(
      id: id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      days: days ?? this.days,
    );
  }
}
