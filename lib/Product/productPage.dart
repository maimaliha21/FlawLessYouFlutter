import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FlawlwssYou/Product/product.dart';

import '../CustomBottomNavigationBar.dart'; // تأكد من صحة هذا الاستيراد

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
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Product Page'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<String?>(
        future: getBaseUrl(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No base URL found'));
          } else {
            return ProductTabScreen(
              apiUrl: "${snapshot.data}/product/random?limit=6",
            );
          }
        },
      ),
      bottomNavigationBar: CustomBottomNavigationBar2(), // استخدام CustomBottomNavigationBar

    );
  }

  Future<String?> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('baseUrl');
  }
}
