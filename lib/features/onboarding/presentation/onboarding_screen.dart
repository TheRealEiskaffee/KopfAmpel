import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/theme/ampel_colors.dart';
import '../../../core/domain/tag_kind.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../widgets/cupertino_time_sheet.dart';
import '../../export/application/export_providers.dart';
import '../../export/application/export_service.dart';
import '../../settings/application/settings_actions.dart';
import '../../settings/presentation/tag_management_screen.dart';

/// First-launch setup wizard. Pages:
///   0 welcome
///   1 path choice — import existing backup, or start fresh
///   2 language + theme   (skipped on import)
///   3 notification permission   (skipped on import)
///   4 reminder window + repeat toggle   (skipped on import)
///   5 triggers & medications shortcuts   (skipped on import)
///   6 done
///
/// On finish (or import success) `onboardingComplete` flips to true, which
/// makes the router send the user on to /calendar.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Pages: welcome, choice, appearance, permissions, reminder, tags, done.
  static const int _pageCount = 7;
  static const int _idxWelcome = 0;
  static const int _idxDone = 6;

  final PageController _controller = PageController();
  int _index = 0;
  bool _busy = false;

  int _startMinutes = 18 * 60;
  int _endMinutes = 22 * 60;
  String? _localeCode;
  String _themeMode = 'system';
  bool _repeatEnabled = true;
  bool _notificationsGranted = false;
  bool _imported = false;
  int _importedCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goTo(int page) async {
    await _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _next() async {
    if (_index >= _pageCount - 1) return;
    await _goTo(_index + 1);
  }

  Future<void> _back() async {
    if (_index <= 0) return;
    await _goTo(_index - 1);
  }

  Future<void> _runImport() async {
    final l10n = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _busy = true);
    try {
      final file = File(result.files.single.path!);
      final import =
          await ref.read(exportServiceProvider).importJson(file, ImportMode.merge);
      if (!mounted) return;
      setState(() {
        _imported = true;
        _importedCount = import.entriesAdded;
      });
      await _goTo(_idxDone);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.importFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveAppearance() async {
    final actions = ref.read(settingsActionsProvider);
    await actions.setLocale(_localeCode);
    await actions.setThemeMode(_themeMode);
  }

  Future<void> _saveReminder() async {
    final actions = ref.read(settingsActionsProvider);
    await actions.setWindow(startMinutes: _startMinutes, endMinutes: _endMinutes);
    await actions.setRepeatEnabled(_repeatEnabled);
  }

  Future<void> _finish() async {
    await ref.read(settingsActionsProvider).setOnboardingComplete(true);
    if (!mounted) return;
    GoRouter.of(context).go('/calendar');
  }

  Future<void> _skipAll() async {
    await ref.read(settingsActionsProvider).setOnboardingComplete(true);
    if (!mounted) return;
    GoRouter.of(context).go('/calendar');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSkip = _index != _idxDone && _index != _idxWelcome;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _index > 0 && !_busy
            ? IconButton(
                icon: const Icon(CupertinoIcons.back),
                onPressed: _back,
                tooltip: l10n.onboardingBack,
              )
            : null,
        actions: [
          if (canSkip && !_busy)
            TextButton(
              onPressed: _skipAll,
              child: Text(l10n.onboardingSkip),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _index = i),
                    children: [
                      _WelcomePage(onContinue: _next),
                      _ChoicePage(
                        onImport: _runImport,
                        onFresh: _next,
                      ),
                      _AppearancePage(
                        localeCode: _localeCode,
                        themeMode: _themeMode,
                        onLocale: (v) => setState(() => _localeCode = v),
                        onTheme: (v) => setState(() => _themeMode = v),
                        onContinue: () async {
                          await _saveAppearance();
                          await _next();
                        },
                      ),
                      _PermissionsPage(
                        onAllow: () async {
                          final granted = await ref
                              .read(notificationServiceProvider)
                              .requestPermissions();
                          if (!mounted) return;
                          setState(() => _notificationsGranted = granted);
                          await _next();
                        },
                        onLater: _next,
                      ),
                      _ReminderPage(
                        startMinutes: _startMinutes,
                        endMinutes: _endMinutes,
                        repeatEnabled: _repeatEnabled,
                        disabled: !_notificationsGranted,
                        onWindow: (start, end) {
                          setState(() {
                            _startMinutes = start;
                            _endMinutes = end;
                          });
                        },
                        onRepeat: (v) => setState(() => _repeatEnabled = v),
                        onContinue: () async {
                          await _saveReminder();
                          await _next();
                        },
                      ),
                      _TagsPage(onContinue: _next),
                      _DonePage(
                        imported: _imported,
                        importedCount: _importedCount,
                        onStart: _finish,
                      ),
                    ],
                  ),
                ),
                _PageIndicator(count: _pageCount, index: _index),
                const SizedBox(height: 16),
              ],
            ),
            if (_busy)
              Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(l10n.onboardingImportRunning),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.body,
    this.icon,
    required this.actions,
    this.extra,
  });

  final String title;
  final String body;
  final Widget? icon;
  final List<Widget> actions;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Center(child: icon!),
                const SizedBox(height: 28),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              if (extra != null) ...[
                const SizedBox(height: 24),
                extra!,
              ],
              const SizedBox(height: 28),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _AmpelMark extends StatelessWidget {
  const _AmpelMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _Dot(color: AmpelColors.green),
          SizedBox(width: 10),
          _Dot(color: AmpelColors.yellow),
          SizedBox(width: 10),
          _Dot(color: AmpelColors.red),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// --- Pages ----------------------------------------------------------------

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onContinue});
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _OnboardingPage(
      icon: const _AmpelMark(),
      title: l10n.onboardingWelcomeTitle,
      body: l10n.onboardingWelcomeBody,
      actions: [
        FilledButton(
          onPressed: onContinue,
          child: Text(l10n.onboardingContinue),
        ),
      ],
    );
  }
}

class _ChoicePage extends StatelessWidget {
  const _ChoicePage({required this.onImport, required this.onFresh});
  final Future<void> Function() onImport;
  final Future<void> Function() onFresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _OnboardingPage(
      title: l10n.onboardingChoiceTitle,
      body: l10n.onboardingChoiceBody,
      actions: [
        _ChoiceCard(
          icon: CupertinoIcons.arrow_down_doc,
          title: l10n.onboardingChoiceImport,
          subtitle: l10n.onboardingChoiceImportDescription,
          onTap: onImport,
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          icon: CupertinoIcons.sparkles,
          title: l10n.onboardingChoiceFresh,
          subtitle: l10n.onboardingChoiceFreshDescription,
          onTap: onFresh,
          accent: true,
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: accent ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 36,
                color: accent ? scheme.onPrimaryContainer : scheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppearancePage extends StatelessWidget {
  const _AppearancePage({
    required this.localeCode,
    required this.themeMode,
    required this.onLocale,
    required this.onTheme,
    required this.onContinue,
  });

  final String? localeCode;
  final String themeMode;
  final ValueChanged<String?> onLocale;
  final ValueChanged<String> onTheme;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _OnboardingPage(
      icon: Icon(
        CupertinoIcons.paintbrush,
        size: 64,
        color: theme.colorScheme.primary,
      ),
      title: l10n.onboardingAppearanceTitle,
      body: l10n.onboardingAppearanceBody,
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.language, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: localeCode ?? 'system',
              children: {
                'system': Text(l10n.languageSystem),
                'de': Text(l10n.languageDe),
                'en': Text(l10n.languageEn),
              },
              onValueChanged: (v) {
                if (v == null) return;
                onLocale(v == 'system' ? null : v);
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.themeMode, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: themeMode,
              children: {
                'system': Text(l10n.themeSystem),
                'light': Text(l10n.themeLight),
                'dark': Text(l10n.themeDark),
              },
              onValueChanged: (v) {
                if (v != null) onTheme(v);
              },
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: onContinue,
          child: Text(l10n.onboardingContinue),
        ),
      ],
    );
  }
}

class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage({required this.onAllow, required this.onLater});
  final Future<void> Function() onAllow;
  final Future<void> Function() onLater;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _OnboardingPage(
      icon: Icon(
        CupertinoIcons.bell,
        size: 64,
        color: theme.colorScheme.primary,
      ),
      title: l10n.onboardingPermissionsTitle,
      body: l10n.onboardingPermissionsBody,
      extra: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          l10n.onboardingPermissionsLaterNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: onAllow,
          child: Text(l10n.onboardingAllow),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onLater,
          child: Text(l10n.onboardingLater),
        ),
      ],
    );
  }
}

class _ReminderPage extends StatelessWidget {
  const _ReminderPage({
    required this.startMinutes,
    required this.endMinutes,
    required this.repeatEnabled,
    required this.disabled,
    required this.onWindow,
    required this.onRepeat,
    required this.onContinue,
  });

  final int startMinutes;
  final int endMinutes;
  final bool repeatEnabled;
  final bool disabled;
  final void Function(int start, int end) onWindow;
  final ValueChanged<bool> onRepeat;
  final Future<void> Function() onContinue;

  TimeOfDay _asTime(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);
  int _asMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String _format(BuildContext context, int minutes) {
    final mat = MaterialLocalizations.of(context);
    return mat.formatTimeOfDay(_asTime(minutes), alwaysUse24HourFormat: true);
  }

  Future<void> _pickStart(BuildContext context) async {
    final picked = await showCupertinoTimeSheet(
      context,
      initialTime: _asTime(startMinutes),
    );
    if (picked == null) return;
    final start = _asMinutes(picked);
    onWindow(start, start >= endMinutes ? start + 60 : endMinutes);
  }

  Future<void> _pickEnd(BuildContext context) async {
    final picked = await showCupertinoTimeSheet(
      context,
      initialTime: _asTime(endMinutes),
    );
    if (picked == null) return;
    final end = _asMinutes(picked);
    onWindow(end <= startMinutes ? end - 60 : startMinutes, end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _OnboardingPage(
      icon: Icon(
        CupertinoIcons.time,
        size: 64,
        color: theme.colorScheme.primary,
      ),
      title: l10n.onboardingReminderTitle,
      body: l10n.onboardingReminderBody,
      extra: Column(
        children: [
          if (disabled) ...[
            _DisabledNotice(
              text: l10n.onboardingReminderDisabled,
              openSettingsLabel: l10n.openSystemSettings,
            ),
            const SizedBox(height: 16),
          ],
          IgnorePointer(
            ignoring: disabled,
            child: Opacity(
              opacity: disabled ? 0.4 : 1,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickStart(context),
                          icon: const Icon(CupertinoIcons.time, size: 18),
                          label: Text(
                            '${l10n.reminderWindowFrom} ${_format(context, startMinutes)}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickEnd(context),
                          icon: const Icon(CupertinoIcons.time, size: 18),
                          label: Text(
                            '${l10n.reminderWindowTo} ${_format(context, endMinutes)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: SwitchListTile.adaptive(
                      title: Text(l10n.onboardingRepeatLabel),
                      subtitle: Text(l10n.reminderRepeatsDescription),
                      value: repeatEnabled,
                      onChanged: onRepeat,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: onContinue,
          child: Text(l10n.onboardingContinue),
        ),
      ],
    );
  }
}

class _DisabledNotice extends StatelessWidget {
  const _DisabledNotice({
    required this.text,
    required this.openSettingsLabel,
  });

  final String text;
  final String openSettingsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.bell_slash,
                size: 18,
                color: scheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: openAppSettings,
              child: Text(openSettingsLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagsPage extends ConsumerWidget {
  const _TagsPage({required this.onContinue});
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _OnboardingPage(
      icon: Icon(
        CupertinoIcons.tag,
        size: 64,
        color: theme.colorScheme.primary,
      ),
      title: l10n.onboardingTagsTitle,
      body: l10n.onboardingTagsBody,
      extra: Column(
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => const TagManagementScreen(kind: TagKind.trigger),
              ),
            ),
            icon: const Icon(CupertinoIcons.tag, size: 18),
            label: Text(l10n.onboardingTagsManageTriggers),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => const TagManagementScreen(kind: TagKind.medication),
              ),
            ),
            icon: const Icon(CupertinoIcons.bandage, size: 18),
            label: Text(l10n.onboardingTagsManageMedications),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: onContinue,
          child: Text(l10n.onboardingContinue),
        ),
      ],
    );
  }
}

class _DonePage extends StatelessWidget {
  const _DonePage({
    required this.imported,
    required this.importedCount,
    required this.onStart,
  });

  final bool imported;
  final int importedCount;
  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _OnboardingPage(
      icon: Icon(
        CupertinoIcons.checkmark_seal_fill,
        size: 64,
        color: theme.colorScheme.primary,
      ),
      title: l10n.onboardingDoneTitle,
      body: imported
          ? l10n.onboardingDoneImportedBody(importedCount)
          : l10n.onboardingDoneBody,
      actions: [
        FilledButton(
          onPressed: onStart,
          child: Text(l10n.onboardingStart),
        ),
      ],
    );
  }
}
