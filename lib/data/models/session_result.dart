import 'exercise.dart';

class SessionResult {
  const SessionResult({
    required this.exercise,
    required this.reps,
    required this.score,
    required this.durationSeconds,
    required this.errors,
    required this.painBefore,
    this.painAfter,
    this.xpEarned = 0,
    this.streakDays = 13,
    this.newBadge,
  });

  final Exercise exercise;
  final int reps;
  final int score;
  final int durationSeconds;
  final List<SessionError> errors;
  final int painBefore;
  final int? painAfter;
  final int xpEarned;
  final int streakDays;
  final String? newBadge;

  String get durationLabel {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static SessionResult sample(Exercise exercise) => SessionResult(
    exercise: exercise,
    reps: 30,
    score: 86,
    durationSeconds: 492,
    painBefore: 2,
    painAfter: 2,
    xpEarned: 45,
    newBadge: '7 Hari Beruntun',
    errors: const [
      SessionError(label: 'Kurang dalam saat turun', count: 6),
      SessionError(label: 'Lutut sedikit masuk ke dalam', count: 3),
    ],
  );
}

class SessionError {
  const SessionError({required this.label, required this.count});

  final String label;
  final int count;
}
