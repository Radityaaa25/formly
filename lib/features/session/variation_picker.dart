import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bottom_sheet.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/exercise.dart';
import '../../data/models/exercise_variation.dart';
import '../../state/user_data_state.dart';
import 'variation_form.dart';

/// Buka daftar variasi lalu mulai sesi dengan variasi yang dipilih.
Future<void> startExercise(BuildContext context, Exercise exercise) async {
  final variation = await showVariationPicker(context, exercise: exercise);
  if (variation == null || !context.mounted) return;
  startVariation(context, exercise, variation);
}

Future<ExerciseVariation?> showVariationPicker(
  BuildContext context, {
  required Exercise exercise,
}) {
  return showGlassSheet<ExerciseVariation>(
    context,
    builder: (sheetContext) => _VariationPicker(
      exercise: exercise,
      onSelected: (variation) => Navigator.of(sheetContext).pop(variation),
    ),
  );
}

void startVariation(
  BuildContext context,
  Exercise exercise,
  ExerciseVariation variation,
) {
  final route = Uri(
    path: AppRoutes.session,
    queryParameters: {
      'ex': exercise.id,
      'var': variation.name,
      'sets': '${variation.sets}',
      'reps': '${variation.reps}',
    },
  ).toString();
  context.push(route);
}

class _VariationPicker extends ConsumerWidget {
  const _VariationPicker({required this.exercise, required this.onSelected});

  final Exercise exercise;
  final ValueChanged<ExerciseVariation> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custom = ref.watch(customExercisesProvider).value ?? const [];
    final presets = presetsForExercise(exercise);
    final customVariations = custom
        .where((item) => item.baseExerciseId == exercise.id)
        .map(
          (item) => ExerciseVariation(
            id: item.id,
            baseExerciseId: item.baseExerciseId,
            name: item.name,
            sets: item.sets,
            reps: item.reps,
            note: item.note,
            isCustom: true,
          ),
        )
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryLight, AppColors.primaryDeep],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(exercise.icon.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih variasi',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${exercise.name} · ${exercise.difficulty.label} · kamera ${exercise.side.label.toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 430),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Variasi tersedia',
                ),
                const SizedBox(height: 10),
                for (final variation in presets) ...[
                  _VariationCard(
                    variation: variation,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelected(variation);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                if (customVariations.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const _SectionLabel(
                    icon: Icons.person_rounded,
                    label: 'Variasi buatanmu',
                  ),
                  const SizedBox(height: 10),
                  for (final variation in customVariations) ...[
                    _VariationCard(
                      variation: variation,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelected(variation);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
                const SizedBox(height: 8),
                CustomVariationButton(
                  onTap: () async {
                    final created = await showCreateVariationSheet(
                      context,
                      base: exercise,
                      onCreate: (custom) async {
                        await ref
                            .read(customExercisesProvider.notifier)
                            .add(custom);
                      },
                    );
                    if (created == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Variasi baru siap dipakai'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryDeep),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _VariationCard extends StatelessWidget {
  const _VariationCard({required this.variation, required this.onTap});

  final ExerciseVariation variation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(13),
      radius: 18,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: variation.isCustom
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              variation.isCustom ? Icons.person_rounded : Icons.bolt_rounded,
              color: variation.isCustom
                  ? AppColors.success
                  : AppColors.primaryDeep,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        variation.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (variation.isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'SAYA',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  variation.volumeLabel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDeep,
                  ),
                ),
                if (variation.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    variation.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomVariationButton extends StatelessWidget {
  const CustomVariationButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.accent.withValues(alpha: 0.5),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 19, color: AppColors.primaryDeep),
              SizedBox(width: 6),
              Text(
                'Buat variasi sendiri',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
