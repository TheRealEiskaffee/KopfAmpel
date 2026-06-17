import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/app_localizations.dart';
import 'notification_bootstrapper.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: NotificationBootstrapper(child: navigationShell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: [
          NavigationDestination(
            icon: const Icon(CupertinoIcons.calendar),
            selectedIcon: const Icon(CupertinoIcons.calendar_today),
            label: l10n.navCalendar,
          ),
          NavigationDestination(
            icon: const Icon(CupertinoIcons.chart_bar),
            selectedIcon: const Icon(CupertinoIcons.chart_bar_fill),
            label: l10n.navStats,
          ),
          NavigationDestination(
            icon: const Icon(CupertinoIcons.settings),
            selectedIcon: const Icon(CupertinoIcons.settings_solid),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
