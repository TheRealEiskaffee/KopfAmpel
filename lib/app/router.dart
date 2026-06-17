import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/database/database_providers.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../widgets/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// Riverpod-cached GoRouter so we only build it once per ProviderScope.
final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(ref);
  ref.onDispose(router.dispose);
  return router;
});

/// Builds the app's GoRouter. The router is built inside a [Ref] so it can
/// react to changes on [settingsProvider]: when `onboardingComplete` flips,
/// the redirect re-runs and the user lands on the right screen.
GoRouter buildRouter(Ref ref) {
  // ValueNotifier that GoRouter listens on. Every time settingsProvider emits
  // a new AppSettingsRow we bump it, which causes the router to re-evaluate
  // its `redirect` closure.
  final refreshSignal = ValueNotifier<int>(0);
  ref.onDispose(refreshSignal.dispose);

  ref.listen(settingsProvider, (_, _) {
    refreshSignal.value++;
  }, fireImmediately: true);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/calendar',
    refreshListenable: refreshSignal,
    redirect: (context, state) {
      final settingsAsync = ref.read(settingsProvider);
      // Until we know the settings row, leave the user where they are. Showing
      // /calendar (the default) while we wait avoids a flash of onboarding for
      // returning users.
      final settings = settingsAsync.valueOrNull;
      if (settings == null) return null;

      final goingToOnboarding = state.matchedLocation == '/onboarding';
      if (!settings.onboardingComplete) {
        return goingToOnboarding ? null : '/onboarding';
      }
      // Onboarding is done — bounce away from /onboarding if they somehow end
      // up there (e.g. via deep link).
      if (goingToOnboarding) return '/calendar';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, _) => const NoTransitionPage(
          child: OnboardingScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(
                path: '/calendar',
                pageBuilder: (_, _) => const NoTransitionPage(
                  child: CalendarScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                pageBuilder: (_, _) => const NoTransitionPage(
                  child: StatsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (_, _) => const NoTransitionPage(
                  child: SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
