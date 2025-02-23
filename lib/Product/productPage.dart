import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projtry1/Product/product.dart'; // تأكد من أن هذا الاستيراد صحيح

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
    final String role = userInfo['role'] ?? 'USER'; // الافتراضي هو USER إذا لم يتم تقديم الدور

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Product Page'),
        backgroundColor: Colors.blue,
      ),
      body: role == 'ADMIN' ? _buildAdminView(context) : _buildUserView(context),
      bottomNavigationBar: CustomBottomNavigationBar(
        token: token,
        userInfo: userInfo,
      ),
    );
  }

  Widget _buildUserView(BuildContext context) {
    return ProductTabScreen(
      apiUrl: "http://localhost:8080/product/random?limit=6",
    );
  }

  Widget _buildAdminView(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          _showEditProductPopup(context);
        },
        child: const Text('Edit Product'),
      ),
    );
  }

  void _showEditProductPopup(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController ingredientsController = TextEditingController();
    final TextEditingController skinTypeController = TextEditingController();
    final TextEditingController usageTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: ingredientsController,
                  decoration: const InputDecoration(labelText: 'Ingredients'),
                ),
                TextField(
                  controller: skinTypeController,
                  decoration: const InputDecoration(labelText: 'Skin Type'),
                ),
                TextField(
                  controller: usageTimeController,
                  decoration: const InputDecoration(labelText: 'Usage Time'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // إعداد بيانات المنتج المحدثة
                final updatedProduct = {
                  "productId": "Atn5pCQF7VR4KhJCzI4g", // استبدل بمعرف المنتج الفعلي
                  "name": nameController.text,
                  "skinType": [skinTypeController.text],
                  "description": descriptionController.text,
                  "ingredients": [ingredientsController.text],
                  "usageTime": [usageTimeController.text],
                };

                // إرسال طلب PUT
                final response = await http.put(
                  Uri.parse('http://localhost:8080/product/product'),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode(updatedProduct),
                );

                // التعامل مع الاستجابة
                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product updated successfully!')),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update product: ${response.body}')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

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
            onPressed: () {},
            child: const Icon(Icons.face, color: Colors.white),
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
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.blue),
                  onPressed: () {},
                ),
                const SizedBox(width: 60),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.blue),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.blue),
                  onPressed: () {},
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