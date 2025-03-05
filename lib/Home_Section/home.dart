import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../Product/product.dart';
import '../Product/productPage.dart';
import '../Home_Section/search.dart';
import '../Home_Section/skincareRoutine.dart';

class Home extends StatelessWidget {
  final String token;

  const Home({
    Key? key,
    required this.token,
  }) : super(key: key);

  // دالة لاسترجاع بيانات المستخدم من SharedPreferences
  Future<Map<String, dynamic>> _getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userInfoJson = prefs.getString('userInfo');
    if (userInfoJson != null) {
      return jsonDecode(userInfoJson);
    }
    return {};
  }

  // دالة لاسترجاع الرابط من SharedPreferences
  Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('baseUrl') ?? ''; // قيمة افتراضية إذا لم يتم العثور على الرابط
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController searchController = TextEditingController();

    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading user data'));
        }

        Map<String, dynamic> userInfo = snapshot.data ?? {};

        return FutureBuilder<String>(
          future: getBaseUrl(), // استرجاع الرابط من SharedPreferences
          builder: (context, baseUrlSnapshot) {
            if (baseUrlSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (baseUrlSnapshot.hasError) {
              return Center(child: Text('Error loading base URL'));
            }

            final baseUrl = baseUrlSnapshot.data!;

            return DefaultTabController(
              length: 2, // عدد علامات التبويب
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Flawless You',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Color(0xFFC7C7BB),
                  elevation: 0,
                  centerTitle: true,
                ),
                body: Stack(
                  children: [
                    // خلفية الصفحة
                    Positioned.fill(
                      child: Image.asset(
                        'assets/background.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ترحيب بالمستخدم
                          Text(
                            'Hello, ${userInfo['userName'] ?? 'User'}!',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),

                          // حقل البحث
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search products',
                                    prefixIcon: Icon(Icons.search, color: Color(0xFF88A383)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              IconButton(
                                icon: Icon(Icons.search, color: Color(0xFF88A383)),
                                onPressed: () {
                                  if (searchController.text.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => search(
                                          token: token,
                                          searchQuery: searchController.text,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          // بطاقة العناية بالبشرة
                          Stack(
                            children: [
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage('assets/HI.png'),
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              Container(
                                height: 120,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.black.withOpacity(0.3),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Don’t forget your daily skin routine, we care about you and your skin!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    TextButton(
                                      onPressed: () {
                                        // الانتقال إلى صفحة العناية بالبشرة
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SkincareRoutine(
                                              token: token,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Start Skincare Routine',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 20),

                          // قسم النصائح
                          Text(
                            'Tips',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                TipCard(
                                  icon: Icons.local_drink,
                                  text: 'Stay hydrated and moisturize regularly',
                                ),
                                TipCard(
                                  icon: Icons.wb_sunny,
                                  text: 'Use sunscreen daily',
                                ),
                                TipCard(
                                  icon: Icons.favorite,
                                  text: 'Skin-related advice and reminders',
                                ),
                                TipCard(
                                  icon: Icons.access_alarm,
                                  text: 'Avoid touching your face frequently',
                                ),
                                TipCard(
                                  icon: Icons.eco,
                                  text: 'Use eco-friendly skincare products',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),

                          // قسم المنتجات
                          Text(
                            'Product Collections',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                ProductTabScreen(
                                  apiUrl: "$baseUrl/product/random?limit=6", // استخدام الرابط المسترجع
                                ),
                                // يمكنك إضافة علامات تبويب إضافية هنا
                                // Center(child: Text('Tab 2 Content')),
                                // Center(child: Text('Tab 3 Content')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: CustomBottomNavigationBar(
                  token: token,
                  userInfo: userInfo,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// بطاقة النصيحة
class TipCard extends StatelessWidget {
  final String text;
  final IconData icon;

  TipCard({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFC7C7BB),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF88A383), size: 26),
          SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// شريط التنقل السفلي
class CustomBottomNavigationBar extends StatelessWidget {
  final String token;
  final Map<String, dynamic> userInfo;

  const CustomBottomNavigationBar({
    super.key,
    required this.token,
    required this.userInfo,
  });

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
              color: Color(0xFFC7C7BB),
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
            backgroundColor: Color(0xFF88A383),
            onPressed: () {
              // إضافة أي تفاعل تريده هنا
            },
            child: const Icon(Icons.face, color: Color(0xFF9EA684)),
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
                  icon: Icon(Icons.home, color: Color(0xFF88A383)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Home(
                          token: token,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.chat, color: Color(0xFF88A383)),
                  onPressed: () {
                    // إضافة تفاعل للذهاب إلى صفحة الدردشة
                  },
                ),
                SizedBox(width: 60), // مساحة فارغة لتجنب تداخل الأيقونات
                IconButton(
                  icon: Icon(Icons.settings, color: Color(0xFF88A383)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  ProductPage(
                          token: token,
                          userInfo: userInfo,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.person, color: Color(0xFF88A383)),
                  onPressed: () {
                    // إضافة تفاعل للذهاب إلى صفحة الملف الشخصي
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

// تصميم الشريط السفلي
class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(size.width / 4, size.height, size.width / 2, size.height - 20);
    path.quadraticBezierTo(size.width * 3 / 4, size.height - 40, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}