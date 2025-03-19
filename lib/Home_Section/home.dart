import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../Product/product.dart';
import '../Product/productPage.dart';
import '../Home_Section/search.dart';
import '../Home_Section/skincareRoutine.dart';
import '../CustomBottomNavigationBar.dart';
import '../CustomBottomNavigationBarAdmin.dart';

class Home extends StatelessWidget {
  final String token;

  const Home({
    Key? key,
    required this.token,
  }) : super(key: key);

  // Fetch user info from SharedPreferences
  Future<Map<String, dynamic>> _getUserInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userInfoJson = prefs.getString('userInfo');
      if (userInfoJson != null) {
        return jsonDecode(userInfoJson);
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
    return {};
  }

  // Fetch base URL from SharedPreferences
  Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('baseUrl') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController searchController = TextEditingController();

    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading user data'));
        }

        Map<String, dynamic> userInfo = snapshot.data ?? {};

        return FutureBuilder<String>(
          future: getBaseUrl(),
          builder: (context, baseUrlSnapshot) {
            if (baseUrlSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (baseUrlSnapshot.hasError) {
              return const Center(child: Text('Error loading base URL'));
            }

            final baseUrl = baseUrlSnapshot.data!;

            return DefaultTabController(
              length: 1, // Update to match the number of tabs
              child: Scaffold(
                appBar: AppBar(
                  title: const Text(
                    'Flawless You',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: const Color(0xFFC7C7BB),
                  elevation: 0,
                  centerTitle: true,
                ),
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting
                        Text(
                          'Hello, ${userInfo['userName'] ?? 'User'}!',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Search bar
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search products',
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.search,
                                  color: Color(0xFF88A383)),
                              onPressed: () {
                                if (searchController.text.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => search(
                                        token: token,
                                        searchQuery: searchController.text,
                                        pageName: 'home',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Skincare routine card
                        Stack(
                          children: [
                            Container(
                              height: 130,
                              decoration: BoxDecoration(
                                image: const DecorationImage(
                                  image: AssetImage('assets/HI.png'),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            Container(
                              height: 140,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.black.withOpacity(0.3),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Don’t forget your daily skin routine, we care about you and your skin!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SkincareRoutine(token: token),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Start Skincare Routine',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Tips section
                        const Text(
                          'Tips',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: const [
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
                        const SizedBox(height: 10),

                        // Product collections
                        const Text(
                          'Product Collections',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 300, // Adjust height as needed
                          child: TabBarView(
                            children: [
                              ProductTabScreen(
                                apiUrl: "$baseUrl/product/random?limit=6",
                                pageName: 'home',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom navigation bar based on user role
                bottomNavigationBar: FutureBuilder<Map<String, dynamic>>(
                  future: _getUserInfo(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    final role = snapshot.data?["role"] ?? "USER";
                    return role == "ADMIN"
                        ? CustomBottomNavigationBarAdmin()
                        : CustomBottomNavigationBar2();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Tip card widget
class TipCard extends StatelessWidget {
  final String text;
  final IconData icon;

  const TipCard({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC7C7BB),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF88A383), size: 26),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}