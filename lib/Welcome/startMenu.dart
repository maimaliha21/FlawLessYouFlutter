import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartMenuScreen(),
    );
  }
}

class StartMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                image: DecorationImage(
                  image: AssetImage('assets/welcomelogo.png'), // Replace with your image path
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 90),
            Text(

              'Embrace your flaws, they make you unique',
              style: TextStyle(

                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                shadows: [
                  Shadow(
                    offset: Offset(6, 18),
                    blurRadius: 5,
                    color: Color(0xFF86CCF8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
