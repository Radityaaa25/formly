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

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    final onboardingDone = await Prefs.onboardingDone();
    final savedMode = await Prefs.savedMode();
    if (savedMode != null) {
      ref.read(appModeProvider.notifier).setMode(savedMode);
    }

    var loggedIn = false;
    if (Env.hasSupabase) {
      loggedIn = Supabase.instance.client.auth.currentSession != null;
    }

    if (loggedIn) {
      ref.read(appRoleProvider.notifier).setRole(await resolveCurrentRole());
      ref
          .read(currentUserProvider.notifier)
          .setUser(await resolveCurrentUser());
    }

    if (!context.mounted) return;

    if (!loggedIn) {
      context.go(AppRoutes.auth);
      return;
    }
    if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
      return;
    }
    final role = ref.read(appRoleProvider);
    context.go(
      role == AppRole.therapist ? AppRoutes.therapist : AppRoutes.home,
    );
  }
}
