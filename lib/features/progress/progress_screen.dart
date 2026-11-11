import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/badge_tile.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/screen_title.dart';
import '../../data/mock_data.dart';
import '../../data/models/user_profile.dart';
import '../../state/app_state.dart';
import '../../state/user_data_state.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final workout = mode == AppMode.workout;
    final dashboard =
        ref.watch(userDashboardProvider).value ??
        (Env.hasSupabase ? const UserDashboard() : _demoDashboard());
    final week = dashboard.week;
    final hasScores = week.any((day) => day.score > 0);
    final activeCount = dashboard.activeDays.where((day) => day).length;
    const weeklyTarget = 5;
    final targetProgress = (activeCount / weeklyTarget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenTitle(title: 'Progres', subtitle: 'Minggu ini'),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Skor form',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (hasScores)
                      SizedBox(height: 160, child: _ScoreChart(week: week))
                    else
                      const _EmptyChart(
                        icon: Icons.show_chart_rounded,
                        message: 'Belum ada skor form minggu ini',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Volume rep',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (hasScores)
                      SizedBox(height: 140, child: _VolumeChart(week: week))
                    else
                      const _EmptyChart(
                        icon: Icons.bar_chart_rounded,
                        message: 'Belum ada data repetisi minggu ini',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'November 2026',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _Calendar(),
                    if (workout) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Target mingguan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$activeCount dari $weeklyTarget hari',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            '${(targetProgress * 100).round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppProgressBar(value: activeCount, max: weeklyTarget),
                    ],
                    const SizedBox(height: 14),
                    const Text(
                      'Istirahat itu bagian dari latihan.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (workout) ...[
                const SizedBox(height: 28),
                const Text(
                  'Badge',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: MockData.badges.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final badge = MockData.badges[index];
                    return BadgeTile(
                      label: badge.label,
                      unlocked: Env.hasSupabase
                          ? dashboard.badges.contains(badge.id)
                          : badge.unlocked,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreChart extends StatelessWidget {
  const _ScoreChart({required this.week});

  final List<DayStat> week;

  @override
  Widget build(BuildContext context) {
    final scores = week;
    final spots = <FlSpot>[
      for (var i = 0; i < scores.length; i++)
        if (scores[i].score > 0)
          FlSpot(i.toDouble(), scores[i].score.toDouble()),
    ];

    return LineChart(
      LineChartData(
        minY: 50,
        maxY: 100,
        minX: 0,
        maxX: (scores.length - 1).toDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 10,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= scores.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    scores[index].shortLabel,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.28,
            barWidth: 3,
            color: AppColors.primary,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  AppColors.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeChart extends StatelessWidget {
  const _VolumeChart({required this.week});

  final List<DayStat> week;

  @override
  Widget build(BuildContext context) {
    final scores = week;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= scores.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    scores[index].shortLabel,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < scores.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: scores[i].reps.toDouble(),
                  color: AppColors.sky,
                  width: 14,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 34,
              color: AppColors.mutedForeground.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

UserDashboard _demoDashboard() {
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

class _Calendar extends StatelessWidget {
  const _Calendar();

  static const _weekLabels = ['M', 'S', 'S', 'R', 'K', 'J', 'S'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (final label in _weekLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 30,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            final day = index + 1;
            final activity = MockData.monthDays[day];
            final (background, foreground) = switch (activity) {
              DayActivity.active => (AppColors.primary, Colors.white),
              DayActivity.frozen => (
                AppColors.sky.withValues(alpha: 0.25),
                AppColors.primary,
              ),
              DayActivity.rest => (AppColors.muted, AppColors.mutedForeground),
              null => (Colors.transparent, AppColors.mutedForeground),
            };
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            _LegendDot(color: AppColors.primary, label: 'Aktif'),
            SizedBox(width: 16),
            _LegendDot(color: Color(0x6638BDF8), label: 'Freeze'),
            SizedBox(width: 16),
            _LegendDot(color: Color(0x55616C82), label: 'Istirahat'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
