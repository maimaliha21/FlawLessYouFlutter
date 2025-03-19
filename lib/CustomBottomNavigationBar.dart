import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Admin/AdminProfileSectio/adminprofile.dart';
import 'Card/Card.dart';
import 'FaceAnalysisManager.dart';
import 'Home_Section/home.dart';
import 'Product/productPage.dart';
import 'ProfileSection/profile.dart';

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0.0, size.height - 15);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 25.0);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint =
    Offset(size.width - (size.width / 3.25), size.height - 55);
    var secondEndPoint = Offset(size.width, size.height - 30);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, size.height - 30);
    path.lineTo(size.width, 0.0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class CustomBottomNavigationBar2 extends StatefulWidget {
  const CustomBottomNavigationBar2({super.key});

  @override
  _CustomBottomNavigationBar2State createState() =>
      _CustomBottomNavigationBar2State();
}

class _CustomBottomNavigationBar2State
    extends State<CustomBottomNavigationBar2> {
  String? token;
  Map<String, dynamic>? userInfo;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? storedToken = prefs.getString('token');
      String? userInfoJson = prefs.getString('userInfo');

      if (storedToken != null && userInfoJson != null) {
        setState(() {
          token = storedToken;
          userInfo = jsonDecode(userInfoJson);
        });
      } else {
        print('No user data found');
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }


  Color _getIconColor(int index) {
    return index == _selectedIndex
        ? const Color(0xFF4A6F4A) // لون غامق عندما تكون الأيقونة نشطة
        : const Color(0xFFB0C0A8); // لون فاتح عندما تكون الأيقونة غير نشطة
  }

  double _getIconSize(int index) {
    return index == _selectedIndex ? 30.0 : 24.0; // زيادة حجم الأيقونة عندما تكون نشطة
  }

  @override
  Widget build(BuildContext context) {
    if (token == null || userInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: BottomWaveClipper(),
          child: Container(
            height: 65,
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8), // خلفية موحدة بلون هادئ
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: MediaQuery.of(context).size.width / 2 - 28,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF88A383),
            onPressed: () {
              FaceAnalysisManager(
                context: context,
                token: token!,
                userInfo: userInfo!,
              ).analyzeFace();
            },
            child: const Icon(Icons.face, color: Colors.white),
            mini: true,
            elevation: 4,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.home,
                    color: _getIconColor(0),
                    size: _getIconSize(0),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Home(token: token!),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.chat,
                    color: _getIconColor(1),
                    size: _getIconSize(1),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessageCard(token: token!),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 56),
                IconButton(
                  icon: Icon(
                    Icons.shopping_bag,
                    color: _getIconColor(2),
                    size: _getIconSize(2),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductPage(token: token!, userInfo: userInfo!),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.person,
                    color: _getIconColor(3),
                    size: _getIconSize(3),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 3;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Profile(token: token!, userInfo: userInfo!),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}