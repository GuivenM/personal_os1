import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/schedule_block_model.dart';

/// Schedules a local notification 5 minutes before each of today's blocks
/// (spec section 18): title = block name, body = `HH:MM – HH:MM`.
///
/// Notifications are cancelled and re-scheduled every time
/// [scheduleForBlocks] is called — on app launch and whenever a fresh
/// dashboard/schedule load happens — rather than via a true midnight
/// background trigger. A real midnight trigger needs a background-isolate
/// scheduler (e.g. `android_alarm_manager_plus` / `workmanager`), which is
/// a meaningfully bigger addition (extra native setup, a background entry
/// point, battery-optimization edge cases); happy to add it if this
/// "refresh on open" approximation isn't good enough in practice.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    try {
      // This is a personal, single-user app whose backend is fixed to
      // Africa/Porto-Novo (UTC+1, no DST — see the spec's server timezone
      // note), so there's no need for a native plugin to detect the
      // device's timezone dynamically. Hardcoding it also avoids a class
      // of Gradle/Kotlin-toolchain build issues those plugins tend to
      // bring in. If you ever use the app while traveling and want
      // reminders to follow local device time instead, say so and I'll
      // swap this for dynamic detection.
      tz.setLocalLocation(tz.getLocation('Africa/Porto-Novo'));
    } catch (_) {
      // Fall back to whatever the `timezone` package defaults to (UTC)
      // rather than crashing if that zone name is ever unavailable.
    }

    // A dedicated flat white silhouette, not the full-color launcher
    // icon — Android composites status-bar/notification icons itself
    // (tinting them with the color below), and feeding it a multi-color
    // icon is what was causing the boxed 'card' fallback look instead of
    // a clean icon like other apps show.
    const androidSettings = AndroidInitializationSettings('ic_stat_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    // Needed on Android 12+ for exact-time scheduling (block reminders
    // need to fire close to the actual minute, not "sometime in the next
    // 15 minutes"). No-op / auto-granted on older Android like this
    // device's.
    await android?.requestExactAlarmsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Cancels every previously scheduled block reminder, then schedules a
  /// new one 5 minutes before each of [blocks]' start time — skipping any
  /// block whose reminder time has already passed today.
  Future<void> scheduleForBlocks(List<ScheduleBlock> blocks) async {
    if (!_initialized) await init();
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);

    for (final block in blocks) {
      final start = _parseTime(block.timeStart);
      if (start == null) continue;

      final reminderTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        start.$1,
        start.$2,
      ).subtract(const Duration(minutes: 5));

      if (reminderTime.isBefore(now)) continue;

      final end = _parseTime(block.timeEnd) ?? start;

      await _plugin.zonedSchedule(
        block.blockId,
        block.name,
        '${_format(start)} – ${_format(end)}',
        reminderTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'block_reminders',
            'Block reminders',
            channelDescription: 'Reminds you 5 minutes before each scheduled block starts.',
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFF6C5CE7),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Fires an immediate notification — useful to verify permissions and
  /// the notification channel are working without waiting for a real
  /// block reminder.
  Future<void> showTestNotification() async {
    if (!_initialized) await init();
    await _plugin.show(
      999999,
      'Test notification',
      'If you can see this, notifications are working.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'block_reminders',
          'Block reminders',
          channelDescription: 'Reminds you 5 minutes before each scheduled block starts.',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF6C5CE7),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Returns (hour, minute) parsed from a "HH:MM" or "HH:MM:SS" string.
  (int, int)? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (h, m);
  }

  String _format((int, int) time) {
    return '${time.$1.toString().padLeft(2, '0')}:${time.$2.toString().padLeft(2, '0')}';
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});        
