import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../core/router/app_router.dart';
import '../../core/services/prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/wordmark.dart';
import '../../state/app_state.dart';
import '../../state/auth_state.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _slides = [
    (
      icon: Icons.photo_camera_rounded,
      title: 'Kamera jadi mata',
      text: 'AI di HP-mu menghitung rep dan membaca gerakan. Video tidak pernah disimpan.',
    ),
    (
      icon: Icons.mic_rounded,
      title: 'Suara jadi pelatih',
      text: 'Koreksi form langsung lewat suara, tanpa perlu melihat layar.',
    ),
    (
      icon: Icons.trending_up_rounded,
      title: 'Progres terlihat jelas',
      text: 'Skor form, rep, dan konsistensi tercatat rapi setiap hari.',
    ),
  ];

  bool get _done => _page >= _slides.length;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    _controller.animateToPage(
      _page + 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                child: Row(
                  children: [
                    const Wordmark(fontSize: 26),
                    const Spacer(),
                    if (!_done)
                      TextButton(
                        onPressed: () => _controller.animateToPage(
                          _slides.length,
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOut,
                        ),
                        child: const Text(
                          'Lewati',
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _page = value),
                  children: [
                    for (final slide in _slides)
                      _Slide(
                        icon: slide.icon,
                        title: slide.title,
                        text: slide.text,
                      ),
                    const _RoleSelection(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: _done
                    ? const Text(
                        'Alat bantu latihan, bukan pengganti fisioterapis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedForeground,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < _slides.length; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  height: 8,
                                  width: i == _page ? 24 : 8,
                                  decoration: BoxDecoration(
                                    color: i == _page
                                        ? AppColors.primary
                                        : AppColors.accent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          GlassButton(
                            label: _page == _slides.length - 1
                                ? 'Mulai'
                                : 'Lanjut',
                            size: GlassButtonSize.large,
                            expand: true,
                            onPressed: _next,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 1),
                  Center(child: _Illustration(icon: icon)),
                  const SizedBox(height: 32),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sky.withValues(alpha: 0.18),
            ),
          ),
          Transform.rotate(
            angle: -0.15,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSelection extends ConsumerWidget {
  const _RoleSelection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appRoleProvider);
    final loggedIn =
        Env.hasSupabase && Supabase.instance.client.auth.currentSession != null;

    final roles = <_RoleOption>[];

    if (role == AppRole.therapist) {
      roles.add(
        _RoleOption(
          icon: Icons.medical_services_rounded,
          title: 'Terapis',
          subtitle: 'Pantau pasien & buat program',
          mode: AppMode.workout,
          route: AppRoutes.therapist,
        ),
      );
    } else if (role == AppRole.patient) {
      roles.add(
        _RoleOption(
          icon: Icons.favorite_rounded,
          title: 'Pasien (Rehab)',
          subtitle: 'Program dari fisioterapis',
          mode: AppMode.rehab,
          route: AppRoutes.home,
        ),
      );
    } else {
      roles.add(
        _RoleOption(
          icon: Icons.fitness_center_rounded,
          title: 'Latihan Mandiri',
          subtitle: 'Gym & olahraga umum',
          mode: AppMode.workout,
          route: AppRoutes.home,
        ),
      );
      if (!loggedIn) {
        roles.add(
          _RoleOption(
            icon: Icons.favorite_rounded,
            title: 'Pasien (Rehab)',
            subtitle: 'Coba alur program rehabilitasi',
            mode: AppMode.rehab,
            route: AppRoutes.home,
          ),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kamu pakai Formly sebagai?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gerak benar, hasil lebih aman.',
            style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 20),
          for (final option in roles) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              onTap: () => _select(context, ref, option),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      option.icon,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option.subtitle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.mutedForeground,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    _RoleOption option,
  ) async {
    ref.read(appModeProvider.notifier).setMode(option.mode);
    await Prefs.saveMode(option.mode);
    await Prefs.setOnboardingDone();
    if (context.mounted) context.go(option.route);
  }
}

class _RoleOption {
  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppMode mode;
  final String route;
}
