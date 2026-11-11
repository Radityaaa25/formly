import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formly/core/utils/date_id.dart';
import 'package:formly/data/models/exercise.dart';
import 'package:formly/data/models/session_result.dart';
import 'package:formly/features/splash/formly_splash.dart';

void main() {
  test('durasi sesi diformat mm:ss', () {
    final result = SessionResult(
      exercise: const Exercise(
        id: 'squat',
        name: 'Squat',
        difficulty: ExerciseDifficulty.medium,
        side: ExerciseSide.side,
        kind: ExerciseKind.reps,
        icon: ExerciseIconType.squat,
        placement: '',
        tips: [],
      ),
      reps: 30,
      score: 86,
      durationSeconds: 492,
      errors: const [],
      painBefore: 2,
    );
    expect(result.durationLabel, '08:12');
  });

  test('tanggal Indonesia memakai nama hari dan bulan', () {
    expect(formattedDateId(DateTime(2026, 11, 7)), 'Sabtu, 7 November');
  });

  testWidgets('splash screen tampil dengan wordmark dan tagline Formly', (
    tester,
  ) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(home: FormlySplash(onFinished: () => finished = true)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Gerak benar, hasil lebih aman.'), findsOneWidget);
    expect(find.text('f'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(finished, isTrue);
  });
}
