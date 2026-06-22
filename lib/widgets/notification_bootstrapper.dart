import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/database/converters.dart';
import '../core/notifications/notification_navigation.dart';
import '../core/notifications/notification_providers.dart';
import '../features/calendar/application/calendar_providers.dart';

/// Drives the notification lifecycle from the app's UI: initialises the
/// plugin once, then refreshes the schedule every time the app comes back
/// to foreground. Also routes a notification *body* tap to that day's entry
/// sheet. Sits inside MaterialApp so localisations are available.
class NotificationBootstrapper extends ConsumerStatefulWidget {
  const NotificationBootstrapper({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationBootstrapper> createState() => _NotificationBootstrapperState();
}

class _NotificationBootstrapperState extends ConsumerState<NotificationBootstrapper>
    with WidgetsBindingObserver {
  bool _initialized = false;
  StreamSubscription<DateTime>? _tapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Notification body taps while the app is running.
    _tapSub = notificationTapStream.listen(_openDay);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Switches to the calendar and asks it to open the given day's entry sheet.
  void _openDay(DateTime day) {
    if (!mounted) return;
    GoRouter.of(context).go('/calendar');
    ref.read(pendingNotificationDayProvider.notifier).state = dayKey(day);
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final strings = notificationStringsOf(context);
    final service = ref.read(notificationServiceProvider);
    await service.init(strings: strings);
    // Don't request permission silently on every app launch — onboarding's
    // explicit "Erlauben" button is the only place that asks. Otherwise iOS
    // shows the system dialog at the wrong moment (or not at all, since the
    // request only triggers once per install).
    await ref.read(notificationSchedulerProvider).rescheduleHorizon(strings: strings);

    // Cold-launched by tapping a notification body? Open that day's sheet.
    final launchDay = await service.notificationLaunchDay();
    if (launchDay != null && mounted) _openDay(launchDay);
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final strings = notificationStringsOf(context);
    final scheduler = ref.read(notificationSchedulerProvider);
    await scheduler.rescheduleHorizon(strings: strings);

    // A severity tapped from a notification is written by the background
    // isolate through its own DB connection, so this already-running app
    // instance gets no change notification and its cached entry queries stay
    // stale (the day sheet shows "no entry" until a restart). Re-read entry
    // data on every resume so such entries appear immediately.
    if (!mounted) return;
    ref.invalidate(entryByDayProvider);
    ref.invalidate(monthSeverityProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
