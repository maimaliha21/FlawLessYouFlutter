import 'package:flutter/material.dart';
import 'package:projtry1/ProfileSection/aboutUs.dart';
import 'package:table_calendar/table_calendar.dart';

import 'home.dart';

void main() {
  runApp(SkincareApp());
}

class SkincareApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SkincareCalendarScreen(),
    );
  }
}

class SkincareCalendarScreen extends StatefulWidget {
  @override
  _SkincareCalendarScreenState createState() => _SkincareCalendarScreenState();
}

class _SkincareCalendarScreenState extends State<SkincareCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 166, 224, 228),
    title: Text(
    'Schedule',
    style: TextStyle(fontStyle: FontStyle.italic),
    ),centerTitle: true,
    leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () {
    Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => aboutUs()), // استبدل HomeScreen بالشاشة الصحيحة
    );
    },
    ),
      ),
    body: Stack(
        children: [
          // Custom background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.png'), // Add your background image to assets
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TableCalendar(
                  firstDay: DateTime(2025, 1, 1),
                  lastDay: DateTime(2025, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Color.fromARGB(255,166 , 224,228 ),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: _getSkincareRoutines(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getSkincareRoutines() {
    return [
      _routineCard(
        title: 'Morning Routine',
        time: '7:00 AM',
        steps: [
          'Cleanse your face with a gentle cleanser',
          'Apply a lightweight moisturizer',
          'Use sunscreen to protect your skin',
        ],
      ),
      _routineCard(
        title: 'Mid-Morning Routine',
        time: '11:00 AM',
        steps: [
          'Spritz a face mist to refresh your skin',
          'Reapply sunscreen if needed',
        ],
      ),
      _routineCard(
        title: 'Afternoon Routine',
        time: '3:00 PM',
        steps: [
          'Reapply sunscreen',
          'Cleanse your face if you’ve been outdoors',
        ],
      ),
      _routineCard(
        title: 'Evening Routine',
        time: '5:30 PM',
        steps: [
          'Use a gentle cleanser to remove makeup',
          'Apply a nourishing moisturizer',
        ],
      ),
      _routineCard(
        title: 'Night Routine',
        time: '9:30 PM',
        steps: [
          'Double cleanse your face',
          'Apply a night serum and eye cream',
          'Use a heavier night moisturizer',
        ],
      ),
    ];
  }

  Widget _routineCard({required String title, required String time, required List<String> steps}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 166, 224, 228)),
            ),
            SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 8),
            ...steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text('- $step'),
            )),
          ],
        ),
      ),
    );
  }
}
