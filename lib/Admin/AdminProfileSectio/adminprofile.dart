import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../LogIn/login.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({Key? key}) : super(key: key);

  @override
  _AdminProfileState createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  String? token;
  Map<String, dynamic>? userInfo;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await loadUserData();
      setState(() {
        token = userData['token'];
        userInfo = userData['userInfo'];
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<Map<String, dynamic>> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userInfoString = prefs.getString('userInfo');

    if (token != null && userInfoString != null) {
      Map<String, dynamic> userInfo = jsonDecode(userInfoString);
      return {'token': token, 'userInfo': userInfo};
    } else {
      throw Exception('No user data found');
    }
  }

  Future<void> clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userInfo');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Admin',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Token: ${token ?? "No Token"}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'User Info: ${userInfo?.toString() ?? "No User Info"}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                await clearUserData();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}