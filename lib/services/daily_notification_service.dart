import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DailyNotificationService {
  DailyNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _launchCountKey = 'daily_notification_launch_count';
  static const String _enabledKey = 'daily_notification_enabled';
  static const int _firstNotificationId = 7000;
  static const int _scheduleDays = 14;

  static const List<String> _promoMessages = [
    'Your arcade is ready. Play one quick round today.',
    'A new high score could be waiting for you today.',
    'Tap in for a quick brain game and keep your streak alive.',
    'Kids learning games and arcade fun are ready to play.',
    'Try one lucky game today and see what you land on.',
    'Your next favorite mini-game is waiting inside XOX Arcade.',
  ];

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
  }

  static Future<void> registerAppLaunch() async {
    if (kIsWeb) return;

    final prefs = await SharedPreferences.getInstance();
    final launchCount = (prefs.getInt(_launchCountKey) ?? 0) + 1;
    await prefs.setInt(_launchCountKey, launchCount);

    final enabled = prefs.getBool(_enabledKey) ?? true;
    if (!enabled || launchCount < 2) {
      return;
    }

    final granted = await _requestPermissions();
    if (!granted) {
      return;
    }

    await _scheduleUpcomingNotifications();
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (!enabled) {
      await cancelAll();
      return;
    }
    await _scheduleUpcomingNotifications();
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<bool> _requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted =
        await androidPlugin?.requestNotificationsPermission() ?? true;

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted =
        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    final macPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final macGranted =
        await macPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    return androidGranted && iosGranted && macGranted;
  }

  static Future<void> _scheduleUpcomingNotifications() async {
    await _cancelScheduledRange();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_arcade_reminders',
        'Daily Arcade Reminders',
        channelDescription: 'Daily reminders to come back and play.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    for (var index = 0; index < _scheduleDays; index++) {
      final scheduleDate = _nextReminderTime(now, dayOffset: index);
      final message = _promoMessages[scheduleDate.day % _promoMessages.length];
      await _plugin.zonedSchedule(
        _firstNotificationId + index,
        'XOX Arcade',
        message,
        scheduleDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  static tz.TZDateTime _nextReminderTime(
    tz.TZDateTime now, {
    required int dayOffset,
  }) {
    final baseDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 18);
    final nextDate = baseDate.isAfter(now)
        ? baseDate
        : baseDate.add(const Duration(days: 1));
    return nextDate.add(Duration(days: dayOffset));
  }

  static Future<void> _cancelScheduledRange() async {
    for (var index = 0; index < _scheduleDays; index++) {
      await _plugin.cancel(_firstNotificationId + index);
    }
  }
}
