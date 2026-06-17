import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/ampel_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../settings/application/settings_actions.dart';

/// First-launch onboarding flow. Three pages:
///   1) welcome
///   2) ask for notification permission
///   3) pick reminder window + finish
///
/// When the user finishes (or skips), `onboardingComplete` is flipped to
/// `true`, which causes the router's redirect to send them on to /calendar.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _pageCount = 3;

  final PageController _controller = PageController();
  int _index = 0;

  // Reminder window state for the third page. Defaults match the Drift table
  // (18:00 – 22:00).
  int _startMinutes = 18 * 60;
  int _endMinutes = 22 * 60;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish({required bool requestNotificationPermission}) async {
    final actions = ref.read(settingsActionsProvider);
    if (requestNotificationPermission) {
      // Fire and forget — we never want the system dialog to block onboarding.
      await ref.read(notificationServiceProvider).requestPermissions();
    }
    await actions.setWindow(startMinutes: _startMinutes, endMinutes: _endMinutes);
    await actions.setOnboardingComplete(true);
    if (!mounted) return;
    // Belt-and-braces: explicitly navigate to /calendar so that even routers
    // configured without a redirect still leave the onboarding screen.
    GoRouter.of(context).go('/calendar');
  }

  Future<void> _skipAll() async {
    await ref.read(settingsActionsProvider).setOnboardingComplete(true);
    if (!mounted) return;
    GoRouter.of(context).go('/calendar');
  }

  void _onWindowChanged({required int start, required int end}) {
    setState(() {
      _startMinutes = start;
      _endMinutes = end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLastPage = _index == _pageCount - 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isLastPage)
            TextButton(
              onPressed: _skipAll,
              child: Text(l10n.onboardingSkip),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _WelcomePage(
                    onContinue: () => _goToPage(1),
                  ),
                  _PermissionsPage(
                    onAllow: () async {
                      await ref
                          .read(notificationServiceProvider)
                          .requestPermissions();
                      if (!mounted) return;
                      _goToPage(2);
                    },
                    onLater: () => _goToPage(2),
                  ),
                  _TimePage(
                    startMinutes: _startMinutes,
                    endMinutes: _endMinutes,
                    onChanged: _onWindowChanged,
                    onFinish: () => _finish(requestNotificationPermission: false),
                  ),
                ],
              ),
            ),
            _PageIndicator(count: _pageCount, index: _index),
            const SizedBox(height: 16),
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
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.25),
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
                const SizedBox(height: 32),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              if (extra != null) ...[
                const SizedBox(height: 24),
                extra!,
              ],
              const SizedBox(height: 32),
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
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onContinue});

  final VoidCallback onContinue;

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

class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage({required this.onAllow, required this.onLater});

  final Future<void> Function() onAllow;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _OnboardingPage(
      icon: Icon(
        Icons.notifications_active_outlined,
        size: 72,
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

class _TimePage extends StatelessWidget {
  const _TimePage({
    required this.startMinutes,
    required this.endMinutes,
    required this.onChanged,
    required this.onFinish,
  });

  final int startMinutes;
  final int endMinutes;
  final void Function({required int start, required int end}) onChanged;
  final VoidCallback onFinish;

  TimeOfDay _asTime(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);
  int _asMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String _format(BuildContext context, int minutes) {
    final mat = MaterialLocalizations.of(context);
    return mat.formatTimeOfDay(_asTime(minutes), alwaysUse24HourFormat: true);
  }

  Future<void> _pickStart(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _asTime(startMinutes),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final start = _asMinutes(picked);
    onChanged(start: start, end: start >= endMinutes ? start + 60 : endMinutes);
  }

  Future<void> _pickEnd(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _asTime(endMinutes),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final end = _asMinutes(picked);
    onChanged(start: end <= startMinutes ? end - 60 : startMinutes, end: end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return _OnboardingPage(
      icon: Icon(
        Icons.schedule,
        size: 72,
        color: theme.colorScheme.primary,
      ),
      title: l10n.onboardingTimeTitle,
      body: l10n.onboardingTimeBody,
      extra: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickStart(context),
              icon: const Icon(Icons.schedule),
              label: Text(
                '${l10n.reminderWindowFrom} ${_format(context, startMinutes)}',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickEnd(context),
              icon: const Icon(Icons.schedule_outlined),
              label: Text(
                '${l10n.reminderWindowTo} ${_format(context, endMinutes)}',
              ),
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: onFinish,
          child: Text(l10n.onboardingFinish),
        ),
      ],
    );
  }
}
