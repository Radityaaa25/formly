import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_id.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/stat_ring.dart';
import '../../data/mock_data.dart';
import '../../data/models/exercise.dart';
import '../../data/models/program.dart';
import '../../data/models/user_profile.dart';
import '../../state/auth_state.dart';
import '../../state/user_data_state.dart';
import '../session/variation_picker.dart';

class RehabHome extends ConsumerWidget {
  const RehabHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final current = ref.watch(currentUserProvider);
    final dashboard =
        ref.watch(userDashboardProvider).value ??
        (Env.hasSupabase ? const UserDashboard() : _demoDashboard());
    final program =
        ref.watch(rehabProgramProvider).value ?? MockData.rehabProgram;
    final catalog =
        ref.watch(exerciseCatalogProvider).value ?? MockData.exercises;

    final name = profile?.fullName ?? current?.name ?? 'Sari Wulandari';
    final initials = profile?.initials ?? _initialsFrom(name);
    final firstName = name.trim().split(RegExp(r'\s+')).first;

    final next = program.firstWhere(
      (item) => !item.done,
      orElse: () => program.isNotEmpty
          ? program.first
          : const RehabProgramItem(
              exerciseId: 'squat',
              name: 'Latihan ringan',
              sets: 3,
              reps: 10,
              done: false,
            ),
    );

    final weekSessions = dashboard.week.isEmpty
        ? 5
        : dashboard.week.fold<int>(0, (sum, day) => sum + day.sessions);
    const ringMax = 6;
    final ringValue = weekSessions.clamp(0, ringMax);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
            ref.invalidate(userDashboardProvider);
            ref.invalidate(rehabProgramProvider);
            await ref.read(userDashboardProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primaryLight, AppColors.primary],
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todayId,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          Text(
                            'Halo, $firstName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border, width: 1.4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: AppColors.streak,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${dashboard.currentStreak}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.streak,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      StatRing(
                        value: ringValue,
                        max: ringMax,
                        size: 90,
                        stroke: 9,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$ringValue',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              '/$ringMax',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$ringValue dari $ringMax sesi minggu ini',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pelan-pelan saja, yang penting rutin.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Program hari ini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'dari Fisioterapis Dimas',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 14),
                for (final item in program) ...[
                  _ProgramCard(
                    item: item,
                    exercise: _exerciseFor(catalog, item.exerciseId),
                    onTap: () => startExercise(
                      context,
                      _exerciseFor(catalog, item.exerciseId),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
                GlassButton(
                  label: 'Mulai ${next.name}',
                  icon: const Icon(Icons.play_arrow_rounded),
                  size: GlassButtonSize.large,
                  expand: true,
                  onPressed: () => startExercise(
                    context,
                    _exerciseFor(catalog, next.exerciseId),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Exercise _exerciseFor(List<Exercise> catalog, String id) {
    return catalog.firstWhere(
      (exercise) => exercise.id == id,
      orElse: () => MockData.exerciseById(id),
    );
  }

  static String _initialsFrom(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'F';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static UserDashboard _demoDashboard() {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return UserDashboard(
      currentStreak: 12,
      longestStreak: 18,
      freezes: 1,
      xp: 340,
      totalSessions: 54,
      todaySessions: 2,
      week: [
        for (var i = 0; i < 7; i++)
          DayStat(
            date: monday.add(Duration(days: i)),
            score: MockData.weekScores[i].score,
            reps: MockData.weekScores[i].reps,
            sessions: MockData.weekScores[i].score > 0 ? 1 : 0,
          ),
      ],
      activeDays: [for (final item in MockData.weekScores) item.score > 0],
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.item,
    required this.exercise,
    required this.onTap,
  });

  final RehabProgramItem item;
  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.done
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.done ? Icons.check_rounded : exercise.icon.icon,
              color: item.done ? AppColors.success : AppColors.primaryDeep,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.sets} set × ${item.reps} rep',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            item.done
                ? Icons.check_circle_rounded
                : Icons.play_circle_fill_rounded,
            color: item.done ? AppColors.success : AppColors.primary,
            size: 26,
          ),
        ],
      ),
    );
  }
}
