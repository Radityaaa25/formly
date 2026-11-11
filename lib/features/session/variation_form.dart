import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/bottom_sheet.dart';
import '../../core/widgets/glass_button.dart';
import '../../data/models/exercise.dart';
import '../../state/user_data_state.dart';

/// Menampilkan form pembuatan variasi. Mengembalikan `true` bila variasi
/// berhasil dibuat dan disimpan.
Future<bool?> showCreateVariationSheet(
  BuildContext context, {
  required Exercise base,
  required Future<void> Function(CustomExercise custom) onCreate,
}) {
  return showGlassSheet<bool>(
    context,
    builder: (sheetContext) => VariationForm(base: base, onCreate: onCreate),
  );
}

class VariationForm extends StatefulWidget {
  const VariationForm({super.key, required this.base, required this.onCreate});

  final Exercise base;
  final Future<void> Function(CustomExercise custom) onCreate;

  @override
  State<VariationForm> createState() => _VariationFormState();
}

class _VariationFormState extends State<VariationForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sets = TextEditingController(text: '3');
  final _reps = TextEditingController(text: '10');
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name.text = '${widget.base.name} Versi Saya';
  }

  @override
  void dispose() {
    _name.dispose();
    _sets.dispose();
    _reps.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final custom = CustomExercise(
      id: const Uuid().v4(),
      name: _name.text.trim(),
      baseExerciseId: widget.base.id,
      sets: int.tryParse(_sets.text.trim()) ?? 3,
      reps: int.tryParse(_reps.text.trim()) ?? 10,
      note: _note.text.trim(),
      createdAt: DateTime.now(),
    );
    try {
      await widget.onCreate(custom);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.base.icon.icon,
                    color: AppColors.primaryDeep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buat variasi',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'dari ${widget.base.name}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Atur set, repetisi, dan catatan pribadi. Variasi disimpan di perangkat ini.',
              style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Nama variasi'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Nama tidak boleh kosong'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sets,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Set'),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed < 1 || parsed > 20) {
                        return '1-20';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _reps,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: widget.base.kind == ExerciseKind.timed
                          ? 'Detik'
                          : 'Repetisi',
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed < 1 || parsed > 200) {
                        return '1-200';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Contoh: fokus lutut kanan',
              ),
            ),
            const SizedBox(height: 18),
            GlassButton(
              label: 'Simpan Variasi',
              icon: const Icon(Icons.check_rounded),
              size: GlassButtonSize.large,
              expand: true,
              loading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
