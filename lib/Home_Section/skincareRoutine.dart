import 'dart:convert';
import 'dart:ui'; // Import for ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';

final String _backgroundImageUrl =
    'https://res.cloudinary.com/davwgirjs/image/upload/v1740317838/nhndev/product/320aee5f-ac8b-48be-94c7-e9296259cf99_1740317835039_Screenshot%202025-02-23%20153620.png.png';

class SkincareRoutine extends StatefulWidget {
  final String token;
  SkincareRoutine({required this.token});

  @override
  _SkincareRoutineScreenState createState() => _SkincareRoutineScreenState();
}

class _SkincareRoutineScreenState extends State<SkincareRoutine> {
  int _currentStep = 0;
  Map<String, List<Map<String, dynamic>>> _routines = {
    "MORNING": [],
    "AFTERNOON": [],
    "NIGHT": [],
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.13:8080/api/routines/by-time'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _routines["MORNING"] = List<Map<String, dynamic>>.from(data["MORNING"]);
          _routines["AFTERNOON"] = List<Map<String, dynamic>>.from(data["AFTERNOON"]);
          _routines["NIGHT"] = List<Map<String, dynamic>>.from(data["NIGHT"]);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  void _nextStep(BuildContext context) {
    if (_currentStep < _routines.values.expand((list) => list).length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  List<Map<String, dynamic>> _getAllRoutines() {
    return _routines.values.expand((list) => list).toList();
  }

  String _getCurrentTime() {
    final allRoutines = _getAllRoutines();
    final currentRoutine = allRoutines[_currentStep];
    return currentRoutine['usageTime'].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final allRoutines = _getAllRoutines();
    final currentRoutine = allRoutines[_currentStep];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // جعل لون الخلفية شفاف
        elevation: 0, // إزالة الظل
        title: Text(
          'Skincare Routine ${_currentStep + 1}',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // Background Image (Normal - No Blur)
          Positioned.fill(
            child: Image.network(
              _backgroundImageUrl,
              fit: BoxFit.cover,
            ),
          ),
          // Time Header
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _getCurrentTime(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content with Blurred Card
          Center(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 500), // Animation duration
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, 0.5), // Slide from bottom
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  )),
                  child: child,
                );
              },
              child: BackdropFilter(
                key: ValueKey<int>(_currentStep), // Unique key for animation
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Card(
                  color: Colors.transparent, // جعل لون الخلفية شفاف
                  margin: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Image (Normal)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            currentRoutine['photos'][0],
                            width: double.infinity, // Take full width
                            height: 120,
                            fit: BoxFit.cover, // Ensure the image covers the area
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.error, color: Colors.white),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          currentRoutine['name'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          currentRoutine['description'],
                          style: TextStyle(fontSize: 16, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Skin Type: ${currentRoutine['skinType'].join(', ')}',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Usage Time: ${currentRoutine['usageTime'].join(', ')}',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => _nextStep(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 166, 224, 228),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          ),
                          child: Text(
                            _currentStep < allRoutines.length - 1 ? 'Next' : 'Finish',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Routine'),
        backgroundColor: Colors.transparent, // جعل لون الخلفية شفاف
        elevation: 0, // إزالة الظل
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              _backgroundImageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'A moment of care that brings back the radiance to your skin! 🌟 With our app, your glowing look becomes easier and gentler than ever!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    String? token = prefs.getString('token');
                    if (token != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>Home(
                              token: token,
                            ),),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Token not found')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 166, 224, 228),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: Text(
                    'Start Routine',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}