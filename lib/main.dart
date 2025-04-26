import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'LogIn/firebase_options.dart';
import 'LogIn/login.dart';
import 'SharedPreferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone
  tz.initializeTimeZones();
  final timeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
  tz.setLocalLocation(tz.getLocation(timeZone));

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Save server URL
  await saveBaseUrl('https://b768-84-242-56-27.ngrok-free.app');

  // Initialize Notifications
  await _initializeNotificationSystem();

  // Schedule Notifications
  await _scheduleAllNotifications();

  runApp(const MyApp());
}

Future<void> _initializeNotificationSystem() async {
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'skin_care_channel',
        channelName: 'Skin Care Reminders',
        channelDescription: 'Channel for skin care notifications',
        importance: NotificationImportance.High,
        defaultColor: Colors.blue,
        ledColor: Colors.white,
        playSound: true,
        enableVibration: true,
      ),
      NotificationChannel(
        channelKey: 'water_reminder_channel',
        channelName: 'Water Reminders',
        channelDescription: 'Channel for water drinking reminders',
        importance: NotificationImportance.Default,
        defaultColor: Colors.lightBlue,
        ledColor: Colors.blue,
        playSound: true,
      ),
    ],
  );

  await AwesomeNotifications().requestPermissionToSendNotifications();
}

Future<void> _scheduleAllNotifications() async {
  await AwesomeNotifications().cancelAllSchedules();

  // Morning Routine - 6 AM
  await _scheduleDailyNotification(
    id: 1001,
    title: 'Let\'s start our day with healthy skin!',
    body: 'Time for morning skincare routine: Cleansing + Moisturizing + Sunscreen',
    hour: 6,
    minute: 0,
  );

  // Afternoon Reminder - 2 PM
  await _scheduleDailyNotification(
    id: 1002,
    title: 'Afternoon Skincare Reminder',
    body: 'Don\'t forget to reapply your sunscreen!',
    hour: 14,
    minute: 0,
  );

  // Evening Routine - 7 PM
  await _scheduleDailyNotification(
    id: 1003,
    title: 'Evening Skincare Time',
    body: 'Time to remove makeup and cleanse your face thoroughly',
    hour: 19,
    minute: 0,
  );

  // Water Reminders - Every 2 hours from 8 AM to 10 PM
  for (int hour = 8; hour <= 22; hour += 2) {
    await _scheduleDailyNotification(
      id: 2000 + hour,
      title: 'Water Reminder 💧',
      body: 'Time to drink a glass of water to stay hydrated',
      hour: hour,
      minute: 0,
      channelKey: 'water_reminder_channel',
    );
  }

  // Sunscreen Reapplication - Every 3 hours from 9 AM to 6 PM
  for (int hour = 9; hour <= 18; hour += 3) {
    await _scheduleDailyNotification(
      id: 3000 + hour,
      title: 'Sunscreen Reapplication 🌞',
      body: 'Don\'t forget to reapply your sunscreen for protection',
      hour: hour,
      minute: 0,
    );
  }
}

Future<void> _scheduleDailyNotification({
  required int id,
  required String title,
  required String body,
  required int hour,
  int minute = 0,
  String channelKey = 'skin_care_channel',
}) async {
  final timeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
  final now = tz.TZDateTime.now(tz.getLocation(timeZone));

  var scheduledTime = tz.TZDateTime(
    tz.getLocation(timeZone),
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );

  if (scheduledTime.isBefore(now)) {
    scheduledTime = scheduledTime.add(const Duration(days: 1));
  }

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: id,
      channelKey: channelKey,
      title: title,
      body: body,
    ),
    schedule: NotificationCalendar(
      timeZone: timeZone,
      hour: scheduledTime.hour,
      minute: scheduledTime.minute,
      second: 0,
      repeats: true,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin Care App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
    );
  }
}