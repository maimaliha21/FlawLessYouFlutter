import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projtry1/ProfileSection/editProfile.dart';
import 'package:projtry1/ProfileSection/aboutUs.dart';
import 'dart:io';
import 'package:projtry1/ProfileSection/supportTeam.dart';
import 'package:projtry1/Routinebar/routinescreen.dart';

void main() {
  runApp(profile());
}

class profile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;

  // لاختيار صورة جديدة من المعرض أو الكاميرا
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/bgphoto.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 30,
                  right: 20,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'support') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => supportTeam()),
                        );
                      } else if (value == 'about_us') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => aboutUs()),
                        );
                      } else if (value == 'logout') {
                        // Add log out action
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'support',
                          child: Text('Support'),
                        ),
                        PopupMenuItem<String>(
                          value: 'about_us',
                          child: Text('About Us'),
                        ),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Text('Log Out'),
                        ),
                      ];
                    },
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                Positioned(
                  top: 150,
                  left: MediaQuery.of(context).size.width / 2 - 75,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: Stack(
                            children: [
                              Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                    image: _profileImage == null
                                        ? AssetImage('assets/profile.jpg') as ImageProvider
                                        : FileImage(_profileImage!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 15,  // المسافة بين الصورة والزر
                                left: 50,
                                right: 50,
                                child: ElevatedButton(
                                  onPressed: _pickImage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFB0BEC5), // اللون السكني
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text('Change Picture'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 75,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 65,
                          backgroundImage: _profileImage == null
                              ? AssetImage('assets/profile.jpg') as ImageProvider
                              : FileImage(_profileImage!),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 60),
            Text(
              'Melissa Peters',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Text(
              'Interior designer',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 5),
            Text(
              'Skin Type:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => editProfile()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xB3F2C4).withOpacity(0.3),
                    foregroundColor: Color(0xFF2A5E38),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Edit profile',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RoutineScreen()), // الانتقال إلى شاشة RoutineScreen
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xB3F2C4).withOpacity(0.3),
                    foregroundColor: Color(0xFF2A5E38),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'View Routine',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            TabBarSection(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(),
    );
  }
}

class CustomBottomNavigationBar extends StatefulWidget {
  @override
  _CustomBottomNavigationBarState createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _selectedIndex = 4;

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
    } else if(index == 1){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RoutineScreen()), // فتح الصفحة من ملف RoutineScreen.dart
      );
    } else {
      // Navigator.push(
      // context,
      // MaterialPageRoute(builder: (context) => home()) // فتح الصفحة من ملف profile.dart
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF2A5E38),
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.article), label: ""),
              BottomNavigationBarItem(icon: SizedBox.shrink(), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: ""),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "profile"),
            ],
          ),
        ),
        Positioned(
          top: -30,
          left: MediaQuery.of(context).size.width / 2 - 32,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF8A794D),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Icon(Icons.face, color: Colors.white, size: 32),
          ),
        ),
      ],
    );
  }
}

class TabBarSection extends StatefulWidget {
  @override
  _TabBarSectionState createState() => _TabBarSectionState();
}

class _TabBarSectionState extends State<TabBarSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Saved'),
            Tab(text: 'History'),
          ],
        ),
        Container(
          height: 200,
          child: TabBarView(
            controller: _tabController,
            children: [
              Center(child: Text('No saved items', style: TextStyle(color: Colors.black))),
              Center(child: Text('No history available', style: TextStyle(color: Colors.black))),
            ],
          ),
        ),
      ],
    );
  }
}
