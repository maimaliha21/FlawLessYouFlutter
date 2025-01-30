import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChooseGenderScreen(),
    );
  }
}

class ChooseGenderScreen extends StatefulWidget {
  @override
  _ChooseGenderScreenState createState() => _ChooseGenderScreenState();
}

class _ChooseGenderScreenState extends State<ChooseGenderScreen> {
  String? selectedGender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Hello, User',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'What is your gender?',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedGender = 'Male';
                    });
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: selectedGender == 'Male'
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                        child: Icon(
                          Icons.male,
                          size: 40,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text('Male'),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedGender = 'Female';
                    });
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: selectedGender == 'Female'
                            ? Colors.pink.shade100
                            : Colors.grey.shade200,
                        child: Icon(
                          Icons.female,
                          size: 40,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text('Female'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Action for Next button
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
