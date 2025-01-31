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
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help, ${userData['name']}', // Display the user's name
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              SizedBox(height: 10),
              Text(
                userData['emotionText'] ?? "How'd you face emotions?",
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              SizedBox(height: 10),
              Text(
                userData['protectText'] ?? 'The year face to protect',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              SizedBox(height: 20),
              Text(
                'Hi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              SizedBox(height: 10),
              Text(
                userData['lifeText'] ?? "Don't forget your story on your life.",
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              SizedBox(height: 20),
              Text(
                userData['routineText'] ?? 'Your Lifecare Routine',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              SizedBox(height: 10),
              Text(
                userData['tipsText'] ?? 'TIPS',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  _buildTip('Stay'),
                  _buildTip('Moisturize'),
                  _buildTip('Use'),
                  _buildTip('Hydrate'),
                  _buildTip('Regularly'),
                  _buildTip('Sunscreen'),
                ],
              ),
              SizedBox(height: 20),
              Text(
                userData['productText'] ?? 'Product',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              SizedBox(height: 10),
              _buildProductGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: Colors.blueAccent.withOpacity(0.2),
      labelStyle: TextStyle(color: Colors.blueAccent),
    );
  }

  Widget _buildProductGrid() {
    // Placeholder for product grid
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      children: List.generate(4, (index) {
        return Card(
          elevation: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 50, color: Colors.blueAccent),
              SizedBox(height: 10),
              Text('Product ${index + 1}', style: TextStyle(color: Colors.blueAccent)),
            ],
          ),
        );
      }),
    );
  }
}