import 'package:flutter/material.dart';

void main() {
  runApp(SkincareRoutineApp());
}

class SkincareRoutineApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SkincareRoutineScreen(),
    );
  }
}

class SkincareRoutineScreen extends StatefulWidget {
  @override
  _SkincareRoutineScreenState createState() => _SkincareRoutineScreenState();
}

class _SkincareRoutineScreenState extends State<SkincareRoutineScreen> {
  int _currentStep = 0;

  // قائمة الخطوات مع نفس الصورة لكل الخطوات
  final List<Map<String, String>> _routines = [
    {
      'title': 'Cleanse your face with an appropriate cleanser',
      'description': 'Use a gentle cleanser suitable for your skin type.',
    },
    {
      'title': 'Apply Toner',
      'description': 'Use a hydrating or exfoliating toner based on your skin needs.',
    },
    {
      'title': 'Apply Serum',
      'description': 'Use a serum to target specific skin concerns like wrinkles or dark spots.',
    },
    {
      'title': 'Apply Eye Cream',
      'description': 'Gently apply eye cream to reduce puffiness and dark circles.',
    },
    {
      'title': 'Apply Moisturizer',
      'description': 'Use a lightweight or rich moisturizer depending on your skin type.',
    },
    {
      'title': 'Apply Sunscreen (if daytime)',
      'description': 'Don\'t forget sunscreen to protect your skin from UV rays.',
    },
  ];

  // رابط الصورة الموحد
  final String _imageUrl =
      'https://res.cloudinary.com/davwgirjs/image/upload/v1738924453/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.28.05%20PM.jpeg_20250207123410.jpg';

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
            // عرض الصورة من الرابط الموحد
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SkincareRoutineApp()),
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