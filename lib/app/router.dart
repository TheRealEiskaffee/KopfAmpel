import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/calendar/presentation/calendar_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../widgets/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/calendar',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
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
