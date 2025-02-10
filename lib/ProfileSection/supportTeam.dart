import 'dart:async';
import 'package:flutter/material.dart';
import 'package:projtry1/ProfileSection/editProfile.dart';
import 'profile.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(supportTeam());
}

class supportTeam extends StatelessWidget {
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

  final List<Map<String, dynamic>> cards = [
    {
      'image': 'assets/mai1.jpg',
      'name': 'Mai Maliha',
      'role': 'Software Engineer',
      'email': 'maimaliha8@gmail.com',
    },
    {
      'image': 'assets/fatma.jpg',
      'name': 'Fatma Qunnies',
      'role': 'Software Engineer',
      'email': 'fatima.n.qunnies@gmail.com',
    },
    {
      'image': 'assets/celina.jpg',
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
    _timer = Timer.periodic(Duration(seconds: 6), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % cards.length;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => editProfile()),
                );
              },
            ),
            SizedBox(width: 8),
            Text(
              "Support Team",
              style: TextStyle(
                fontSize: 20,
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
                Image.asset(
                  'assets/supbg.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Container(
                  color: Colors.black.withOpacity(0.5), // Adjust opacity here
                ),
              ],
            ),
          ),
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Center(
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    width: MediaQuery.of(context).size.width * 0.85,
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      color: Colors.white.withOpacity(0.6),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (cards[index]['image'] != null && index != 3) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.asset(
                                    cards[index]['image'],
                                    height: 300,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(height: 15),
                              ],
                              Text(
                                cards[index]['name'],
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                cards[index]['role'],
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              if (cards[index]['description'] != null)
                                Text(
                                  cards[index]['description'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              SizedBox(height: 10),
                              if (cards[index]['email'] != null)
                                GestureDetector(
                                  onTap: () => _launchEmail(cards[index]['email']),
                                  child: Text(
                                    cards[index]['email'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF0D1698),
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
        ],
      ),
    );
  }
}
