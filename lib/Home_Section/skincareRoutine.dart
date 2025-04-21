import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../SharedPreferences.dart';
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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      String? baseUrl = await getBaseUrl();
      if (baseUrl == null) {
        throw Exception("Base URL not found in SharedPreferences");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/routines/by-time'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _routines["MORNING"] = List<Map<String, dynamic>>.from(data["MORNING"] ?? []);
          _routines["AFTERNOON"] = List<Map<String, dynamic>>.from(data["AFTERNOON"] ?? []);
          _routines["NIGHT"] = List<Map<String, dynamic>>.from(data["NIGHT"] ?? []);
          _currentStep = 0;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _getAllRoutines() {
    List<Map<String, dynamic>> allRoutines = [];

    // Add only non-empty routines
    for (var time in _routines.keys) {
      if (_routines[time] != null && _routines[time]!.isNotEmpty) {
        allRoutines.addAll(_routines[time]!);
      }
    }

    return allRoutines;
  }

  void _nextStep(BuildContext context) {
    final allRoutines = _getAllRoutines();
    if (allRoutines.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
      return;
    }

    if (_currentStep < allRoutines.length - 1) {
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

  String _getCurrentTime() {
    final allRoutines = _getAllRoutines();
    if (allRoutines.isEmpty || _currentStep >= allRoutines.length) return "";
    final currentRoutine = allRoutines[_currentStep];
    return currentRoutine['usageTime']?.join(', ') ?? "";
  }

  Widget _buildNoRoutinesScreen() {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              _backgroundImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'No skincare routines available',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'You don\'t have any routines scheduled for today',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 166, 224, 228),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    child: Text(
                      'Go to Home',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineItem(Map<String, dynamic> routine) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (routine['photos'] != null && routine['photos'].isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              routine['photos'][0],
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(
                    color: Colors.grey,
                    height: 120,
                    child: Icon(Icons.error, color: Colors.white),
                  ),
            ),
          )
        else
          Container(
            height: 120,
            color: Colors.grey.withOpacity(0.5),
            child: Center(
              child: Icon(Icons.image_not_supported,
                  color: Colors.white, size: 40),
            ),
          ),
        SizedBox(height: 16),
        Text(
          routine['name'] ?? 'No Name',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          routine['smaledescription'] ?? 'No Description',
          style: TextStyle(fontSize: 16, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Usage Time: ${_getCurrentTime()}',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ],
    );
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

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load data',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchData,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final allRoutines = _getAllRoutines();

    if (allRoutines.isEmpty) {
      return _buildNoRoutinesScreen();
    }

    // Ensure current step is within bounds
    if (_currentStep >= allRoutines.length) {
      _currentStep = 0;
    }

    final currentRoutine = allRoutines[_currentStep];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Skincare Routine ${_currentStep + 1}/${allRoutines.length}',
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
          Positioned.fill(
            child: Image.network(
              _backgroundImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
            ),
          ),
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
          Center(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  )),
                  child: child,
                );
              },
              child: BackdropFilter(
                key: ValueKey<int>(_currentStep),
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Card(
                  color: Colors.black.withOpacity(0.5),
                  margin: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRoutineItem(currentRoutine),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => _nextStep(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 166, 224, 228),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 16),
                          ),
                          child: Text(
                            _currentStep < allRoutines.length - 1
                                ? 'Next'
                                : 'Finish',
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              _backgroundImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.grey),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'A moment of care that brings back the radiance to your skin! 🌟 With our app, your glowing look becomes easier and gentler than ever!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                          builder: (context) => SkincareRoutine(token: token),
                        ),
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