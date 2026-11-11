import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/stat_ring.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/therapist_scaffold.dart';
import '../../data/mock_data.dart';
import '../../data/models/patient.dart';

class TherapistDetailScreen extends StatefulWidget {
  const TherapistDetailScreen({super.key, required this.patientId});

  final String patientId;

  @override
  State<TherapistDetailScreen> createState() => _TherapistDetailScreenState();
}

class _TherapistDetailScreenState extends State<TherapistDetailScreen> {
  final TextEditingController _note = TextEditingController();
  bool _saved = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patient = MockData.patientById(widget.patientId);
    final firstName = patient.name.split(' ').first;

    return TherapistScaffold(
      title: firstName,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                patient.condition,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
            StatusBadge(
              label: patient.status.label,
              tone: switch (patient.status) {
                PatientStatus.routine => StatusTone.success,
                PatientStatus.needsAttention => StatusTone.warning,
                PatientStatus.inactive => StatusTone.muted,
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  StatRing(
                    value: patient.adherence,
                    max: 100,
                    size: 80,
                    stroke: 8,
                    child: Text(
                      '${patient.adherence}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kepatuhan',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kesalahan tersering',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final error in patient.errors)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• $error',
                          style: const TextStyle(fontSize: 13.5, height: 1.35),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Skor form mingguan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 140,
                child: _WeeklyScoreChart(scores: patient.scores),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Catatan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: _note,
                  maxLines: 3,
                  onChanged: (_) => setState(() => _saved = false),
                  style: const TextStyle(fontSize: 14.5),
                  decoration: const InputDecoration(
                    hintText: 'Tulis catatan untuk pasien...',
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GlassButton(
                label: _saved ? 'Tersimpan' : 'Simpan catatan',
                icon: Icon(_saved ? Icons.check_rounded : Icons.save_rounded),
                onPressed: () => setState(() => _saved = true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyScoreChart extends StatelessWidget {
  const _WeeklyScoreChart({required this.scores});

  final List<int> scores;

  static const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < scores.length; i++)
        if (scores[i] > 0) FlSpot(i.toDouble(), scores[i].toDouble()),
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
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _days.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _days[index],
                    style: const TextStyle(
                      fontSize: 10,
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
            dotData: const FlDotData(show: true, getDotPainter: _dotPainter),
          ),
        ],
      ),
    );
  }

  static FlDotPainter _dotPainter(
    FlSpot spot,
    double percent,
    LineChartBarData barData,
    int index,
  ) {
    return FlDotCirclePainter(
      radius: 3.5,
      color: AppColors.primary,
      strokeWidth: 0,
      strokeColor: Colors.transparent,
    );
  }
}
