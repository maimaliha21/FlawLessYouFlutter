import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(Signup());
}

class Signup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Create Profile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CreateProfileScreen(),
    );
  }
}

class CreateProfileScreen extends StatefulWidget {
  @override
  _CreateProfileScreenState createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen>
    with TickerProviderStateMixin {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  // AnimationControllers for each circle
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  late AnimationController _controller4;

  late Animation<Offset> _animation1;
  late Animation<Offset> _animation2;
  late Animation<Offset> _animation3;
  late Animation<Offset> _animation4;

  @override
  void initState() {
    super.initState();

    // Initialize the AnimationControllers with a longer duration for smoother looping
    _controller1 = AnimationController(
      duration: Duration(seconds: 2), // Adjust duration for slower/faster motion
      vsync: this,
    )..repeat(reverse: true); // Loop the animation forward and backward

    _controller2 = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _controller3 = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _controller4 = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    // Define the animations using Tween
    _animation1 = Tween<Offset>(
      begin: Offset(-0.05, -0.05), // Small range to keep circles visible
      end: Offset(0.05, 0.05),
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_controller1);

    _animation2 = Tween<Offset>(
      begin: Offset(-0.05, 0.05),
      end: Offset(0.05, -0.05),
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_controller2);

    _animation3 = Tween<Offset>(
      begin: Offset(0.05, -0.05),
      end: Offset(-0.05, 0.05),
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_controller3);

    _animation4 = Tween<Offset>(
      begin: Offset(0.05, 0.05),
      end: Offset(-0.05, -0.05),
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_controller4);
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Dispose the controllers
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _controller4.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background circles with continuous loop animation
          Positioned(
            top: 50, // Adjusted to keep circles visible
            left: 50,
            child: AnimatedBuilder(
              animation: _controller1,
              builder: (context, child) {
                return Transform.translate(
                  offset: _animation1.value * 110, // Small multiplier for subtle movement
                  child: CircleAvatar(
                    radius: 90,
                    backgroundColor: Colors.cyan.withOpacity(0.4),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: -50, // Adjusted to keep circles visible
            right: -50,
            child: AnimatedBuilder(
              animation: _controller2,
              builder: (context, child) {
                return Transform.translate(
                  offset: _animation2.value * 160,
                  child: CircleAvatar(
                    radius: 120,
                    backgroundColor: Colors.cyan.withOpacity(0.3),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 50, // Adjusted to keep circles visible
            left: -50,
            child: AnimatedBuilder(
              animation: _controller3,
              builder: (context, child) {
                return Transform.translate(
                  offset: _animation3.value * 150,
                  child: CircleAvatar(
                    radius: 100,
                    backgroundColor: Colors.cyan.withOpacity(0.3),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -50, // Adjusted to keep circles visible
            right: 50,
            child: AnimatedBuilder(
              animation: _controller4,
              builder: (context, child) {
                return Transform.translate(
                  offset: _animation4.value * 100,
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.cyan.withOpacity(0.4),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  Text(
                    'Create Profile',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  SizedBox(height: 30),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _image != null ? FileImage(_image!) : null,
                        child: _image == null ? Icon(Icons.person, size: 50) : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImagePickerOptions,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'YYYY',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'MM',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'DD',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      // Implement next button logic here
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Next'),
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