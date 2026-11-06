import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A daily notification such as "Did you log today's spending?".
/// Works on Android phones. On Chrome it is switched off.
class ReminderService extends ChangeNotifier {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const _enabledKey = 'reminder_enabled';
  static const _hourKey = 'reminder_hour';
  static const _minuteKey = 'reminder_minute';
  static const _notificationId = 1;

  final _plugin = FlutterLocalNotificationsPlugin();

  /// This device can show reminders (Android phone).
  bool supported = false;

  /// The user turned the reminder on.
  bool enabled = false;

  /// What time of day it fires.
  TimeOfDay time = const TimeOfDay(hour: 20, minute: 0);

  Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      supported = false;
      return;
    }
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      supported = true;

      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_enabledKey) ?? false;
      time = TimeOfDay(
        hour: prefs.getInt(_hourKey) ?? 20,
        minute: prefs.getInt(_minuteKey) ?? 0,
      );

      // Schedule again on every start. This also fixes the time if the
      // phone's time zone changed.
      if (enabled) await _schedule();
    } catch (e) {
      debugPrint('Reminder init error: $e');
      supported = false;
      enabled = false;
    }
    notifyListeners();
  }

  Future<void> _schedule() async {
    final now = DateTime.now();
    var when = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'ClearCash',
      body: "Did you log today's spending?",
      scheduledDate: tz.TZDateTime.from(when, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminder',
          channelDescription: 'A daily nudge to log your spending',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeats every day
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    await prefs.setInt(_hourKey, time.hour);
    await prefs.setInt(_minuteKey, time.minute);
  }

  /// Turns the reminder on. Asks for notification permission first.
  Future<bool> enable(TimeOfDay at) async {
    if (!supported) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission() ?? false;
      if (!granted) return false;

      time = at;
      enabled = true;
      await _save();
      await _schedule();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Reminder enable error: $e');
      return false;
    }
  }

  /// Changes the time (and re-schedules if the reminder is on).
  Future<void> changeTime(TimeOfDay at) async {
    time = at;
    await _save();
    if (enabled) await _schedule();
    notifyListeners();
  }

  Future<void> disable() async {
    try {
      await _plugin.cancel(id: _notificationId);
    } catch (e) {
      debugPrint('Reminder cancel error: $e');
    }
    enabled = false;
    await _save();
    notifyListeners();
  }
}
