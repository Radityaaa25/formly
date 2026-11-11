import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/bottom_sheet.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/screen_title.dart';
import '../../data/mock_data.dart';
import '../../data/models/exercise.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Exercise> get _results {
    return MockData.exercises.where((exercise) {
      final matchesQuery = exercise.name.toLowerCase().contains(
        _query.toLowerCase(),
      );
      if (_selectedCategory == null) return matchesQuery;
      if (_selectedCategory == 'Samping') {
        return matchesQuery && exercise.side == ExerciseSide.side;
      }
      if (_selectedCategory == 'Depan') {
        return matchesQuery && exercise.side == ExerciseSide.front;
      }
      return matchesQuery;
    }).toList();
  }

  void _openDetail(Exercise exercise) {
    showGlassSheet<void>(
      context,
      builder: (sheetContext) => _ExerciseDetail(
        exercise: exercise,
        onStart: () {
          Navigator.of(sheetContext).pop();
          context.push('${AppRoutes.session}?ex=${exercise.id}');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenTitle(
              title: 'Latihan',
              subtitle: 'Pilih gerakan untuk memulai',
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
            Row(
              children: [
                AppChip(
                  label: 'Semua',
                  active: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                AppChip(
                  label: 'Tampak Samping',
                  active: _selectedCategory == 'Samping',
                  onTap: () => setState(() => _selectedCategory = 'Samping'),
                ),
                const SizedBox(width: 8),
                AppChip(
                  label: 'Tampak Depan',
                  active: _selectedCategory == 'Depan',
                  onTap: () => setState(() => _selectedCategory = 'Depan'),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
                  childAspectRatio: 0.88,
                ),
                itemBuilder: (context, index) {
                  final exercise = results[index];
                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () => _openDetail(exercise),
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
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                exercise.icon.icon,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                exercise.side.label,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          exercise.difficulty.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseDetail extends StatelessWidget {
  const _ExerciseDetail({required this.exercise, required this.onStart});

  final Exercise exercise;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
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
      ],
    );
  }
}
