import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final String _imageUrl = 'https://res.cloudinary.com/davwgirjs/image/upload/v1738924453/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.28.05%20PM.jpeg_20250207123410.jpg';


class SkincareRoutine extends StatefulWidget {
  final String token;
  SkincareRoutine({required this.token});

  @override
  _SkincareRoutineScreenState createState() => _SkincareRoutineScreenState();
}

class _SkincareRoutineScreenState extends State<SkincareRoutine> {
  int _currentStep = 0;
  List<Map<String, String>> _routines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final response = await http.get(
      Uri.parse('http://localhost:8080/product/search'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _routines = List<Map<String, String>>.from(data['routines']);
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  void _nextStep(BuildContext context) {
    if (_currentStep < _routines.length - 1) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 166, 224, 228),
        title: Text(
          'Skincare Routine ${_currentStep + 1}',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Step ${_currentStep + 1}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 166, 224, 228),
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16),
            Image.network(
              _imageUrl,
              height: 120,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.error), // عرض أيقونة خطأ إذا فشل التحميل
            ),
            SizedBox(height: 24),
            Text(
              _routines[_currentStep]['title']!,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 166, 224, 228),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              _routines[_currentStep]['description']!,
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
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
                _currentStep < _routines.length - 1 ? 'Next' : 'Finish',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
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
        backgroundColor: Color.fromARGB(255, 166, 224, 228),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'لحظة عناية تُعيد لِبشرتكِ إشراقتها! 🌟 مع تطبيقنا، إطلالتكِ المشرقة بتكون أسهل وألطف من أي وقت!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (context) => SkincareRoutine()),
                //);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 166, 224, 228),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: Text(
                'Back To Home Page',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}