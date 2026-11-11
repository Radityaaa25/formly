import 'models/exercise.dart';
import 'models/patient.dart';
import 'models/program.dart';

enum DayActivity { active, frozen, rest }

class WeekScore {
  const WeekScore({required this.day, required this.score, required this.reps});

  final String day;
  final int score;
  final int reps;
}

class BadgeData {
  const BadgeData({
    required this.id,
    required this.label,
    required this.unlocked,
  });

  final String id;
  final String label;
  final bool unlocked;
}

abstract final class MockData {
  static const List<Exercise> exercises = [
    Exercise(
      id: 'squat',
      name: 'Squat',
      difficulty: ExerciseDifficulty.medium,
      side: ExerciseSide.side,
      kind: ExerciseKind.reps,
      icon: ExerciseIconType.squat,
      placement: 'Taruh HP setinggi pinggang, 2-3 meter di samping badan.',
      tips: [
        'Punggung tetap lurus',
        'Lutut searah ujung kaki',
        'Turun sampai paha sejajar lantai',
      ],
    ),
    Exercise(
      id: 'pushup',
      name: 'Push-up',
      difficulty: ExerciseDifficulty.medium,
      side: ExerciseSide.side,
      kind: ExerciseKind.reps,
      icon: ExerciseIconType.pushup,
      placement: 'Taruh HP di lantai, 2 meter di samping badan.',
      tips: [
        'Badan lurus dari kepala ke tumit',
        'Siku sekitar 45 derajat',
        'Dada hampir menyentuh lantai',
      ],
    ),
    Exercise(
      id: 'plank',
      name: 'Plank',
      difficulty: ExerciseDifficulty.easy,
      side: ExerciseSide.side,
      kind: ExerciseKind.timed,
      icon: ExerciseIconType.plank,
      placement: 'Taruh HP di lantai, 2 meter di samping badan.',
      tips: [
        'Pinggul jangan turun',
        'Tarik perut ke dalam',
        'Napas tetap teratur',
      ],
    ),
    Exercise(
      id: 'arm',
      name: 'Angkat Lengan',
      difficulty: ExerciseDifficulty.easy,
      side: ExerciseSide.front,
      kind: ExerciseKind.reps,
      icon: ExerciseIconType.arm,
      placement: 'Taruh HP setinggi dada, 2 meter di depan badan.',
      tips: ['Bahu tetap rileks', 'Angkat perlahan', 'Siku sedikit ditekuk'],
    ),
    Exercise(
      id: 'lunge',
      name: 'Lunge',
      difficulty: ExerciseDifficulty.hard,
      side: ExerciseSide.side,
      kind: ExerciseKind.reps,
      icon: ExerciseIconType.lunge,
      placement: 'Taruh HP setinggi pinggang, 3 meter di samping badan.',
      tips: [
        'Lutut depan tidak melewati ujung kaki',
        'Badan tegak',
        'Langkah cukup lebar',
      ],
    ),
    Exercise(
      id: 'bridge',
      name: 'Glute Bridge',
      difficulty: ExerciseDifficulty.easy,
      side: ExerciseSide.side,
      kind: ExerciseKind.reps,
      icon: ExerciseIconType.bridge,
      placement: 'Taruh HP di lantai, 2 meter di samping badan.',
      tips: [
        'Dorong lewat tumit',
        'Tahan 2 detik di atas',
        'Jangan melengkungkan punggung',
      ],
    ),
    Exercise(
      id: 'knee',
      name: 'Tekuk Lutut',
      difficulty: ExerciseDifficulty.easy,
      side: ExerciseSide.side,
      kind: ExerciseKind.reps,
      icon: ExerciseIconType.knee,
      placement: 'Taruh HP setinggi lutut, 2 meter di samping badan.',
      tips: ['Gerak perlahan', 'Berhenti bila nyeri tajam', 'Paha tetap diam'],
    ),
    Exercise(
      id: 'shoulder',
      name: 'Putar Bahu',
      difficulty: ExerciseDifficulty.easy,
      side: ExerciseSide.front,
      kind: ExerciseKind.reps,
      icon: ExerciseIconType.shoulder,
      placement: 'Taruh HP setinggi dada, 2 meter di depan badan.',
      tips: ['Lingkaran kecil dulu', 'Leher rileks', 'Kedua sisi sama rata'],
    ),
  ];

  static Exercise exerciseById(String? id) {
    return exercises.firstWhere(
      (exercise) => exercise.id == id,
      orElse: () => exercises.first,
    );
  }

  static const List<RehabProgramItem> rehabProgram = [
    RehabProgramItem(
      exerciseId: 'knee',
      name: 'Tekuk Lutut',
      sets: 3,
      reps: 10,
      done: true,
    ),
    RehabProgramItem(
      exerciseId: 'bridge',
      name: 'Glute Bridge',
      sets: 2,
      reps: 12,
      done: false,
    ),
    RehabProgramItem(
      exerciseId: 'shoulder',
      name: 'Putar Bahu',
      sets: 2,
      reps: 8,
      done: false,
    ),
  ];

  static const List<WeekScore> weekScores = [
    WeekScore(day: 'Sen', score: 72, reps: 40),
    WeekScore(day: 'Sel', score: 78, reps: 55),
    WeekScore(day: 'Rab', score: 75, reps: 30),
    WeekScore(day: 'Kam', score: 81, reps: 60),
    WeekScore(day: 'Jum', score: 84, reps: 48),
    WeekScore(day: 'Sab', score: 0, reps: 0),
    WeekScore(day: 'Min', score: 86, reps: 30),
  ];

  static const List<Patient> patients = [
    Patient(
      id: 'sari',
      name: 'Sari Wulandari',
      condition: 'Pasca operasi ACL lutut kanan',
      status: PatientStatus.routine,
      adherence: 83,
      lastSession: 'Hari ini',
      scores: [70, 74, 77, 80, 82, 85, 86],
      errors: ['Lutut masuk ke dalam', 'Gerak terlalu cepat'],
    ),
    Patient(
      id: 'budi',
      name: 'Budi Santoso',
      condition: 'Frozen shoulder kiri',
      status: PatientStatus.needsAttention,
      adherence: 50,
      lastSession: '3 hari lalu',
      scores: [65, 62, 68, 60, 64, 0, 0],
      errors: ['Bahu terangkat', 'Rentang gerak kurang'],
    ),
    Patient(
      id: 'ayu',
      name: 'Ayu Lestari',
      condition: 'Nyeri punggung bawah',
      status: PatientStatus.routine,
      adherence: 92,
      lastSession: 'Kemarin',
      scores: [78, 80, 83, 85, 84, 88, 90],
      errors: ['Pinggul turun saat bridge'],
    ),
    Patient(
      id: 'hendra',
      name: 'Hendra Gunawan',
      condition: 'Pemulihan sprain pergelangan kaki',
      status: PatientStatus.inactive,
      adherence: 10,
      lastSession: '12 hari lalu',
      scores: [60, 0, 0, 0, 0, 0, 0],
      errors: ['Keseimbangan kurang'],
    ),
  ];

  static Patient patientById(String id) {
    return patients.firstWhere(
      (patient) => patient.id == id,
      orElse: () => patients.first,
    );
  }

  static const List<BadgeData> badges = [
    BadgeData(id: 's3', label: '3 Hari Beruntun', unlocked: true),
    BadgeData(id: 's7', label: '7 Hari Beruntun', unlocked: true),
    BadgeData(id: 's14', label: '14 Hari Beruntun', unlocked: false),
    BadgeData(id: 's30', label: '30 Hari Beruntun', unlocked: false),
    BadgeData(id: 's100', label: '100 Hari Beruntun', unlocked: false),
    BadgeData(id: 'skor90', label: 'Skor 90+', unlocked: false),
    BadgeData(id: 'rep100', label: '100 Rep Pertama', unlocked: true),
  ];

  static const Map<int, DayActivity> monthDays = {
    2: DayActivity.active,
    3: DayActivity.active,
    4: DayActivity.rest,
    5: DayActivity.active,
    6: DayActivity.active,
    7: DayActivity.active,
    9: DayActivity.active,
    10: DayActivity.frozen,
    11: DayActivity.active,
    12: DayActivity.active,
    13: DayActivity.active,
    14: DayActivity.active,
    15: DayActivity.active,
    16: DayActivity.active,
    17: DayActivity.active,
    18: DayActivity.active,
    19: DayActivity.active,
    20: DayActivity.active,
    21: DayActivity.rest,
    22: DayActivity.active,
    23: DayActivity.active,
    24: DayActivity.active,
    25: DayActivity.active,
    26: DayActivity.active,
  };

  static const List<String> formCues = [
    'Turun sedikit lagi',
    'Bagus, pertahankan',
    'Punggung tetap lurus',
    'Lutut searah ujung kaki',
  ];

  static const List<TherapistProgram> therapistPrograms = [
    TherapistProgram(
      id: 1,
      patientId: 'sari',
      patientName: 'Sari Wulandari',
      exerciseIds: ['knee', 'bridge', 'shoulder'],
      sets: 3,
      reps: 10,
      days: ['Sen', 'Rab', 'Jum', 'Sab'],
    ),
    TherapistProgram(
      id: 2,
      patientId: 'budi',
      patientName: 'Budi Santoso',
      exerciseIds: ['shoulder', 'arm'],
      sets: 2,
      reps: 8,
      days: ['Sel', 'Kam', 'Sab'],
    ),
  ];

  static const int painAlertThreshold = 7;

  static List<String> get dayNames => const [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];
}
