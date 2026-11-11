import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/therapist_scaffold.dart';
import '../../data/mock_data.dart';
import '../../data/models/patient.dart';

class TherapistListScreen extends StatelessWidget {
  const TherapistListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TherapistScaffold(
      title: 'Pasien',
      showBack: false,
      action: TherapistActionButton(
        label: 'Program',
        icon: Icons.add_rounded,
        onTap: () => context.push(AppRoutes.therapistProgram),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Fisioterapis Dimas · ${MockData.patients.length} pasien aktif',
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < MockData.patients.length; i++) ...[
                _PatientRow(patient: MockData.patients[i]),
                if (i != MockData.patients.length - 1)
                  Divider(
                    height: 1,
                    color: AppColors.border.withValues(alpha: 0.6),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.therapist}/${patient.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Text(
                  patient.initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${patient.condition} · ${patient.lastSession}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: patient.status.label,
                tone: switch (patient.status) {
                  PatientStatus.routine => StatusTone.success,
                  PatientStatus.needsAttention => StatusTone.warning,
                  PatientStatus.inactive => StatusTone.muted,
                },
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedForeground,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
