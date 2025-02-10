// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: HomeScreen(),
//     );
//   }
// }
//
// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       bottomNavigationBar: BottomNavigationBar(
//         selectedItemColor: Colors.white,
//         unselectedItemColor: Colors.white70,
//         backgroundColor: Color.fromRGBO(166, 224, 228, 1), // اللون السماوي المتوسط
//         items: [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Schedule'),
//           BottomNavigationBarItem(icon: Icon(Icons.face), label: 'Community'),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage('assets/background.png'),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             padding: EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 20),
//                 Text(
//                   'Hello, Celina',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//                 Text(
//                   'How’s your face condition?',
//                   style: TextStyle(color: Colors.black87),
//                 ),
//                 SizedBox(height: 10),
//                 TextField(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => SearchScreen()),
//                     );
//                   },
//                   readOnly: true,
//                   decoration: InputDecoration(
//                     hintText: 'Find your favorite product',
//                     filled: true,
//                     fillColor: Color.fromRGBO(200, 236, 238, 1), // اللون السماوي الفاتح جدًا
//                     prefixIcon: Icon(Icons.search, color: Colors.black54),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 Container(
//                   padding: EdgeInsets.all(16.0),
//                   decoration: BoxDecoration(
//                     color: Color.fromRGBO(200, 236, 238, 1), // اللون السماوي الفاتح جدًا
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black26,
//                         blurRadius: 4,
//                         offset: Offset(2, 2),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Hi',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                       Text(
//                         'Don’t forget your daily skin routine, we care about you and your skin',
//                         style: TextStyle(color: Colors.black),
//                       ),
//                       TextButton(
//                         onPressed: () {},
//                         child: Text(
//                           'Start Skincare Routine',
//                           style: TextStyle(color: Colors.black),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 Text(
//                   'TIPS',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 10),
//                 TipsCarousel(),
//                 SizedBox(height: 20),
//                 Text(
//                   'Product',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 10),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class TipsCarousel extends StatefulWidget {
//   @override
//   _TipsCarouselState createState() => _TipsCarouselState();
// }
//
// class _TipsCarouselState extends State<TipsCarousel> {
//   int _currentIndex = 0;
//
//   final List<Widget> _tips = [
//     tipCard('Stay Hydrated', Color.fromRGBO(200, 236, 238, 1)),
//     tipCard('Moisturize Regularly', Color.fromRGBO(166, 224, 228, 1)),
//     tipCard('Use Sunscreen', Colors.orange[100]!),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           height: 130, // Slightly smaller height for tips
//           child: PageView.builder(
//             itemCount: _tips.length,
//             controller: PageController(viewportFraction: 0.8),
//             onPageChanged: (index) {
//               setState(() {
//                 _currentIndex = index;
//               });
//             },
//             itemBuilder: (context, index) {
//               return _tips[index];
//             },
//           ),
//         ),
//         SizedBox(height: 10),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: List.generate(_tips.length, (index) {
//             return Container(
//               margin: EdgeInsets.symmetric(horizontal: 4),
//               width: 8,
//               height: 8,
//               decoration: BoxDecoration(
//                 color: _currentIndex == index
//                     ? Color(0xFF36D8F4) // Stylish line color
//                     : Colors.grey,
//                 shape: BoxShape.circle,
//               ),
//             );
//           }),
//         ),
//       ],
//     );
//   }
//
//   static Widget tipCard(String text, Color backgroundColor) {
//     return AnimatedSwitcher(
//       duration: Duration(milliseconds: 300),
//       child: Container(
//         key: ValueKey<String>(text), // Unique key for animation
//         width: double.infinity,
//         margin: EdgeInsets.symmetric(horizontal: 8.0),
//         padding: EdgeInsets.all(12.0), // Smaller padding
//         decoration: BoxDecoration(
//           color: backgroundColor,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 4,
//               offset: Offset(2, 2),
//             ),
//           ],
//         ),
//         child: Center(
//           child: Text(
//             text,
//             style: TextStyle(
//               fontSize: 16, // Smaller font size for tips
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class SearchScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Search'),
//       ),
//       body: Center(
//         child: Text('Search Page Content Here'),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Color.fromRGBO(166, 224, 228, 1),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.face), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text(
                  'Hello, Celina',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,  // تغيير النص إلى مايل
                    color: Colors.black,
                  ),
                ),
                Text(
                  'How’s your face condition?',
                  style: TextStyle(color: Colors.black87),
                ),
                SizedBox(height: 10),
                TextField(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchScreen()),
                    );
                  },
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Find your favorite product',
                    filled: true,
                    fillColor: Color.fromRGBO(200, 236, 238, 1),
                    prefixIcon: Icon(Icons.search, color: Colors.black54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/HI.png'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,  // تغيير النص إلى مايل
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Don’t forget your daily skin routine, we care about you and your skin',
                        style: TextStyle(color: Colors.black),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Start Skincare Routine',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'TIPS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),  // تغيير النص إلى مايل
                ),
                SizedBox(height: 10),
                TipsCarousel(),
                SizedBox(height: 20),
                Text(
                  'Product',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TipsCarousel extends StatefulWidget {
  @override
  _TipsCarouselState createState() => _TipsCarouselState();
}

class _TipsCarouselState extends State<TipsCarousel> {
  int _currentIndex = 0;

  final List<Widget> _tips = [
    tipCard('Stay Hydrated', Color.fromRGBO(200, 236, 238, 1)),
    tipCard('Moisturize Regularly', Color.fromRGBO(166, 224, 228, 1)),
    tipCard('Use Sunscreen',Color.fromRGBO(200, 236, 238, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 130,
          child: PageView.builder(
            itemCount: _tips.length,
            controller: PageController(viewportFraction: 0.8),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _tips[index];
            },
          ),
        ),
      ],
    );
  }
}

Widget tipCard(String text, Color backgroundColor) {
  return AnimatedSwitcher(
    duration: Duration(milliseconds: 300),
    child: Container(
      key: ValueKey<String>(text),
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Center(
        child: Text('Search Page Content Here'),
      ),
    );
  }
}
