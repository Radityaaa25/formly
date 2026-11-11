import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../core/router/app_router.dart';
import '../../core/services/prefs.dart';
import '../../state/app_state.dart';
import '../../state/auth_state.dart';
import 'formly_splash.dart';

class SplashGate extends ConsumerWidget {
  const SplashGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormlySplash(
      fontFamily: 'PlusJakartaSans',
      onFinished: () => _continue(context, ref),
    );
  }

  bool _hasSession() {
    if (!Env.hasSupabase) return false;
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    final hasSession = _hasSession();
    final fallback = hasSession ? AppRoutes.home : AppRoutes.auth;
    debugPrint('[Splash] start (session=$hasSession)');

    var destination = fallback;
    try {
      destination = await _resolveDestination(ref, hasSession).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          debugPrint('[Splash] timeout, fallback to $fallback');
          return fallback;
        },
      );
    } catch (error, stack) {
      debugPrint('[Splash] error: $error\n$stack');
    }

    debugPrint('[Splash] go $destination');
    if (context.mounted) context.go(destination);
  }

  Future<String> _resolveDestination(WidgetRef ref, bool hasSession) async {
    var onboardingDone = false;
    try {
      onboardingDone = await Prefs.onboardingDone().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      final savedMode = await Prefs.savedMode().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      if (savedMode != null) {
        ref.read(appModeProvider.notifier).setMode(savedMode);
      }
    } catch (error) {
      debugPrint('[Splash] prefs error: $error');
    }

    if (!hasSession) return AppRoutes.auth;

    var role = AppRole.self;
    try {
      final results = await Future.wait<Object?>([
        resolveCurrentRole().timeout(
          const Duration(seconds: 3),
          onTimeout: () => AppRole.self,
        ),
        resolveCurrentUser().timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        ),
      ]);
      role = results[0] as AppRole;
      ref.read(appRoleProvider.notifier).setRole(role);
      ref
          .read(currentUserProvider.notifier)
          .setUser(results[1] as CurrentUser?);
    } catch (error) {
      debugPrint('[Splash] profile error: $error');
    }

    if (!onboardingDone) return AppRoutes.onboarding;
    return role == AppRole.therapist ? AppRoutes.therapist : AppRoutes.home;
  }
}
