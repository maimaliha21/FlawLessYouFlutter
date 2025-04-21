import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleDailyNotifications() async {
    await _scheduleMorningNotification();
    await _scheduleAfternoonNotification();
    await _scheduleEveningNotification();
  }

  Future<void> _scheduleMorningNotification() async {
    await _notificationsPlugin.zonedSchedule(
      0,
      'حان وقت روتين الصباح!',
      'هيا لنكمل روتين العناية بالبشرة معاً ☀️',
      _nextTimeOfDay(const TimeOfDay(hour: 8, minute: 0)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'morning_routine_channel',
          'Morning Routine',
          channelDescription: 'Notifications for morning skincare routine',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleAfternoonNotification() async {
    await _notificationsPlugin.zonedSchedule(
      1,
      'حان وقت روتين الظهر!',
      'لا تنسى العناية ببشرتك في منتصف النهار 🌤️',
      _nextTimeOfDay(const TimeOfDay(hour: 12, minute: 0)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'afternoon_routine_channel',
          'Afternoon Routine',
          channelDescription: 'Notifications for afternoon skincare routine',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleEveningNotification() async {
    await _notificationsPlugin.zonedSchedule(
      2,
      'حان وقت روتين المساء!',
      'لننهي يومنا بروتين عناية ليلية 🌙',
      _nextTimeOfDay(const TimeOfDay(hour: 20, minute: 0)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'evening_routine_channel',
          'Evening Routine',
          channelDescription: 'Notifications for evening skincare routine',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextTimeOfDay(TimeOfDay timeOfDay) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}