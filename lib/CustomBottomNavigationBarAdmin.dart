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
import 'Treatment/treatment.dart';

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0.0, size.height - 20);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30.0);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint =
    Offset(size.width - (size.width / 3.25), size.height - 65);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, size.height - 40);
    path.lineTo(size.width, 0.0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class CustomBottomNavigationBarAdmin extends StatefulWidget {
  const CustomBottomNavigationBarAdmin({super.key});

  @override
  _CustomBottomNavigationBarAdminState createState() =>
      _CustomBottomNavigationBarAdminState();
}

class _CustomBottomNavigationBarAdminState extends State<CustomBottomNavigationBarAdmin> {
  String? token;
  Map<String, dynamic>? userInfo;
  int _selectedIndex = 3 ; // Track the selected index

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

  // Method to get icon color based on selected index
  Color _getIconColor(int index) {
    return _selectedIndex == index ? Color(0xFF4A6F4A) : Color(0xFF88A383);
  }

  // Method to get icon size based on selected index
  double _getIconSize(int index) {
    return _selectedIndex == index ? 30 : 24;
  }

  // Method to handle navigation
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Home(token: token!),
          ),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>  TreatmentPage(),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(token: token!, userInfo: userInfo!),
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminProfile(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (token == null || userInfo == null) {
      return Center(child: CircularProgressIndicator()); // Show loading indicator
    }

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
            backgroundColor: Color(0xFF4A6F4A), // Changed to the new color
            onPressed: () {
              FaceAnalysisManager(
                context: context,
                token: token!,
                userInfo: userInfo!,
              ).analyzeFace();
            },
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
                  icon: Icon(Icons.home, color: _getIconColor(0)),
                  onPressed: () => _onItemTapped(0),
                ),
                IconButton(
                  icon: Icon(Icons.medical_services, color: _getIconColor(1)),
                  onPressed: () => _onItemTapped(1),
                ),
                const SizedBox(width: 60), // Space for FAB
                IconButton(
                  icon: Icon(Icons.shopping_bag, color: _getIconColor(2)),
                  onPressed: () => _onItemTapped(2),
                ),
                IconButton(
                  icon: Icon(Icons.person, color: _getIconColor(3)),
                  onPressed: () => _onItemTapped(3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}