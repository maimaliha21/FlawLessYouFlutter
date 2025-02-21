import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:projtry1/ProfileSection/editProfile.dart';
import 'profile.dart';  // تأكد من استيراد الصفحة الجديدة هنا

void main() {
  runApp(aboutUs());
}

class aboutUs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'About Us',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 26), // السهم
              onPressed: () {
                // Navigator.push(
                //                 //   context,
                //                 //   MaterialPageRoute(builder: (context) => editProfile()), // الانتقال لصفحة Profile
                //                 // );
              },
            ),
            SizedBox(width: 8), // مسافة صغيرة بين السهم والنص
            Text(
              "About Us",
              style: TextStyle(
                fontSize: 20, // خط أصغر
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // **الخلفية كصورة مع تأثير شفاف**
          Positioned.fill(
            child: Stack(
              children: [
                Image.asset(
                  'assets/aboutusbg.jpg', // تأكد من وضع الصورة في مجلد assets
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Container(
                  color: Colors.black.withOpacity(0.4), // طبقة شفافة لجعل النص واضحًا
                ),
              ],
            ),
          ),

          // **بطاقات المعلومات مع التمرير العمودي**
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical, // حركة الشرائح من أعلى لأسفل
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
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Center(
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.55, // جعل الشرائح أقل ارتفاعًا
                          width: MediaQuery.of(context).size.width * 0.85,
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            color: Colors.white.withOpacity(0.9), // جعل البطاقة شفافة قليلًا
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      cards[index]['title']!,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    cards[index]['content']!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.blue.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: cards[index]['points']!.map<Widget>((point) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.blue.shade600, size: 20),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                point,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.blue.shade900,
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
      ),
    );
  }
}
