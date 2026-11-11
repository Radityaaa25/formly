import 'exercise.dart';

/// Satu variasi gerakan. Bisa berasal dari preset bawaan atau buatan pengguna.
class ExerciseVariation {
  const ExerciseVariation({
    required this.id,
    required this.baseExerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    this.note = '',
    this.isCustom = false,
  });

  final String id;
  final String baseExerciseId;
  final String name;
  final int sets;
  final int reps;
  final String note;
  final bool isCustom;

  bool get isTimed {
    return baseExerciseId == 'plank';
  }

  String get volumeLabel =>
      isTimed ? '$sets set · $reps detik' : '$sets set × $reps rep';
}

List<ExerciseVariation> presetsForExercise(Exercise exercise) {
  final id = exercise.id;

  ExerciseVariation v(
    String slug,
    String name,
    int sets,
    int reps,
    String note,
  ) {
    return ExerciseVariation(
      id: 'preset_${id}_$slug',
      baseExerciseId: id,
      name: name,
      sets: sets,
      reps: reps,
      note: note,
    );
  }

  return switch (id) {
    'squat' => [
      v('ringan', 'Squat Ringan', 2, 8, 'Kedalaman nyaman, fokus kontrol.'),
      v('standar', 'Squat Standar', 3, 10, 'Paha sejajar lantai, dada tegap.'),
      v(
        'lebar',
        'Squat Lebar',
        3,
        12,
        'Kaki lebih lebar, lutut searah ujung kaki.',
      ),
      v('kursi', 'Squat Kursi', 3, 10, 'Turun menyentuh kursi lalu berdiri.'),
    ],
    'knee' => [
      v(
        'extension',
        'Knee Extension',
        3,
        10,
        'Luruskan lutut perlahan, tahan 1 detik.',
      ),
      v('legraise', 'Leg Raise', 3, 12, 'Angkat kaki lurus, jangan ayun.'),
      v('quad', 'Quad Set', 3, 10, 'Tekan lutut ke bawah, tahan 5 detik.'),
    ],
    'pushup' => [
      v('dinding', 'Push-up Dinding', 3, 12, 'Tangan di dinding, badan lurus.'),
      v('lutut', 'Push-up Lutut', 3, 10, 'Tumpuan lutut, badan tetap lurus.'),
      v(
        'standar',
        'Push-up Standar',
        3,
        10,
        'Siku 45 derajat, dada turun penuh.',
      ),
    ],
    'plank' => [
      v('lutut', 'Plank Lutut', 3, 20, 'Tumpuan lutut, pinggul jangan turun.'),
      v('standar', 'Plank Standar', 3, 30, 'Badan lurus dari kepala ke tumit.'),
      v('samping', 'Plank Samping', 2, 20, 'Tumpu siku, pinggul terangkat.'),
    ],
    'lunge' => [
      v(
        'statis',
        'Lunge Statis',
        3,
        10,
        'Tetap di tempat, lutut depan 90 derajat.',
      ),
      v('standar', 'Lunge Standar', 3, 12, 'Langkah ke depan, badan tegak.'),
      v(
        'mundur',
        'Lunge Mundur',
        3,
        10,
        'Melangkah ke belakang, lebih ringan untuk lutut.',
      ),
    ],
    'bridge' => [
      v('glute', 'Glute Bridge', 3, 12, 'Angkat pinggul, tahan 2 detik.'),
      v(
        'satu-kaki',
        'Bridge Satu Kaki',
        2,
        8,
        'Satu kaki lurus, pinggul tetap sejajar.',
      ),
      v('tahan', 'Bridge Tahan', 3, 20, 'Tahan posisi atas selama hitungan.'),
    ],
    'arm' => [
      v(
        'standar',
        'Angkat Lengan',
        3,
        12,
        'Angkat lurus ke depan setinggi bahu.',
      ),
      v(
        'beban',
        'Lengan Beban Ringan',
        3,
        10,
        'Gunakan botol air, gerakan pelan.',
      ),
      v('silang', 'Lengan Silang', 3, 10, 'Angkat menyilang, kontrol penuh.'),
    ],
    'shoulder' => [
      v('pendulum', 'Pendulum', 3, 15, 'Ayun lengan rileks seperti pendulum.'),
      v('putaran', 'Putaran Bahu', 3, 12, 'Putaran kecil, tanpa nyeri.'),
      v(
        'samping',
        'Angkat Samping',
        3,
        10,
        'Angkat lengan ke samping maksimal 45 derajat.',
      ),
    ],
    _ => [
      v(
        'standar',
        '${exercise.name} Standar',
        3,
        10,
        'Lakukan dengan kontrol dan nyaman.',
      ),
      v(
        'ringan',
        '${exercise.name} Ringan',
        2,
        8,
        'Versi lebih ringan untuk pemanasan.',
      ),
    ],
  };
}
