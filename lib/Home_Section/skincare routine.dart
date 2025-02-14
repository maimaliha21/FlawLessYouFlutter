// import 'package:flutter/material.dart';
// import 'package:projtry1/Home_Section/home.dart' as home;
//
// void main() {
// runApp(const SkincareRoutineApp());
// }
//
// class SkincareRoutineApp extends StatelessWidget {
// const SkincareRoutineApp({super.key});
//
// @override
// Widget build(BuildContext context) {
// return const MaterialApp(
// debugShowCheckedModeBanner: false,
// home: SkincareRoutineScreen(),
// );
// }
// }
//
// class SkincareRoutineScreen extends StatefulWidget {
// const SkincareRoutineScreen({super.key});
//
// @override
// _SkincareRoutineScreenState createState() => _SkincareRoutineScreenState();
// }
//
// class _SkincareRoutineScreenState extends State<SkincareRoutineScreen> {
// int _currentStep = 0;
//
// final List<Map<String, String>> _routines = [
// {'title': 'Cleanse your face', 'description': 'Use a gentle cleanser suitable for your skin type.'},
// {'title': 'Apply Toner', 'description': 'Use a hydrating or exfoliating toner based on your skin needs.'},
// {'title': 'Apply Serum', 'description': 'Use a serum to target specific skin concerns.'},
// {'title': 'Apply Eye Cream', 'description': 'Gently apply eye cream to reduce puffiness and dark circles.'},
// {'title': 'Apply Moisturizer', 'description': 'Use a moisturizer depending on your skin type.'},
// {'title': 'Apply Sunscreen', 'description': 'Protect your skin from UV rays with sunscreen.'},
// ];
//
// void _nextStep(BuildContext context) {
// setState(() {
// if (_currentStep < _routines.length - 1) {
// _currentStep++;
// } else {
// Navigator.pushReplacement(
// context,
// MaterialPageRoute(builder: (context) => home.HomeScreen()),
// );
// }
// });
// }
//
// @override
// Widget build(BuildContext context) {
// return Scaffold(
// extendBodyBehindAppBar: true,
// body: Stack(
// children: [
// Positioned.fill(
// child: Image.asset(
// 'assets/skincare.png',
// fit: BoxFit.cover,
// ),
// ),
// Container(
// decoration: BoxDecoration(
// gradient: LinearGradient(
// begin: Alignment.topCenter,
// end: Alignment.bottomCenter,
// colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
// ),
// ),
// ),
// Padding(
// padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 80),
// child: Column(
// mainAxisAlignment: MainAxisAlignment.end,
// children: [
// Text(
// 'Step ${_currentStep + 1}',
// style: const TextStyle(
// fontSize: 24,
// fontWeight: FontWeight.bold,
// color: Colors.white,
// fontStyle: FontStyle.italic,
// ),
// ),
// const SizedBox(height: 16),
// Text(
// _routines[_currentStep]['title']!,
// style: const TextStyle(
// fontSize: 24,
// fontWeight: FontWeight.bold,
// color: Colors.white,
// ),
// textAlign: TextAlign.center,
// ),
// const SizedBox(height: 16),
// Text(
// _routines[_currentStep]['description']!,
// style: const TextStyle(
// fontSize: 16,
// color: Colors.white70,
// ),
// textAlign: TextAlign.center,
// ),
// const SizedBox(height: 40),
// ElevatedButton(
// onPressed: () => _nextStep(context),
// style: ElevatedButton.styleFrom(
// backgroundColor: const Color(0xFF88A383),
// shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
// ),
// child: Text(
// _currentStep < _routines.length - 1 ? 'Next' : 'Finish',
// style: const TextStyle(fontSize: 18, color: Colors.white),
// ),
// ),
// const SizedBox(height: 80),
// ],
// ),
// ),
// ],
// ),
// bottomNavigationBar: const CustomBottomNavigationBar(),
// );
// }
// }
//
// class CustomBottomNavigationBar extends StatelessWidget {
// const CustomBottomNavigationBar({super.key});
//
// @override
// Widget build(BuildContext context) {
// return Stack(
// clipBehavior: Clip.none,
// children: [
// ClipPath(
// clipper: BottomWaveClipper(),
// child: Container(
// height: 70,
// decoration: const BoxDecoration(
// color: Color(0xFFC7C7BB),
// boxShadow: [
// BoxShadow(
// color: Colors.black26,
// blurRadius: 10,
// ),
// ],
// ),
// ),
// ),
// Positioned(
// bottom: 25,
// left: MediaQuery.of(context).size.width / 2 - 30,
// child: FloatingActionButton(
// backgroundColor: const Color(0xFF88A383),
// onPressed: () {},
// child: const Icon(Icons.face, color: Color(0xFF9EA684)),
// ),
// ),
// Positioned(
// bottom: 0,
// left: 0,
// right: 0,
// child: Container(
// height: 70,
// padding: const EdgeInsets.symmetric(horizontal: 16),
// child: Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: const [
// IconButton(
// icon: Icon(Icons.home, color: Color(0xFF88A383)),
// onPressed: null,
// ),
// IconButton(
// icon: Icon(Icons.chat, color: Color(0xFF88A383)),
// onPressed: null,
// ),
// SizedBox(width: 60), // لمنع التصادم مع الـ FloatingActionButton
// IconButton(
// icon: Icon(Icons.settings, color: Color(0xFF88A383)),
// onPressed: null,
// ),
// IconButton(
// icon: Icon(Icons.person, color: Color(0xFF88A383)),
// onPressed: null,
// ),
// ],
// ),
// ),
// ),
// ],
// );
// }
// }
//
// class BottomWaveClipper extends CustomClipper<Path> {
// @override
// Path getClip(Size size) {
// Path path = Path();
// path.lineTo(0, size.height);
// path.quadraticBezierTo(size.width / 2, size.height - 20, size.width, size.height);
// path.lineTo(size.width, 0);
// path.close();
// return path;
// }
//
// @override
// bool shouldReclip(CustomClipper<Path> oldClipper) => false;
// }
import 'package:flutter/material.dart';
import 'package:projtry1/Home_Section/home.dart' as home;

void main() {
  runApp(const SkincareRoutineApp());
}

class SkincareRoutineApp extends StatelessWidget {
  const SkincareRoutineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SkincareRoutineScreen(),
    );
  }
}

class SkincareRoutineScreen extends StatefulWidget {
  const SkincareRoutineScreen({super.key});

  @override
  _SkincareRoutineScreenState createState() => _SkincareRoutineScreenState();
}

class _SkincareRoutineScreenState extends State<SkincareRoutineScreen> {
  int _currentStep = 0;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _routines = [
    {'title': 'Cleanse your face', 'description': 'Use a gentle cleanser suitable for your skin type.'},
    {'title': 'Apply Toner', 'description': 'Use a hydrating or exfoliating toner based on your skin needs.'},
    {'title': 'Apply Serum', 'description': 'Use a serum to target specific skin concerns.'},
    {'title': 'Apply Eye Cream', 'description': 'Gently apply eye cream to reduce puffiness and dark circles.'},
    {'title': 'Apply Moisturizer', 'description': 'Use a moisturizer depending on your skin type.'},
    {'title': 'Apply Sunscreen', 'description': 'Protect your skin from UV rays with sunscreen.'},
  ];

  void _nextStep() {
    if (_currentStep < _routines.length - 1) {
      setState(() {
        _currentStep++;
      });

      // التمرير إلى العنصر التالي
      _scrollController.animateTo(
        _currentStep * 150.0, // ارتفاع العنصر تقريبي
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      // إذا انتهت الخطوات، انتقل إلى الصفحة الرئيسية
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => home.HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/skincare.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 150),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: List.generate(_routines.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: index == _currentStep ? Colors.white.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _routines[index]['title']!,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _routines[index]['description']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF88A383),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: Text(
                    _currentStep < _routines.length - 1 ? 'Next' : 'Finish',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: home.CustomBottomNavigationBar(),
    );
  }
}
