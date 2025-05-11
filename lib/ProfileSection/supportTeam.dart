import 'dart:async';
import 'package:flutter/material.dart';
import 'package:FlawlessYou/ProfileSection/profile.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Admin/AdminProfileSectio/adminprofile.dart';
import '../SharedPreferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportTeam extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Support Team',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SupportTeamScreen(),
    );
  }
}

class SupportTeamScreen extends StatefulWidget {
  @override
  _SupportTeamScreenState createState() => _SupportTeamScreenState();
}

class _SupportTeamScreenState extends State<SupportTeamScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentIndex = 0;
  late Timer _timer;
  String? _token;
  Map<String, dynamic> _userInfo = {};
  bool _isAdmin = false;

  final List<Map<String, dynamic>> cards = [
    {
      'image': 'https://res.cloudinary.com/davwgirjs/image/upload/v1740417703/nhndev/product/320aee5f-ac8b-48be-94c7-e9296259cf99_1740417704566_mai1.jpg.jpg',
      'name': 'Mai Maliha',
      'role': 'Software Engineer',
      'email': 'maimaliha8@gmail.com',
    },
    {
      'image': 'https://res.cloudinary.com/davwgirjs/image/upload/v1740417791/nhndev/product/320aee5f-ac8b-48be-94c7-e9296259cf99_1740417792239_fatma.jpg.jpg',
      'name': 'Fatma Qunnies',
      'role': 'Software Engineer',
      'email': 'fatima.n.qunnies@gmail.com',
    },
    {
      'image': 'https://res.cloudinary.com/davwgirjs/image/upload/v1742386384/nhndev/product/dacbcfa8-1768-4c1e-8a7d-736c4e20b0c6_1742386381784_celinapic.jpg.jpg',
      'name': 'Celina Nassif',
      'role': 'Software Engineer',
      'email': 'celinanassif0@gmail.com',
    },
    {
      'name': 'About Our Team',
      'role': 'Meet the creators of Skin Project',
      'description': "Mai Maliha, Fatma Qunnies, and Celina Nassif.\n\nUnited by a passion for innovation, we designed this app to provide personalized skincare solutions using advanced technology.\n\nOur goal is to make expert skincare advice accessible, empowering users to achieve healthier, more confident skin.",
      'email': 'SupportT_flawlessyou@gmail.com',
      'phone': '+970 59 999 001 1\n02-27747741'
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _startAutoScroll();
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

  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 6), (timer) {
      if (_pageController.hasClients) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % cards.length;
        });
        _pageController.animateToPage(
          _currentIndex,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _navigateToProfile() async {
    if (_token == null || _userInfo.isEmpty) {
      await _loadUserInfo();
    }

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

  void _launchEmail(String email) async {
    final Uri gmailUri = Uri(
      scheme: 'https',
      host: 'mail.google.com',
      path: '/mail/u/0/',
      queryParameters: {
        'view': 'cm',
        'fs': '1',
        'to': email,
        'su': 'Support Request from Flawless You App',
        'body': 'Dear Support Team,\n\n',
      },
    );

    final Uri fallbackUri = Uri(scheme: 'mailto', path: email);

    try {
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch email app')),
        );
      }
    } catch (e) {
      print('Error launching email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while trying to open email')),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPortrait = constraints.maxHeight > constraints.maxWidth;
        final isTablet = constraints.maxWidth > 600;
        final cardWidth = isTablet ? constraints.maxWidth * 0.6 : constraints.maxWidth * 0.85;
        final cardHeight = isTablet ? constraints.maxHeight * (isPortrait ? 0.55 : 0.7) : constraints.maxHeight * (isPortrait ? 0.6 : 0.8);

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
                  "Support Team",
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Stack(
                  children: [
                    Image.network(
                      'https://res.cloudinary.com/davwgirjs/image/upload/v1740417948/nhndev/product/320aee5f-ac8b-48be-94c7-e9296259cf99_1740417948735_supbg.jpg.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.error, color: Colors.white),
                      ),
                    ),
                    Container(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              Center(
                child: SizedBox(
                  height: cardHeight,
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.horizontal,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Center(
                          child: Container(
                            width: cardWidth,
                            child: Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              color: Colors.white.withOpacity(0.6),
                              child: Padding(
                                padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (card['image'] != null && index != 3) ...[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: Image.network(
                                            card['image'],
                                            height: constraints.maxHeight / 3,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) => Center(
                                              child: Icon(Icons.person, size: 100, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: isTablet ? 20 : 15),
                                      ],
                                      Text(
                                        card['name'],
                                        style: TextStyle(
                                          fontSize: isTablet ? 26 : 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF596D56),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: isTablet ? 12 : 10),
                                      Text(
                                        card['role'],
                                        style: TextStyle(
                                          fontSize: isTablet ? 20 : 18,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: isTablet ? 12 : 10),
                                      if (card['description'] != null)
                                        Text(
                                          card['description'],
                                          style: TextStyle(
                                            fontSize: isTablet ? 18 : 16,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      SizedBox(height: isTablet ? 12 : 10),
                                      if (card['email'] != null)
                                        GestureDetector(
                                          onTap: () => _launchEmail(card['email']),
                                          child: Text(
                                            card['email'],
                                            style: TextStyle(
                                              fontSize: isTablet ? 18 : 16,
                                              color: Color(0xFF596D56),
                                              decoration: TextDecoration.underline,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
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
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}