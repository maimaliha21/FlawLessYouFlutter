import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// حفظ بيانات المستخدم
Future<void> saveUserData(String token, Map<String, dynamic> userInfo) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token); // حفظ التوكن
  await prefs.setString('userInfo', jsonEncode(userInfo)); // حفظ معلومات المستخدم كـ JSON


}

// استرجاع بيانات المستخدم
Future<Map<String, dynamic>?> getUserData() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userInfoJson = prefs.getString('userInfo');

    if (token != null && userInfoJson != null) {
      Map<String, dynamic> userInfo = jsonDecode(userInfoJson);
      return {'token': token, 'userInfo': userInfo};
    } else {
      print('No user data found');
      return null;
    }
  } catch (e) {
    print('Error retrieving user data: $e');
    throw Exception('Failed to retrieve user data');
  }
}

// حذف بيانات المستخدم
Future<void> clearUserData() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userInfo');
    print('User data cleared successfully');
  } catch (e) {
    print('Error clearing user data: $e');
    throw Exception('Failed to clear user data');
  }
}

// التحقق من وجود بيانات مستخدم
Future<bool> hasUserData() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token') && prefs.containsKey('userInfo');
  } catch (e) {
    print('Error checking user data: $e');
    throw Exception('Failed to check user data');
  }
}

// حفظ الرابط
Future<void> saveBaseUrl(String baseUrl) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseUrl', 'http://localhost:8080'); // حفظ الرابط
        print('Base URL saved successfully: $baseUrl');
  } catch (e) {
    print('Error saving base URL: $e');

    throw Exception('Failed to save base URL');
  }
}


// استرجاع الرابط
Future<String> getBaseUrl() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString('baseUrl');
    if (url == null || url.isEmpty) {
      throw Exception('Base URL not found');
    }
    return url;
  } catch (e) {
    print('Error getting base URL: $e');
    throw Exception('Failed to get base URL');
  }
}