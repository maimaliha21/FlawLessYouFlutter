import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'LogIn/firebase_options.dart';
import 'LogIn/login.dart';
import 'SharedPreferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة المناطق الزمنية بشكل صحيح
  tz.initializeTimeZones();
  final String timeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
  tz.setLocalLocation(tz.getLocation(timeZone));
  debugPrint('المنطقة الزمنية الحالية: $timeZone');

  await _setupPlatform();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await saveBaseUrl('https://b768-84-242-56-27.ngrok-free.app');

  await _initializeNotificationSystem();

  runApp(const MyApp());
}

Future<void> _setupPlatform() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

Future<void> _initializeNotificationSystem() async {
  try {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'skin_care_channel',
          channelName: 'Skin Care Reminders',
          channelDescription: 'Channel for skin care notifications',
          importance: NotificationImportance.Max,
          defaultColor: Colors.blue,
          ledColor: Colors.white,
          playSound: true,
          enableVibration: true,
          soundSource: 'resource://raw/notification_sound',
        ),
        NotificationChannel(
          channelKey: 'water_reminder_channel',
          channelName: 'Water Reminders',
          channelDescription: 'Channel for water drinking reminders',
          importance: NotificationImportance.High,
          defaultColor: Colors.lightBlue,
          ledColor: Colors.blue,
          playSound: true,
          enableVibration: true,
        ),
      ],
    );

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications(
        channelKey: 'skin_care_channel',
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
        ],
      );
    }

    // إرسال إشعار ترحيبي للتأكد من عمل النظام
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: -1,
        channelKey: 'skin_care_channel',
        title: 'تم تهيئة الإشعارات',
        body: 'سيتم إرسال الإشعارات في الأوقات المحددة',
      ),
    );

    await _scheduleAllNotifications();
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }
}

Future<void> _scheduleAllNotifications() async {
  try {
    await AwesomeNotifications().cancelAllSchedules();

    debugPrint('جارٍ جدولة الإشعارات...');

    // روتين الصباح الساعة 6 صباحاً
    await _scheduleDailyNotification(
      id: 1001,
      title: 'روتين الصباح ✨',
      body: 'وقت العناية ببشرتك! تنظيف + ترطيب + واقي شمس',
      hour: 6,
      minute: 0,
    );

    // تذكير الظهر الساعة 12 ظهراً
    await _scheduleDailyNotification(
      id: 1002,
      title: 'تذكير الظهيرة ☀️',
      body: 'جدد وضع واقي الشمس وحافظ على ترطيب بشرتك',
      hour: 12,
      minute: 0,
    );

    // روتين المساء الساعة 9 مساءً
    await _scheduleDailyNotification(
      id: 1003,
      title: 'روتين المساء 🌙',
      body: 'وقت إزالة المكياج وتنظيف البشرة بعمق',
      hour: 22,
      minute: 15,
    );

    // تذكير شرب المياه كل ساعتين من 8 صباحاً حتى 10 مساءً
    for (int hour = 8; hour <= 22; hour += 2) {
      await _scheduleDailyNotification(
        id: 2000 + hour,
        title: 'تذكير شرب المياه 💧',
        body: 'حان الوقت لشرب كوب من الماء لترطيب جسمك وبشرتك',
        hour: hour,
        minute: 0,
        channelKey: 'water_reminder_channel',
      );
    }

    // تذكير الواقي الشمسي كل 3 ساعات من 9 صباحاً حتى 6 مساءً
    for (int hour = 9; hour <= 18; hour += 3) {
      await _scheduleDailyNotification(
        id: 3000 + hour,
        title: 'تذكير الواقي الشمسي 🌞',
        body: 'حان الوقت لتجديد وضع واقي الشمس لحماية بشرتك',
        hour: hour,
        minute: 30,
      );
    }

    debugPrint('تم جدولة جميع الإشعارات بنجاح');
  } catch (e) {
    debugPrint('Error scheduling notifications: $e');
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
  try {
    final String timeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
    final tz.Location location = tz.getLocation(timeZone);
    final now = tz.TZDateTime.now(location);

    var scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint('''
    ===================================
    ⏰ جاري جدولة الإشعار:
    📌 العنوان: $title
    🕒 الوقت المحدد: ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}
    📅 التاريخ: ${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}
    🌍 المنطقة الزمنية: $timeZone
    ⏱ الوقت الحالي: ${now.hour}:${now.minute.toString().padLeft(2, '0')}
    ===================================
    ''');

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        title: title,
        body: body,
      ),
      schedule: NotificationCalendar(
        timeZone: timeZone,
        hour: scheduledDate.hour,
        minute: scheduledDate.minute,
        second: 0,
        repeats: true,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  } catch (e) {
    debugPrint('❌ خطأ في جدولة الإشعار: $e');
  }
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
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          elevation: 4,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentTime = '';
  String _notificationsInfo = 'جارٍ تحميل الإشعارات...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _updateCurrentTime();
    _loadScheduledNotifications();

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
    );
  }

  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    debugPrint('Notification action received: ${receivedAction.title}');
  }

  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    debugPrint('Notification created: ${receivedNotification.title}');
  }

  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    debugPrint('Notification displayed: ${receivedNotification.title}');
  }

  void _updateCurrentTime() {
    final now = tz.TZDateTime.now(tz.local);
    setState(() {
      _currentTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} - ${now.day}/${now.month}/${now.year}';
    });

    Future.delayed(const Duration(seconds: 1), _updateCurrentTime);
  }

  Future<void> _loadScheduledNotifications() async {
    setState(() => _isLoading = true);

    final now = tz.TZDateTime.now(tz.local);
    List<NotificationModel> scheduled =
    await AwesomeNotifications().listScheduledNotifications();

    if (scheduled.isEmpty) {
      setState(() {
        _notificationsInfo = 'لا توجد إشعارات مجدولة حالياً';
        _isLoading = false;
      });
      return;
    }

    StringBuffer infoBuffer = StringBuffer();
    infoBuffer.writeln('الإشعارات المجدولة (${scheduled.length}):');
    infoBuffer.writeln('------------------------');

    for (var notif in scheduled) {
      if (notif.content != null && notif.schedule is NotificationCalendar) {
        final calendar = notif.schedule as NotificationCalendar;
        final scheduledTime = tz.TZDateTime(
          tz.local,
          calendar.year ?? now.year,
          calendar.month ?? now.month,
          calendar.day ?? now.day,
          calendar.hour ?? 0,
          calendar.minute ?? 0,
        );

        final timeLeft = scheduledTime.difference(now);
        final hoursLeft = timeLeft.inHours;
        final minutesLeft = timeLeft.inMinutes.remainder(60);

        infoBuffer.writeln('⏰ ${notif.content?.title}');
        infoBuffer.writeln('📝 ${notif.content?.body}');
        infoBuffer.writeln('🕒 ${calendar.hour}:${calendar.minute.toString().padLeft(2, '0')}');
        infoBuffer.writeln('📌 القناة: ${notif.content?.channelKey}');
        infoBuffer.writeln('⏳ متبقي: $hoursLeft ساعة $minutesLeft دقيقة');
        infoBuffer.writeln('------------------------');
      }
    }

    setState(() {
      _notificationsInfo = infoBuffer.toString();
      _isLoading = false;
    });
  }

  Future<void> _testNotificationAfter1Minute() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(const Duration(minutes: 1));

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 999,
        channelKey: 'skin_care_channel',
        title: 'إشعار اختبار',
        body: 'هذا إشعار اختبار تم إرساله في ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}\nالوقت الحالي: ${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
      ),
      schedule: NotificationCalendar(
        timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
        year: scheduledTime.year,
        month: scheduledTime.month,
        day: scheduledTime.day,
        hour: scheduledTime.hour,
        minute: scheduledTime.minute,
        second: scheduledTime.second,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم جدولة إشعار اختبار بعد دقيقة في الساعة ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}'),
        duration: const Duration(seconds: 3),
      ),
    );

    await _loadScheduledNotifications();
  }

  Future<void> _checkCurrentTime() async {
    final String timeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
    final tz.Location location = tz.getLocation(timeZone);
    final now = tz.TZDateTime.now(location);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'الوقت الفعلي: ${now.hour}:${now.minute.toString().padLeft(2, '0')}\n'
              'المنطقة الزمنية: $timeZone',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام العناية بالبشرة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScheduledNotifications,
            tooltip: 'تحديث الإشعارات',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الوقت الحالي:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_currentTime,
                        style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('الإشعارات المجدولة:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                child: Text(_notificationsInfo),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _testNotificationAfter1Minute,
            tooltip: 'إشعار بعد دقيقة',
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer),
                Text('1 دقيقة', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _checkCurrentTime,
            tooltip: 'فحص الوقت',
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time),
                Text('فحص الوقت', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}