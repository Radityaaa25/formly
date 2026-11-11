import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/bottom_sheet.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/screen_title.dart';
import '../../data/mock_data.dart';
import '../../data/models/exercise.dart';
import '../../data/models/exercise_variation.dart';
import '../../state/user_data_state.dart';
import '../session/variation_form.dart';
import '../session/variation_picker.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  ExerciseSide? _side;
  ExerciseDifficulty? _difficulty;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Exercise> get _all =>
      ref.read(exerciseCatalogProvider).value ?? MockData.exercises;

  List<Exercise> get _results {
    final query = _query.trim().toLowerCase();
    return _all.where((exercise) {
      final matchesQuery =
          query.isEmpty || exercise.name.toLowerCase().contains(query);
      final matchesSide = _side == null || exercise.side == _side;
      final matchesDifficulty =
          _difficulty == null || exercise.difficulty == _difficulty;
      return matchesQuery && matchesSide && matchesDifficulty;
    }).toList();
  }

  void _start(Exercise exercise) {
    startExercise(context, exercise);
  }

  void _startCustom(CustomExercise custom) {
    final base = _baseExercise(custom.baseExerciseId);
    startVariation(
      context,
      base,
      ExerciseVariation(
        id: custom.id,
        baseExerciseId: custom.baseExerciseId,
        name: custom.name,
        sets: custom.sets,
        reps: custom.reps,
        note: custom.note,
        isCustom: true,
      ),
    );
  }

  Exercise _baseExercise(String id) {
    return _all.firstWhere(
      (exercise) => exercise.id == id,
      orElse: () => MockData.exercises.first,
    );
  }

  void _openDetail(Exercise exercise) {
    showGlassSheet<void>(
      context,
      builder: (sheetContext) => _ExerciseDetail(
        exercise: exercise,
        onStart: () {
          Navigator.of(sheetContext).pop();
          _start(exercise);
        },
        onVariation: () {
          Navigator.of(sheetContext).pop();
          _openVariation(exercise);
        },
      ),
    );
  }

  Future<void> _openVariation(Exercise base) async {
    final created = await showCreateVariationSheet(
      context,
      base: base,
      onCreate: (custom) async {
        await ref.read(customExercisesProvider.notifier).add(custom);
      },
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Variasi baru disimpan'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteCustom(CustomExercise custom) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus variasi?'),
        content: Text('"${custom.name}" akan dihapus dari perangkat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(customExercisesProvider.notifier).remove(custom.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(exerciseCatalogProvider);
    final results = _results;
    final custom = ref.watch(customExercisesProvider).value ?? const [];

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenTitle(
              title: 'Latihan',
              subtitle: 'Pilih gerakan atau buat variasi sendiri',
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Cari gerakan (Squat, Push-up, ...)',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.mutedForeground,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.mutedForeground,
                    size: 22,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  AppChip(
                    label: 'Semua',
                    active: _side == null && _difficulty == null,
                    onTap: () => setState(() {
                      _side = null;
                      _difficulty = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  AppChip(
                    label: 'Samping',
                    active: _side == ExerciseSide.side,
                    onTap: () => setState(
                      () => _side = _side == ExerciseSide.side
                          ? null
                          : ExerciseSide.side,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppChip(
                    label: 'Depan',
                    active: _side == ExerciseSide.front,
                    onTap: () => setState(
                      () => _side = _side == ExerciseSide.front
                          ? null
                          : ExerciseSide.front,
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (final difficulty in ExerciseDifficulty.values) ...[
                    AppChip(
                      label: difficulty.label,
                      active: _difficulty == difficulty,
                      onTap: () => setState(
                        () => _difficulty = _difficulty == difficulty
                            ? null
                            : difficulty,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            if (custom.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Variasi saya',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${custom.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: custom.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = custom[index];
                    return _CustomExerciseCard(
                      custom: item,
                      base: _baseExercise(item.baseExerciseId),
                      onPlay: () => _startCustom(item),
                      onDelete: () => _deleteCustom(item),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Katalog gerakan',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${results.length} gerakan',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: AppColors.mutedForeground.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gerakan tidak ditemukan',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 186,
                ),
                itemBuilder: (context, index) {
                  final exercise = results[index];
                  return _ExerciseCard(
                    exercise: exercise,
                    onTap: () => _openDetail(exercise),
                    onStart: () => _start(exercise),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onTap,
    required this.onStart,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  exercise.icon.icon,
                  color: AppColors.primaryDeep,
                  size: 22,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  exercise.side.label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            exercise.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            exercise.difficulty.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            width: double.infinity,
            child: _QuickActionButton(
              label: 'Mulai',
              icon: Icons.play_arrow_rounded,
              onPressed: onStart,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryDeep, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.primaryDeep,
                blurRadius: 0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
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

class _CustomExerciseCard extends StatelessWidget {
  const _CustomExerciseCard({
    required this.custom,
    required this.base,
    required this.onPlay,
    required this.onDelete,
  });

  final CustomExercise custom;
  final Exercise base;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        onTap: onPlay,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.sky.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(base.icon.icon, color: AppColors.sky, size: 18),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              custom.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            Text(
              '${custom.sets} set · ${custom.reps} rep',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Mulai ${base.name}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseDetail extends StatelessWidget {
  const _ExerciseDetail({
    required this.exercise,
    required this.onStart,
    required this.onVariation,
  });

  final Exercise exercise;
  final VoidCallback onStart;
  final VoidCallback onVariation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 340),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.difficulty.label} · Kamera ${exercise.side.label.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Icon(
                      Icons.smartphone_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Cara menaruh HP',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  exercise.placement,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kunci form',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final tip in exercise.tips) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(fontSize: 14, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        GlassButton(
          label: 'Mulai Latihan',
          icon: const Icon(Icons.play_arrow_rounded),
          size: GlassButtonSize.large,
          expand: true,
          onPressed: onStart,
        ),
        const SizedBox(height: 10),
        GlassButton(
          label: 'Buat Variasi',
          icon: const Icon(Icons.tune_rounded),
          variant: GlassButtonVariant.secondary,
          expand: true,
          onPressed: onVariation,
        ),
      ],
    );
  }
}
