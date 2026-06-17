import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/notification_providers.dart';

/// Drives the notification lifecycle from the app's UI: initialises the
/// plugin once, then refreshes the schedule every time the app comes back
/// to foreground. Sits inside MaterialApp so localisations are available.
class NotificationBootstrapper extends ConsumerStatefulWidget {
  const NotificationBootstrapper({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationBootstrapper> createState() => _NotificationBootstrapperState();
}

class _NotificationBootstrapperState extends ConsumerState<NotificationBootstrapper>
    with WidgetsBindingObserver {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final strings = notificationStringsOf(context);
    final service = ref.read(notificationServiceProvider);
    await service.init(strings: strings);
    await service.requestPermissions();
    await ref.read(notificationSchedulerProvider).rescheduleHorizon(strings: strings);
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final strings = notificationStringsOf(context);
    final scheduler = ref.read(notificationSchedulerProvider);
    await scheduler.recoverOpenPrompts(strings: strings);
    await scheduler.rescheduleHorizon(strings: strings);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
