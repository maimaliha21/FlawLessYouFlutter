import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'Home_Section/notification_service.dart';
import 'LogIn/firebase_options.dart';
import 'LogIn/login.dart';
import 'SharedPreferences.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // طباعة الرابط للتأكد من حفظه
  final baseUrl = await getBaseUrl();
  print('Base URL saved: $baseUrl');
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.scheduleDailyNotifications();
  runApp(MyApp());
}