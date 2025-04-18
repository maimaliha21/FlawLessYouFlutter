import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FlawlessYou/Product/product.dart';
import '../CustomBottomNavigationBar.dart';
import '../CustomBottomNavigationBarAdmin.dart'; // تأكد من صحة هذا الاستيراد

class ProductPage extends StatelessWidget {
  final String token;
  final Map<String, dynamic> userInfo;

  const ProductPage({
    super.key,
    required this.token,
    required this.userInfo,
  });

  @override
  Widget build(BuildContext context) {
    // دالة لجلب معلومات المستخدم من SharedPreferences
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

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Product Page'),
        backgroundColor: const Color(0xFFC7C7BB),
      ),
      body: FutureBuilder<String?>(
        future: getBaseUrl(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No base URL found'));
          } else {
            return ProductTabScreen(
              apiUrl: "${snapshot.data}/product/random?limit=12",
              pageName: 'home',
            );
          }
        },
      ),
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
    );
  }

  Future<String?> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('baseUrl');
  }
}