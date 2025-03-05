import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'LogIn/firebase_options.dart';
import 'LogIn/login.dart';
import 'SharedPreferences.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await saveBaseUrl('http://localhost:8080');

  // طباعة الرابط للتأكد من حفظه
  final baseUrl = await getBaseUrl();
  print('Base URL saved: $baseUrl');

  runApp(MyApp());
}