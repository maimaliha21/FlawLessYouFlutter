import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_card.dart';

class SavedProductsList extends StatelessWidget {
  final String token;

  const SavedProductsList({Key? key, required this.token}) : super(key: key);

  Future<List<dynamic>> _fetchSavedProducts() async {
    final response = await http.get(
      Uri.parse('http://localhost:8080/product/Saved'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load saved products');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _fetchSavedProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return const Text('Error loading products');
        final products = snapshot.data!;
        return products.isEmpty
            ? const Center(child: Text('No saved products', style: TextStyle(color: Colors.black)))
            : GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => ProductCard(
            product: products[index],
            token: token,
            compactMode: true,
          ),
        );
      },
    );
  }
}