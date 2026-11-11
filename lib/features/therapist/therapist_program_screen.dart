import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/therapist_scaffold.dart';
import '../../data/mock_data.dart';
import '../../data/models/program.dart';
import '../../state/app_state.dart';

class TherapistProgramScreen extends ConsumerStatefulWidget {
  const TherapistProgramScreen({super.key});

  @override
  ConsumerState<TherapistProgramScreen> createState() =>
      _TherapistProgramScreenState();
}

class _TherapistProgramScreenState
    extends ConsumerState<TherapistProgramScreen> {
  String _patientId = MockData.patients.first.id;
  final Set<String> _exerciseIds = {};
  final Set<String> _days = {'Sen', 'Rab', 'Jum'};
  int _sets = 3;
  int _reps = 10;
  int? _editingId;

  bool get _valid => _exerciseIds.isNotEmpty && _days.isNotEmpty;

  void _toggle(Set<String> target, String value) {
    setState(() {
      if (!target.remove(value)) target.add(value);
    });
  }

  void _reset() {
    setState(() {
      _patientId = MockData.patients.first.id;
      _exerciseIds.clear();
      _days
        ..clear()
        ..addAll({'Sen', 'Rab', 'Jum'});
      _sets = 3;
      _reps = 10;
      _editingId = null;
    });
  }

  void _save() {
    if (!_valid) return;
    final patient = MockData.patientById(_patientId);
    final program = TherapistProgram(
      id: _editingId ?? DateTime.now().millisecondsSinceEpoch,
      patientId: patient.id,
      patientName: patient.name,
      exerciseIds: [
        for (final id in MockData.exercises.map((e) => e.id))
          if (_exerciseIds.contains(id)) id,
      ],
      sets: _sets,
      reps: _reps,
      days: [
        for (final day in MockData.dayNames)
          if (_days.contains(day)) day,
      ],
    );
    ref
        .read(therapistProgramsProvider.notifier)
        .save(program, editingId: _editingId);
    _reset();
  }

  void _edit(TherapistProgram program) {
    setState(() {
      _editingId = program.id;
      _patientId = program.patientId;
      _exerciseIds
        ..clear()
        ..addAll(program.exerciseIds);
      _days
        ..clear()
        ..addAll(program.days);
      _sets = program.sets;
      _reps = program.reps;
    });
  }

  @override
  Widget build(BuildContext context) {
    final programs = ref.watch(therapistProgramsProvider);

    return TherapistScaffold(
      title: 'Buat Program',
      children: [
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Pasien'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _patientId,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(20),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                    items: [
                      for (final patient in MockData.patients)
                        DropdownMenuItem(
                          value: patient.id,
                          child: Text(patient.name),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _patientId = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _FieldLabel('Gerakan'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final exercise in MockData.exercises)
                    _TogglePill(
                      label: exercise.name,
                      active: _exerciseIds.contains(exercise.id),
                      onTap: () => _toggle(_exerciseIds, exercise.id),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _Stepper(
                      label: 'Set',
                      value: _sets,
                      onChanged: (value) => setState(() => _sets = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stepper(
                      label: 'Rep',
                      value: _reps,
                      onChanged: (value) => setState(() => _reps = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _FieldLabel('Hari'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final day in MockData.dayNames)
                    _DayPill(
                      label: day,
                      active: _days.contains(day),
                      onTap: () => _toggle(_days, day),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_editingId != null) ...[
                    Expanded(
                      child: GlassButton(
                        label: 'Batal',
                        variant: GlassButtonVariant.secondary,
                        expand: true,
                        onPressed: _reset,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: GlassButton(
                      label: _editingId == null
                          ? 'Buat Program'
                          : 'Simpan perubahan',
                      expand: true,
                      onPressed: _valid ? _save : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Program aktif',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 12),
        for (final program in programs) ...[
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${program.exerciseIds.map((id) => MockData.exerciseById(id).name).join(', ')} · ${program.sets}×${program.reps} · ${program.days.join(' ')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _edit(program),
                  icon: const Icon(
                    Icons.edit_rounded,
                    size: 19,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(therapistProgramsProvider.notifier)
                      .remove(program.id),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.destructive,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.mutedForeground,
        ),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.accent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.foreground,
          ),
        ),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: () => onChanged(value > 1 ? value - 1 : value),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                onTap: () => onChanged(value + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 18)),
      ),
    );
  }
}
