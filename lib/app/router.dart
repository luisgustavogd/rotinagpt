import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/di/providers.dart';
import '../data/remote/firestore_paths.dart';
import '../domain/profile/user_profile.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/health/health_screen.dart';
import '../features/more/more_screen.dart';
import '../features/nutrition/nutrition_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/routine/routine_screen.dart';
import '../features/settings/edit_profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/today/today_screen.dart';

/// Faz o `GoRouter` reagir a mudanças no estado de autenticação, disparando
/// reavaliação do `redirect` sempre que o usuário loga/desloga.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshStream = GoRouterRefreshStream(
    ref.watch(authGatewayProvider).authStateChanges(),
  );
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    initialLocation: '/today',
    refreshListenable: refreshStream,
    redirect: (context, state) async {
      final loggingIn = state.matchedLocation == '/sign-in';
      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null;

      final user = authState.valueOrNull;
      if (user == null) return loggingIn ? null : '/sign-in';
      if (loggingIn) return '/today';

      final onOnboarding = state.matchedLocation == '/onboarding';
      final firestore = ref.read(firestoreProvider);
      final paths = FirestorePaths(user.uid);
      final profileSnap = await firestore.doc(paths.profileDoc).get();
      final hasProfile = profileSnap.data() != null;

      if (!hasProfile && !onOnboarding) return '/onboarding';
      if (hasProfile && onOnboarding) return '/today';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/today',
            builder: (context, state) => const TodayScreen(),
          ),
          GoRoute(
            path: '/nutrition',
            builder: (context, state) => const NutritionScreen(),
          ),
          GoRoute(
            path: '/progress',
            builder: (context, state) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (context, state) => const MoreScreen(),
            routes: [
              GoRoute(
                path: 'routine',
                builder: (context, state) => const RoutineScreen(),
              ),
              GoRoute(
                path: 'health',
                builder: (context, state) => const HealthScreen(),
              ),
              GoRoute(
                path: 'settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'edit-profile',
                    builder: (context, state) =>
                        EditProfileScreen(profile: state.extra! as UserProfile),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
