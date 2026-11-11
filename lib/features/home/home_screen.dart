import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_id.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/mock_data.dart';
import '../../data/models/exercise.dart';
import '../../data/models/user_profile.dart';
import '../../state/app_state.dart';
import '../../state/auth_state.dart';
import '../../state/user_data_state.dart';
import '../rehab/rehab_home.dart';
import '../session/variation_picker.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    return switch (mode) {
      AppMode.workout => const _WorkoutHome(),
      AppMode.rehab => const RehabHome(),
    };
  }
}

class _WorkoutHome extends ConsumerWidget {
  const _WorkoutHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final current = ref.watch(currentUserProvider);
    final dashboard =
        ref.watch(userDashboardProvider).value ??
        (Env.hasSupabase ? const UserDashboard() : _demoDashboard());
    final catalog =
        ref.watch(exerciseCatalogProvider).value ?? MockData.exercises;

    final name = profile?.fullName ?? current?.name ?? 'Sobat Formly';
    final initials = profile?.initials ?? _initialsFrom(name);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(userProfileProvider);
                ref.invalidate(userDashboardProvider);
                await ref.read(userDashboardProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeHeader(
                      initials: initials,
                      name: _firstName(name),
                      streak: dashboard.currentStreak,
                      xp: dashboard.xp,
                    ),
                    const SizedBox(height: 18),
                    _DailyQuestCard(dashboard: dashboard),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Jalur latihan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.library),
                          child: const Text(
                            'Lihat semua',
                            style: TextStyle(
                              color: AppColors.primaryDeep,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dashboard.todaySessions > 0
                          ? 'Bagus! Lanjutkan latihan berikutnya.'
                          : 'Selesaikan satu simpul untuk mulai streak hari ini.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _LessonPath(
                      exercises: catalog.take(6).toList(),
                      completed: dashboard.todaySessions,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStatCard(
                            icon: Icons.local_fire_department_rounded,
                            color: AppColors.streak,
                            value: '${dashboard.currentStreak}',
                            label: 'Hari beruntun',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniStatCard(
                            icon: Icons.bolt_rounded,
                            color: AppColors.xp,
                            value: '${dashboard.xp}',
                            label: 'Total XP',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniStatCard(
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                            value: '${dashboard.totalSessions}',
                            label: 'Sesi',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _StreakCard(dashboard: dashboard),
                    const SizedBox(height: 16),
                    _LevelCard(dashboard: dashboard),
                    const SizedBox(height: 22),
                    const Text(
                      'Pilih cepat',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 46,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: catalog.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final exercise = catalog[index];
                          return AppChip(
                            label: exercise.name,
                            icon: Icon(exercise.icon.icon),
                            onTap: () => _startSession(context, exercise),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 112,
            child: SafeArea(
              top: false,
              child: _CoachButton(onTap: () => context.push(AppRoutes.coach)),
            ),
          ),
        ],
      ),
    );
  }

  static void _startSession(BuildContext context, Exercise exercise) {
    startExercise(context, exercise);
  }

  static String _firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Sobat Formly';
    return trimmed.split(RegExp(r'\s+')).first;
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
      badges: const {'s3', 's7', 'rep100'},
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.initials,
    required this.name,
    required this.streak,
    required this.xp,
  });

  final String initials;
  final String name;
  final int streak;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryLight, AppColors.primaryDeep],
            ),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
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
                'Halo, $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _HeaderChip(
          icon: Icons.local_fire_department_rounded,
          color: AppColors.streak,
          value: '$streak',
        ),
        const SizedBox(width: 8),
        _HeaderChip(
          icon: Icons.bolt_rounded,
          color: AppColors.xp,
          value: '$xp',
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.color,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border, width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyQuestCard extends StatelessWidget {
  const _DailyQuestCard({required this.dashboard});

  final UserDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final sessionDone = dashboard.todaySessions >= 1;
    final doubleDone = dashboard.todaySessions >= 2;
    final streakDone = dashboard.currentStreak >= 1;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: AppColors.primaryDeep,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Misi hari ini',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${[sessionDone, doubleDone, streakDone].where((done) => done).length}/3',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _QuestRow(
            icon: Icons.play_circle_fill_rounded,
            color: AppColors.primary,
            label: 'Selesaikan 1 sesi latihan',
            done: sessionDone,
            progress: (dashboard.todaySessions / 1).clamp(0, 1).toDouble(),
          ),
          const SizedBox(height: 10),
          _QuestRow(
            icon: Icons.fitness_center_rounded,
            color: AppColors.sky,
            label: 'Selesaikan 2 sesi hari ini',
            done: doubleDone,
            progress: (dashboard.todaySessions / 2).clamp(0, 1).toDouble(),
          ),
          const SizedBox(height: 10),
          _QuestRow(
            icon: Icons.local_fire_department_rounded,
            color: AppColors.streak,
            label: 'Jaga streak tetap hidup',
            done: streakDone,
            progress: streakDone ? 1 : 0,
          ),
        ],
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.done,
    required this.progress,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool done;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: done ? AppColors.accent : color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            done ? Icons.check_rounded : icon,
            size: 18,
            color: done ? AppColors.success : color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: done ? AppColors.success : AppColors.foreground,
                ),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: AppColors.muted,
                  valueColor: AlwaysStoppedAnimation(
                    done ? AppColors.success : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LessonPath extends StatelessWidget {
  const _LessonPath({required this.exercises, required this.completed});

  final List<Exercise> exercises;
  final int completed;

  static const double _rowHeight = 120;
  static const double _topPad = 54;
  static const double _boxHeight = 84;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const GlassCard(
        child: Text(
          'Belum ada gerakan. Tambahkan variasi dari tab Latihan.',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final finished = completed.clamp(0, exercises.length);
        final amplitude = math.min(width * 0.19, 66.0);
        final points = <Offset>[
          for (var i = 0; i < exercises.length; i++)
            Offset(
              (width / 2 + math.sin(i * 1.1 - 0.9) * amplitude).clamp(
                58.0,
                width - 58.0,
              ),
              _topPad + i * _rowHeight,
            ),
          Offset(width / 2, _topPad + exercises.length * _rowHeight),
        ];
        final height = _topPad + exercises.length * _rowHeight + 80;

        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrailPainter(
                    points: points,
                    progressIndex: finished,
                  ),
                ),
              ),
              for (var i = 0; i < exercises.length; i++)
                Positioned(
                  left: points[i].dx - 60,
                  top: points[i].dy - _boxHeight / 2,
                  child: SizedBox(
                    width: 120,
                    child: _LessonNode(
                      exercise: exercises[i],
                      completed: i < finished,
                      current: i == finished,
                      onTap: () => startExercise(context, exercises[i]),
                    ),
                  ),
                ),
              Positioned(
                left: points.last.dx - 60,
                top: points.last.dy - _boxHeight / 2,
                child: SizedBox(
                  width: 120,
                  child: _GoalNode(completed: finished >= exercises.length),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.points, required this.progressIndex});

  final List<Offset> points;
  final int progressIndex;

  Path _buildPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final curr = pts[i];
      final dx = curr.dx - prev.dx;
      final midY = (prev.dy + curr.dy) / 2;
      path.cubicTo(
        prev.dx + dx * 0.42,
        midY,
        curr.dx - dx * 0.42,
        midY,
        curr.dx,
        curr.dy,
      );
    }
    return path;
  }

  void _drawDotted(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, 2.4, paint);
        }
        distance += 11;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final basePath = _buildPath(points);

    final dotPaint = Paint()..color = AppColors.primary.withValues(alpha: 0.16);
    _drawDotted(canvas, basePath, dotPaint);

    final endIndex = progressIndex.clamp(0, points.length - 1);
    if (endIndex <= 0) return;

    final progressPath = _buildPath(points.sublist(0, endIndex + 1));

    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawPath(progressPath, glowPaint);

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryLight,
          AppColors.primary,
          AppColors.primaryDeep,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(progressPath, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) {
    return oldDelegate.progressIndex != progressIndex ||
        oldDelegate.points != points;
  }
}

class _LessonNode extends StatefulWidget {
  const _LessonNode({
    required this.exercise,
    required this.completed,
    required this.current,
    required this.onTap,
  });

  final Exercise exercise;
  final bool completed;
  final bool current;
  final VoidCallback onTap;

  @override
  State<_LessonNode> createState() => _LessonNodeState();
}

class _LessonNodeState extends State<_LessonNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.current) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant _LessonNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.current && !oldWidget.current) {
      _pulse.repeat();
    } else if (!widget.current && oldWidget.current) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.current ? 72.0 : 62.0;
    final radius = BorderRadius.circular(size * 0.36);
    final active = widget.current || widget.completed;
    final icon = widget.completed
        ? Icons.check_rounded
        : widget.current
        ? widget.exercise.icon.icon
        : Icons.lock_rounded;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _LessonPath._boxHeight,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (widget.current)
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final t = _pulse.value;
                      return Transform.scale(
                        scale: 1 + t * 0.14,
                        child: Opacity(
                          opacity: (1 - t) * 0.5,
                          child: Container(
                            width: size + 12,
                            height: size + 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                (size + 12) * 0.36,
                              ),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    color: widget.completed ? null : Colors.white,
                    gradient: widget.completed
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primaryLight, AppColors.primary],
                          )
                        : null,
                    border: Border.all(
                      color: widget.completed
                          ? Colors.transparent
                          : widget.current
                          ? AppColors.primary
                          : const Color(0xFFE2E8F0),
                      width: widget.current ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: active
                            ? AppColors.primary.withValues(alpha: 0.22)
                            : const Color(0xFF94A3B8).withValues(alpha: 0.08),
                        blurRadius: active ? 18 : 10,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: widget.completed
                        ? Colors.white
                        : widget.current
                        ? AppColors.primaryDeep
                        : const Color(0xFFA9B6C8),
                    size: widget.current ? 30 : 25,
                  ),
                ),
                if (widget.current)
                  Positioned(
                    right: 20,
                    bottom: 4,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.exercise.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: widget.current ? 11 : 10.5,
              fontWeight: widget.current
                  ? FontWeight.w800
                  : widget.completed
                  ? FontWeight.w700
                  : FontWeight.w600,
              color: widget.current
                  ? AppColors.primaryDeep
                  : widget.completed
                  ? AppColors.foreground
                  : AppColors.mutedForeground.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalNode extends StatelessWidget {
  const _GoalNode({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final size = 66.0;
    return GestureDetector(
      onTap: () {
        if (completed) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selesaikan semua gerakan untuk mencapai tujuan.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _LessonPath._boxHeight,
            child: Center(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.36),
                  color: completed ? null : Colors.white,
                  gradient: completed
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primaryLight, AppColors.primary],
                        )
                      : null,
                  border: Border.all(
                    color: completed
                        ? Colors.transparent
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: completed
                          ? AppColors.primary.withValues(alpha: 0.22)
                          : const Color(0xFF94A3B8).withValues(alpha: 0.08),
                      blurRadius: completed ? 18 : 10,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Icon(
                  completed ? Icons.emoji_events_rounded : Icons.flag_rounded,
                  size: 26,
                  color: completed ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            completed ? 'Tercapai' : 'Tujuan',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: completed
                  ? AppColors.primaryDeep
                  : AppColors.mutedForeground.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.dashboard});

  final UserDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final active = dashboard.activeDays.length == 7
        ? dashboard.activeDays
        : List<bool>.filled(7, false);
    final todayIndex = DateTime.now().weekday - 1;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.streak,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Streak ${dashboard.currentStreak} hari',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Freeze ${dashboard.freezes}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Column(
                  children: [
                    Text(
                      const ['S', 'S', 'R', 'K', 'J', 'S', 'M'][i],
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active[i]
                            ? AppColors.primary
                            : i == todayIndex
                            ? AppColors.accent
                            : AppColors.muted,
                        border: i == todayIndex
                            ? Border.all(color: AppColors.primary)
                            : null,
                      ),
                      child: active[i]
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.dashboard});

  final UserDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.xp.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${dashboard.level}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.xp,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Level',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${dashboard.xpIntoLevel} / ${dashboard.xpForNextLevel} XP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppProgressBar(
                  value: dashboard.xpIntoLevel,
                  max: dashboard.xpForNextLevel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachButton extends StatelessWidget {
  const _CoachButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryDeep,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primaryDeep, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.primaryDeep,
                blurRadius: 0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.white),
              SizedBox(width: 7),
              Text(
                'Tanya Pelatih',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
