import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final String currentPage; // الصفحة الحالية
  final Function(String) onTabTapped; // دالة للتنقل بين الصفحات

  CustomBottomNavigationBar({
    required this.currentPage,
    required this.onTabTapped,
  });

  // الأيقونات للزر العائم بناءً على الصفحة الحالية
  IconData _getFloatingIcon() {
    switch (currentPage) {
      case "Home":
        return Icons.home; // أيقونة الهوم
      case "Search":
        return Icons.search; // أيقونة البحث
      case "Notifications":
        return Icons.notifications; // أيقونة الإشعارات
      case "Profile":
        return Icons.face; // أيقونة الوجه (البروفايل)
      default:
        return Icons.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: BottomWaveClipper(),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 25,
          left: MediaQuery.of(context).size.width / 2 - 30,
          child: FloatingActionButton(
            backgroundColor: Colors.blue,
            onPressed: () {
              // وظيفة الزر العائم
              print("Floating Button Pressed!");
            },
            child: Icon(_getFloatingIcon()), // تغيير الأيقونة بناءً على الصفحة الحالية
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.blue),
                  onPressed: () {
                    onTabTapped("Home"); // الانتقال إلى صفحة الهوم
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.blue),
                  onPressed: () {
                    onTabTapped("Search"); // الانتقال إلى صفحة البحث
                  },
                ),
                const SizedBox(width: 60), // مساحة فارغة للزر العائم
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.blue),
                  onPressed: () {
                    onTabTapped("Notifications"); // الانتقال إلى صفحة الإشعارات
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.blue),
                  onPressed: () {
                    onTabTapped("Profile"); // الانتقال إلى صفحة البروفايل
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(size.width / 4, size.height, size.width / 2, size.height - 20);
    path.quadraticBezierTo(3 / 4 * size.width, size.height - 40, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}