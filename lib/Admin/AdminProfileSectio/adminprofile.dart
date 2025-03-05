import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../Card/Card.dart';
import '../../Home_Section/home.dart';
import '../../LogIn/login.dart';
import '../../Product/product.dart';
import '../../Product/productPage.dart';
import '../../Routinebar/routinescreen.dart';
import '../../ProfileSection/editProfile.dart';
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

  // دالة لاسترجاع الرابط من SharedPreferences
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You do not have permission to edit.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 250,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/bgphoto.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 30,
                  right: 20,
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
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                Positioned(
                  top: 150,
                  left: MediaQuery.of(context).size.width / 2 - 75,
                  child: CircleAvatar(
                    radius: 75,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 65,
                        backgroundImage: NetworkImage(userInfo?['profilePicture'] ?? 'assets/profile.jpg'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            Text(
              userInfo?['userName'] ?? 'Admin',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            Text(
              userInfo?['email'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (userInfo?['skinType'] != null) ...[
              const SizedBox(height: 5),
              Text(
                'Skin Type: ${userInfo?['skinType']}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 20),
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Edit profile'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserFilterPage(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('manage Routine'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Saved'),
              ],
            ),
            FutureBuilder<String>(
              future: getBaseUrl(), // استرجاع الرابط من SharedPreferences
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final baseUrl = snapshot.data!;
                  return Container(
                    height: 300,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ProductTabScreen(
                          apiUrl: '$baseUrl/product/Saved',
                        ),
                        const Center(
                          child: Text('No history available',
                              style: TextStyle(color: Colors.black)),
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
      bottomNavigationBar: CustomBottomNavigationBar(
        token: token ?? '',
        userInfo: userInfo ?? {},
      ),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final String token;
  final Map<String, dynamic> userInfo;

  const CustomBottomNavigationBar({
    super.key,
    required this.token,
    required this.userInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: BottomWaveClipper(),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 25,
          left: MediaQuery.of(context).size.width / 2 - 30,
          child: FloatingActionButton(
            backgroundColor: Colors.blue,
            onPressed: () {},
            child: const Icon(Icons.face, color: Colors.white),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Home(token: token),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessageCard(token: token),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 60),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductPage(token: token, userInfo: userInfo),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.blue),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(size.width / 4, size.height, size.width / 2,
        size.height - 20);
    path.quadraticBezierTo(size.width * 3 / 4, size.height - 40, size.width,
        size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}