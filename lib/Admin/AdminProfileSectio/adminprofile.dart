import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../Card/Card.dart';
import '../../CustomBottomNavigationBarAdmin.dart';
import '../../Home_Section/home.dart';
import '../../LogIn/login.dart';
import '../../Product/product.dart';
import '../../Product/productPage.dart';
import '../../Routinebar/routinescreen.dart';
import '../../ProfileSection/editProfile.dart';
import '../../Treatment/treatment.dart';
import 'editRole.dart';

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

  Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('baseUrl') ?? '';
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
    if (userInfo != null && userInfo!['role'] == 'ADMIN') {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You do not have permission to edit.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.shortestSide > 600;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: isTablet ? screenHeight * 0.3 : screenHeight * 0.25,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          'https://res.cloudinary.com/davwgirjs/image/upload/v1740417378/nhndev/product/320aee5f-ac8b-48be-94c7-e9296259cf99_1740417378981_bgphoto.jpg.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: isTablet ? 50 : 30,
                  right: isTablet ? 40 : 20,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout') _logout();
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'support',
                        child: Text('Support'),
                      ),
                      const PopupMenuItem(
                        value: 'about_us',
                        child: Text('About Us'),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Text('Log Out'),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: isTablet ? 35 : 30,
                    ),
                  ),
                ),
                Positioned(
                  top: isTablet ? 180 : 150,
                  left: screenWidth / 2 - (isTablet ? 90 : 75),
                  child: CircleAvatar(
                    radius: isTablet ? 90 : 75,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: isTablet ? 85 : 70,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: isTablet ? 80 : 65,
                        backgroundImage: NetworkImage(userInfo?['profilePicture'] ?? 'assets/profile.jpg'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 110 : 90),
            Text(
              userInfo?['userName'] ?? 'Admin',
              style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            SizedBox(height: 5),
            Text(
              userInfo?['email'] ?? '',
              style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  color: Colors.grey),
            ),
            if (userInfo?['skinType'] != null) ...[
              SizedBox(height: 5),
              Text(
                'Skin Type: ${userInfo?['skinType']}',
                style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey),
              ),
            ],
            SizedBox(height: isTablet ? 30 : 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfile(token: token!),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF88A383),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 50 : 37,
                        vertical: isTablet ? 15 : 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Edit profile',
                    style: TextStyle(fontSize: isTablet ? 18 : 16),
                  ),
                ),
                SizedBox(width: isTablet ? 20 : 10),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserFilterPage(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF88A383),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 50 : 37,
                        vertical: isTablet ? 15 : 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'manage Role',
                    style: TextStyle(fontSize: isTablet ? 18 : 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 30 : 20),
            SizedBox(
              width: isTablet ? screenWidth * 0.8 : screenWidth,
              child: TabBar(
                controller: _tabController,
                labelColor: Color(0xFF88A383),
                indicatorColor: Color(0xFF88A383),
                indicatorWeight: 3.0,
                unselectedLabelColor: Colors.grey,
                labelStyle: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: 'Saved'),
                ],
              ),
            ),
            FutureBuilder<String>(
              future: getBaseUrl(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final baseUrl = snapshot.data!;
                  return Container(
                    height: isTablet ? screenHeight * 0.5 : screenHeight * 0.4,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ProductTabScreen(
                          apiUrl: '$baseUrl/product/Saved',
                          pageName: 'home',
                        ),
                        Center(
                          child: Text('No history available',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: isTablet ? 18 : 16,
                              )),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBarAdmin(),
    );
  }
}