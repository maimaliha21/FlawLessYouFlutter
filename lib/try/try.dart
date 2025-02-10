import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignInScreen(),
    );
  }
}

class SignInScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Circles
          Positioned(
            top: -50,
            left: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.cyan.withOpacity(0.3),
            ),
          ),
          Positioned(
            top: 50,
            left: 50,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.cyan.withOpacity(0.4),
            ),
          ),

          // Bottom Illustration
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [


                  Image.asset(
                    'assets/p1.png', // Replace with your actual asset
                    width: 190,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
