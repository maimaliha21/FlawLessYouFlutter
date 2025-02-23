import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../LogIn/login.dart';
import '../../Product/product.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({Key? key}) : super(key: key);

  @override
  _AdminProfileState createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> with SingleTickerProviderStateMixin {
  String? token;
  Map<String, dynamic>? userInfo;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
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

  void _logout() async {
    await clearUserData();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _showEditPopup() {
    print(userInfo!['role'] +'ADMIN'+'hhhhhhhhhh');
    if (userInfo != null && userInfo!['role'] == 'ADMIN') {
      print(userInfo!['role'] +'ADMIN');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Edit Product'),
            content: Text('You are an ADMIN. You can edit this product.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  // هنا يمكنك إضافة منطق التعديل
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Product updated successfully!')),
                  );
                },
                child: Text('Save'),
              ),
            ],
          );
        },
      );
    } else {
      print(userInfo!['role'] +'ADMIN'+'this is else');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You do not have permission to edit.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          if (userInfo != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Welcome, ${userInfo!['name'] ?? 'Admin'}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Email: ${userInfo!['email'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  if (userInfo!['role'] == 'ADMIN')
                    ElevatedButton(
                      onPressed: _showEditPopup,
                      child: Text('Edit Product'),
                    ),
                ],
              ),
            ),
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Saved'),
              Tab(text: 'History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ProductTabScreen(
                  apiUrl: "http://localhost:8080/product/Saved",
                ),
                const Center(
                  child: Text('No history available',
                      style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}