import 'package:flutter/foundation.dart';

/// No-op notification service.
///
/// Local notifications were removed because no `flutter_local_notifications`
/// version is compatible with the project's Flutter 3.19 / Dart 3.3 toolchain
/// (v17+ needs Flutter 3.22+, and v16 fails to compile against compileSdk 34).
///
/// The API surface is kept intact so the rest of the app (reminders stored on
/// a task, BLoC scheduling calls) continues to compile and run. Reminder times
/// are still persisted with each task — only the OS-level scheduling is a no-op.
/// To re-enable real reminders, upgrade to Flutter 3.22+ and restore
/// `flutter_local_notifications`.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  Future<void> init() async {}

  Future<void> requestPermissions() async {
    debugPrint('NotificationService: reminders are disabled in this build.');
  }

  int notificationIdFor(String taskId) => taskId.hashCode & 0x7fffffff;

  Future<void> scheduleReminder({
    required String taskId,
    required String title,
    required String body,
    required DateTime time,
  }) async {
    // Intentionally a no-op. Reminder time is still saved with the task.
  }

  Future<void> cancelReminder(String taskId) async {
    // Intentionally a no-op.
  }
}
