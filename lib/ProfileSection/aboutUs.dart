import 'dart:async';
import 'package:flutter/material.dart';
import 'package:FlawlessYou/ProfileSection/profile.dart';
import '../Admin/AdminProfileSectio/adminprofile.dart';
import '../SharedPreferences.dart';

class aboutUs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'About Us',
        theme: ThemeData(
        primarySwatch: MaterialColor(
        0xFF596D56, {
        50: Color(0xFFE2E7D8),
        100: Color(0xFFB5C2A5),
        200: Color(0xFF8A9D72),
        300: Color(0xFF5F7840),
        400: Color(0xFF436C2E),
        500: Color(0xFF2F6023),
        600: Color(0xFF275220),
        700: Color(0xFF1F4420),
        800: Color(0xFF17362D),
        900: Color(0xFF0E2B1B),
        },
    ),
    ),
    home: CardScreen(),
    );
  }
}

class CardScreen extends StatefulWidget {
  @override
  _CardScreenState createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentIndex = 0;
  String? _token;
  Map<String, dynamic> _userInfo = {};
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userData = await getUserData();
      if (userData != null) {
        setState(() {
          _token = userData['token'];
          _userInfo = userData['userInfo'];
          _isAdmin = _userInfo['role']?.toString().toUpperCase() == 'ADMIN';
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  void _navigateToProfile() {
    if (_token == null || _userInfo.isEmpty) {
      // إذا لم يتم تحميل بيانات المستخدم بعد، نعيد تحميلها
      _loadUserInfo().then((_) {
        _redirectToProfile();
      });
    } else {
      _redirectToProfile();
    }
  }

  void _redirectToProfile() {
    if (_isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminProfile(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Profile(token: _token!, userInfo: _userInfo),
        ),
      );
    }
  }

  final List<Map<String, dynamic>> cards = [
    {
      'title': 'Our Vision',
      'content': 'We aim to simplify absence management and provide personalized solutions to everyone.',
      'points': [
        '✔ Simplified absence tracking',
        '✔ AI-driven personalization',
        '✔ Secure and efficient solutions',
      ],
    },
    {
      'title': 'What We Do',
      'content': 'We use cutting-edge AI technology to analyze and assist users with smart solutions.',
      'points': [
        '✔ AI-driven insights',
        '✔ Data security ensured',
        '✔ User-friendly interfaces',
      ],
    },
    {
      'title': 'Why Choose Us',
      'content': 'We offer the best solutions through technology and innovation.',
      'points': [
        '✔ Reliable and accurate',
        '✔ Trusted by professionals',
        '✔ Personalized recommendations',
      ],
    },
    {
      'title': 'Who We Help',
      'content': 'We support individuals and businesses seeking reliable absence tracking solutions.',
      'points': [
        '✔ Students and educators',
        '✔ Businesses and employees',
        '✔ Personal use and families',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 26),
              onPressed: _navigateToProfile,
            ),
            SizedBox(width: 8),
            Text(
              "About Us",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // الخلفية
              Positioned.fill(
                child: Stack(
                  children: [
                    Image.network(
                      "https://res.cloudinary.com/davwgirjs/image/upload/v1740423125/nhndev/product/320aee5f-ac8b-48be-94c7-e9296259cf99_1740423126526_aboutusbg.jpg.jpg",
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Container(
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ],
                ),
              ),

              // بطاقات المعلومات
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  double scale = _currentIndex == index ? 1.0 : 0.85;
                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 300),
                    tween: Tween<double>(begin: scale, end: scale),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: constraints.maxHeight * 0.02,
                          ),
                          child: Center(
                            child: Container(
                              height: constraints.maxHeight * 0.65,
                              width: constraints.maxWidth * 0.85,
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                color: Colors.white.withOpacity(0.9),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                    constraints.maxWidth * 0.05,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Text(
                                          cards[index]['title']!,
                                          style: TextStyle(
                                            fontSize: constraints.maxWidth * 0.06,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF596D56),
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: constraints.maxHeight * 0.02),
                                      Text(
                                        cards[index]['content']!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: constraints.maxWidth * 0.045,
                                          color: Colors.black,
                                          height: 1.4,
                                        ),
                                      ),
                                      SizedBox(height: constraints.maxHeight * 0.02),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: cards[index]['points']!.map<Widget>((point) {
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: constraints.maxHeight * 0.01,
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    point,
                                                    style: TextStyle(
                                                      fontSize: constraints.maxWidth * 0.04,
                                                      color: Color(0xFF596D56),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}