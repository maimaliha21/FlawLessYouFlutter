import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'LogIn/firebase_options.dart';
import 'LogIn/login.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    ),
  );
}