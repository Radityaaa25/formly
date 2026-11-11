import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_screen.dart';
import '../../features/coach/chat_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/session/session_screen.dart';
import '../../features/splash/splash_gate.dart';
import '../../features/summary/summary_screen.dart';
import '../../features/therapist/therapist_detail_screen.dart';
import '../../features/therapist/therapist_list_screen.dart';
import '../../features/therapist/therapist_program_screen.dart';
import '../widgets/app_shell.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const auth = '/auth';
  static const onboarding = '/onboarding';
  static const home = '/beranda';
  static const library = '/latihan';
  static const progress = '/progres';
  static const profile = '/profil';
  static const session = '/sesi';
  static const summary = '/ringkasan';
  static const coach = '/tanya';
  static const therapist = '/terapis';
  static const therapistProgram = '/terapis/program';
}

CustomTransitionPage<void> _fadeSlidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashGate(),
    ),
    GoRoute(
      path: AppRoutes.auth,
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.library,
              builder: (context, state) => const LibraryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.progress,
              builder: (context, state) => const ProgressScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.session,
      pageBuilder: (context, state) {
        final params = state.uri.queryParameters;
        return _fadeSlidePage(
          state,
          SessionScreen(
            exerciseId: params['ex'] ?? 'squat',
            variationName: params['var'],
            sets: int.tryParse(params['sets'] ?? ''),
            reps: int.tryParse(params['reps'] ?? ''),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.summary,
      pageBuilder: (context, state) =>
          _fadeSlidePage(state, const SummaryScreen()),
    ),
    GoRoute(
      path: AppRoutes.coach,
      pageBuilder: (context, state) =>
          _fadeSlidePage(state, const ChatScreen()),
    ),
    GoRoute(
      path: AppRoutes.therapistProgram,
      builder: (context, state) => const TherapistProgramScreen(),
    ),
    GoRoute(
      path: AppRoutes.therapist,
      builder: (context, state) => const TherapistListScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.therapist}/:id',
      builder: (context, state) =>
          TherapistDetailScreen(patientId: state.pathParameters['id'] ?? ''),
    ),
  ],
);
