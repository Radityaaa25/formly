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
      builder: (context, state) =>
          SessionScreen(exerciseId: state.uri.queryParameters['ex'] ?? 'squat'),
    ),
    GoRoute(
      path: AppRoutes.summary,
      builder: (context, state) => const SummaryScreen(),
    ),
    GoRoute(
      path: AppRoutes.coach,
      builder: (context, state) => const ChatScreen(),
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
