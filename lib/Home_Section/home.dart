import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mock user data (replace with data from your database later)
    final Map<String, String> userData = {
      'name': 'Celina', // Replace with the user's name
      'emotionText': "How'd you face emotions?",
      'protectText': 'The year face to protect',
      'lifeText': "Don't forget your story on your life.",
      'routineText': 'Your Lifecare Routine',
      'tipsText': 'TIPS',
      'productText': 'Product',
    };

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(userData: userData),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Map<String, String> userData;

  HomeScreen({required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help, ${userData['name']}', // Display the user's name
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              userData['emotionText'] ?? "How'd you face emotions?",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              userData['protectText'] ?? 'The year face to protect',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'H!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              userData['lifeText'] ?? "Don't forget your story on your life.",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              userData['routineText'] ?? 'Your Lifecare Routine',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              userData['tipsText'] ?? 'TIPS',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Say'),
            Text('Motstuffs'),
            Text('Use'),
            Text('updates/'),
            Text('Registry'),
            Text('Screeres'),
            SizedBox(height: 20),
            Text(
              userData['productText'] ?? 'Product',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}