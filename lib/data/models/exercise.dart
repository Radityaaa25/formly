import 'package:flutter/material.dart';

enum ExerciseDifficulty { easy, medium, hard }

extension ExerciseDifficultyLabel on ExerciseDifficulty {
  String get label => switch (this) {
    ExerciseDifficulty.easy => 'Mudah',
    ExerciseDifficulty.medium => 'Sedang',
    ExerciseDifficulty.hard => 'Sulit',
  };
}

enum ExerciseSide { front, side }

extension ExerciseSideLabel on ExerciseSide {
  String get label => switch (this) {
    ExerciseSide.front => 'Depan',
    ExerciseSide.side => 'Samping',
  };
}

enum ExerciseKind { reps, timed }

enum ExerciseIconType {
  squat,
  pushup,
  plank,
  arm,
  lunge,
  bridge,
  knee,
  shoulder,
}

extension ExerciseIconData on ExerciseIconType {
  IconData get icon => switch (this) {
    ExerciseIconType.squat => Icons.accessibility_new_rounded,
    ExerciseIconType.pushup => Icons.fitness_center_rounded,
    ExerciseIconType.plank => Icons.horizontal_rule_rounded,
    ExerciseIconType.arm => Icons.arrow_upward_rounded,
    ExerciseIconType.lunge => Icons.directions_walk_rounded,
    ExerciseIconType.bridge => Icons.swap_horiz_rounded,
    ExerciseIconType.knee => Icons.airline_seat_legroom_extra_rounded,
    ExerciseIconType.shoulder => Icons.rotate_right_rounded,
  };
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.side,
    required this.kind,
    required this.icon,
    required this.placement,
    required this.tips,
  });

  final String id;
  final String name;
  final ExerciseDifficulty difficulty;
  final ExerciseSide side;
  final ExerciseKind kind;
  final ExerciseIconType icon;
  final String placement;
  final List<String> tips;
}
