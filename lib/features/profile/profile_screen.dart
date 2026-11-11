import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/wordmark.dart';
import '../../state/app_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);
    final rehab = mode == AppMode.rehab;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wordmark(fontSize: 30),
              const SizedBox(height: 22),
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF60A5FA), AppColors.primary],
                        ),
                      ),
                      child: Text(
                        rehab ? 'SW' : 'RA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rehab ? 'Sari Wulandari' : 'Raka Pratama',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rehab
                              ? 'Pasien · Fisioterapis Dimas'
                              : 'Level 5 · Bandung',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        rehab
                            ? Icons.favorite_rounded
                            : Icons.fitness_center_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rehab ? 'Mode Rehab' : 'Mode Workout',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rehab
                                ? 'Program latihan dari fisioterapis'
                                : 'Latihan mandiri di gym & rumah',
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
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suara pelatih',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SettingsRow(
                      label: 'Volume · ${settings.volume}%',
                      child: Slider(
                        value: settings.volume.toDouble(),
                        min: 0,
                        max: 100,
                        onChanged: (value) => settingsNotifier.update(
                          settings.copyWith(volume: value.round()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsRow(
                      label: 'Kecepatan bicara',
                      child: Column(
                        children: [
                          Slider(
                            value: settings.speechRate.toDouble(),
                            min: 0,
                            max: 100,
                            onChanged: (value) => settingsNotifier.update(
                              settings.copyWith(speechRate: value.round()),
                            ),
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pelan',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                              Text(
                                'Cepat',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsRow(
                      label: 'Tingkat detail',
                      child: _Segmented<bool>(
                        value: settings.detailedCorrections,
                        options: const [
                          (value: false, label: 'Ringkas'),
                          (value: true, label: 'Lengkap'),
                        ],
                        onChanged: (value) => settingsNotifier.update(
                          settings.copyWith(detailedCorrections: value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mode senyap',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Switch(
                          value: settings.silentMode,
                          onChanged: (value) => settingsNotifier.update(
                            settings.copyWith(silentMode: value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_rounded,
                      color: AppColors.primary,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Pengingat latihan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () async {
                        final parsed = _parseTime(settings.reminderTime);
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: parsed,
                        );
                        if (picked != null) {
                          settingsNotifier.update(
                            settings.copyWith(
                              reminderTime: _formatTime(picked),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          settings.reminderTime,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.success,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Privasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Video tidak pernah disimpan. Hanya angka hasil latihan yang tersimpan.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    if (Env.hasSupabase) {
                      await Supabase.instance.client.auth.signOut();
                    }
                    if (context.mounted) context.go(AppRoutes.auth);
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Keluar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mutedForeground,
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 18, minute: 30);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 18,
      minute: int.tryParse(parts[1]) ?? 30,
    );
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<({T value, String label})> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onChanged(option.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == option.value
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: value == option.value
                        ? [
                            BoxShadow(
                              color: AppColors.navy.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    option.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: value == option.value
                          ? AppColors.primary
                          : AppColors.mutedForeground,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
