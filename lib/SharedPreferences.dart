import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveUserData(String token, Map<String, dynamic> userInfo) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token); // حفظ التوكن
  await prefs.setString('userInfo', jsonEncode(userInfo)); // حفظ معلومات المستخدم كـ JSON
}