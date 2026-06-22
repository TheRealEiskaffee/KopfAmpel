import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // UIScene-migrated apps must set the notification-center delegate
    // explicitly: unlike the legacy lifecycle, FlutterAppDelegate no longer
    // wires this up, so notification responses (taps on action buttons) would
    // never reach the plugin and the tapped severity would never be logged.
    // This is the canonical setup from the flutter_local_notifications example.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Required for apps migrated to the UIScene lifecycle (per the
    // flutter_local_notifications README). When a notification action button
    // (without the `foreground` option) is tapped while the app is
    // backgrounded/terminated, the plugin spins up a dedicated background
    // FlutterEngine to run the Dart handler. That engine needs its plugins
    // registered via this callback — otherwise the background isolate never
    // starts and `onDidReceiveBackgroundNotificationResponse` never runs, so a
    // tapped severity is silently never written.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
