import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:projtry1/ProfileSection/profile.dart';


void main() {
  runApp(RoutineScreen());
}

class RoutineScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (index == 4) {
      // الانتقال إلى صفحة البروفايل عند الضغط على الأيقونة
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => profile()), // فتح الصفحة من ملف profile.dart
      );
    } else if(index == 3) {
      setState(() {
        _selectedIndex = index;
      });
    } else if(index == 2){
      //camera
    } else if(index == 1){ Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RoutineScreen()), // فتح الصفحة من ملف profile.dart
    );
    } else {
      // Navigator.push(
      // context,
      // MaterialPageRoute(builder: (context) => home()) // فتح الصفحة من ملف profile.dart

  }}

  final List<Widget> _pages = [
    Center(child: Text("home")),
    RoutineTabScreen(),
    Center(child: Text("routine")),
    Center(child: Text("settings")),
    // لا حاجة لإضافة صفحة البروفايل هنا لأننا نفتحها عند الضغط على الأيقونة
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: Colors.blue.shade900,
              unselectedItemColor: Colors.grey,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
                BottomNavigationBarItem(icon: Icon(Icons.article), label: ""),
                BottomNavigationBarItem(icon: SizedBox.shrink(), label: ""),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: ""),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
              ],
            ),
          ),
          Positioned(
            top: -30,
            left: MediaQuery.of(context).size.width / 2 - 32,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Icon(Icons.face, color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class RoutineTabScreen extends StatelessWidget {
  final List<Routine> morningRoutines = [
    Routine(name: "Morning Cleanser", time: "7:00 AM", details: "Apply cleanser and rinse with warm water.", imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738924453/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.28.05%20PM.jpeg_20250207123410.jpg"),
    Routine(name: "Moisturizing", time: "7:30 AM", details: "Use hydrating cream on face and neck.", imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738924475/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.27.29%20PM.jpeg_20250207123434.jpg"),
    Routine(name: "Sunscreen", time: "8:00 AM", details: "Apply SPF 50 sunscreen evenly.", imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738917076/nhndev/product/Screenshot%202025-02-06%20230725.png_20250207103114.png"),
  ];

  final List<Routine> afternoonRoutines = [
    Routine(name: "Toner", time: "12:00 PM", details: "Apply toner to refresh skin.", imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738924475/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.27.29%20PM.jpeg_20250207123434.jpg"),
    Routine(name: "Hydration Spray", time: "1:00 PM", details: "Use hydration mist for a fresh feel.", imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738917076/nhndev/product/Screenshot%202025-02-06%20230725.png_20250207103114.png"),
    Routine(name: "Night Serum", time: "9:00 PM", details: "Apply serum before bed.", imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738924453/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.28.05%20PM.jpeg_20250207123410.jpg"),
  ];

  final List<Routine> eveningRoutines = [
    Routine(name: "Night Serum", time: "9:00 PM", details: "Apply serum before bed.", imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738924453/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.28.05%20PM.jpeg_20250207123410.jpg"),
    Routine(name: "Moisturizer", time: "9:30 PM", details: "Use night moisturizer for hydration.", imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738917076/nhndev/product/Screenshot%202025-02-06%20230725.png_20250207103114.png"),
    Routine(name: "Moisturizing", time: "7:30 AM", details: "Use hydrating cream on face and neck.", imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738924475/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.27.29%20PM.jpeg_20250207123434.jpg"),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          title: Text("Skin Care Routine"),
          centerTitle: true,
          bottom: TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey[700],
            indicatorColor: Colors.yellow[700],
            tabs: [
              Tab(text: "Morning"),
              Tab(text: "Afternoon"),
              Tab(text: "Evening"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RoutineList(routines: morningRoutines),
            RoutineList(routines: afternoonRoutines),
            RoutineList(routines: eveningRoutines),
          ],
        ),
      ),
    );
  }
}

class Routine {
  final String name;
  final String time;
  final String details;
  final String imageUrl;

  Routine({required this.name, required this.time, required this.details, required this.imageUrl});
}

class RoutineList extends StatelessWidget {
  final List<Routine> routines;

  RoutineList({required this.routines});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: routines.length,
        itemBuilder: (context, index) {
          return RoutineCard(routine: routines[index]);
        },
      ),
    );
  }
}

class RoutineCard extends StatelessWidget {
  final Routine routine;

  RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.network(routine.imageUrl, width: double.infinity, height: 200, fit: BoxFit.cover),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(12),
                color: Colors.grey.withOpacity(0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(routine.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(routine.time, style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 5),
                    Text(routine.details, style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
