import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_providers.dart';
import '../core/i18n/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class KopfAmpelApp extends ConsumerWidget {
  const KopfAmpelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settingsAsync = ref.watch(settingsProvider);

    final locale = settingsAsync.maybeWhen(
      data: (s) => s.locale == null ? null : Locale(s.locale!),
      orElse: () => null,
    );
    final themeMode = settingsAsync.maybeWhen(
      data: (s) => switch (s.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      orElse: () => ThemeMode.system,
    );

    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Tap anywhere outside an input field to dismiss the soft keyboard.
      // GestureDetector with no explicit behavior defers to children, so
      // buttons and text fields still receive their own taps.
      builder: (context, child) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
    );
  }
}
