import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'LogIn/firebase_options.dart';
import 'LogIn/login.dart';
import 'SharedPreferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Save server URL
  await saveBaseUrl('https://b768-84-242-56-27.ngrok-free.app');
  final baseUrl = await getBaseUrl();
  debugPrint('Base URL saved: $baseUrl');

  // 3. Initialize Notifications
  await _initializeAwesomeNotifications();

  // 4. Schedule Daily Notifications
  await _scheduleDailyNotifications();

  runApp(const MyApp());
}

// ==================== Notification Functions ====================
Future<void> _initializeAwesomeNotifications() async {
  await AwesomeNotifications().initialize(
    null, // Default app icon
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Channel for scheduled notifications',
        importance: NotificationImportance.High,
        defaultColor: Colors.blue,
        ledColor: Colors.white,
        playSound: true,
      )
    ],
  );

  // Request permission (for iOS)
  await AwesomeNotifications().requestPermissionToSendNotifications();
}

Future<void> _scheduleDailyNotifications() async {
  // Clear any existing scheduled notifications
  await AwesomeNotifications().cancelAllSchedules();

  // Notification schedule data
  final notifications = <Map<String, dynamic>>[
    {
      'id': 1001,
      'title': 'صباح الخير',
      'body': 'حان وقت بدء يومك بنشاط!',
      'hour': 8,
      'minute': 0,
    },
    {
      'id': 1002,
      'title': 'تذكير الغداء',
      'body': 'لا تنسى تناول غداء صحي',
      'hour': 13,
      'minute': 30,
    },
    {
      'id': 1003,
      'title': 'وقت الراحة',
      'body': 'خذ قسطاً من الراحة، لقد عملت بجد اليوم',
      'hour': 16,
      'minute': 0,
    },
  ];

  // Schedule each notification
  for (final notification in notifications) {
    await _createScheduledNotification(
      id: notification['id'] as int,
      title: notification['title'] as String,
      body: notification['body'] as String,
      hour: notification['hour'] as int,
      minute: notification['minute'] as int,
    );
  }
}

Future<void> _createScheduledNotification({
  required int id,
  required String title,
  required String body,
  required int hour,
  required int minute,
}) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: id,
      channelKey: 'basic_channel',
      title: title,
      body: body,
    ),
    schedule: NotificationCalendar(
      hour: hour,
      minute: minute,
      second: 0,
      millisecond: 0,
      repeats: true, // Repeat daily
    ),
  );
}

// ==================== Main App Widget ====================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق الإشعارات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
    );
  }
}