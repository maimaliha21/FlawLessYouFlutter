import 'package:flutter/material.dart';
import '../Product/product.dart';
import 'package:projtry1/Home_Section/skincare%20routine.dart'as skincareroutine;


void main() {
  runApp(FlawlessYouApp());
}

class FlawlessYouApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Flawless You',
          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFC7C7BB),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Add background image here
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, Celina!',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF88A383)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Stack(
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/HI.png'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      height: 120,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don’t forget your daily skin routine, we care about you and your skin!',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => skincareroutine.SkincareRoutineScreen()),
    );

                            },
                            child: Text('Start Skincare Routine', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Tips',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      TipCard(icon: Icons.local_drink, text: 'Stay hydrated and moisturize regularly'),
                      TipCard(icon: Icons.wb_sunny, text: 'Use sunscreen daily'),
                      TipCard(icon: Icons.favorite, text: 'Skin-related advice and reminders'),
                      TipCard(icon: Icons.access_alarm, text: 'Avoid touching your face frequently'),
                      TipCard(icon: Icons.eco, text: 'Use eco-friendly skincare products'),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Product Collections',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(),
    );
  }
}

class TipCard extends StatelessWidget {
  final String text;
  final IconData icon;

  TipCard({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFC7C7BB),
        borderRadius: BorderRadius.circular(30),  // Larger and smoother shape
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF88A383), size: 26),
          SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  const CustomBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: BottomWaveClipper(),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Color(0xFFC7C7BB),
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
            backgroundColor: Color(0xFF88A383),
            onPressed: () {},
            child: const Icon(Icons.face, color: Color(0xFF9EA684)),
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
                IconButton(icon: Icon(Icons.home, color: Color(0xFF88A383)), onPressed: () {}),
                IconButton(icon: Icon(Icons.chat, color: Color(0xFF88A383)), onPressed: () {}),
                SizedBox(width: 60),
                IconButton(icon: Icon(Icons.settings, color: Color(0xFF88A383)), onPressed: () {}),
                IconButton(icon: Icon(Icons.person, color: Color(0xFF88A383)), onPressed: () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
