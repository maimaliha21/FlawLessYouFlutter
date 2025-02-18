import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'skin_product.dart'; // استيراد ملف skin_product.dart

class Product {
  final String productId;
  final String? name;
  final List<String> skinType;
  final List<String> ingredients;
  final String? description;
  final double rating;
  final List<String>? photos;
  bool isSaved;

  Product({
    required this.productId,
    this.name,
    required this.skinType,
    required this.ingredients,
    this.description,
    required this.rating,
    this.photos,
    this.isSaved = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double avgRating = 0.0;
    final reviews = json['reviews'];
    if (reviews != null && reviews is Map<String, dynamic>) {
      final ratings = reviews.values.whereType<int>().toList();
      if (ratings.isNotEmpty) {
        avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
      }
    }

    List<String>? photos;
    if (json['photos'] is List) {
      photos = List<String>.from(json['photos']);
    }

    return Product(
      productId: json['productId'] as String? ?? 'unknown',
      name: json['name'] as String?,
      skinType: List<String>.from(json['skinType'] ?? []),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      description: json['description'] as String?,
      rating: avgRating,
      photos: photos,
      isSaved: json['isSaved'] is bool ? json['isSaved'] : false,
    );
  }
}

class ProductTabScreen extends StatelessWidget {
  final String token;

  const ProductTabScreen({Key? key, required this.token}) : super(key: key);

  Future<List<Product>> fetchProducts() async {
    final response = await http.get(
      Uri.parse('http://localhost:8080/product/random?limit=6'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is List) {
          List<Product> products = decodedBody.map((json) => Product.fromJson(json)).toList();

          for (var product in products) {
            final savedResponse = await http.get(
              Uri.parse('http://localhost:8080/product/${product.productId}/isSaved'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );

            if (savedResponse.statusCode == 200) {
              if (savedResponse.body == 'true' || savedResponse.body == 'false') {
                product.isSaved = savedResponse.body == 'true';
              } else {
                final savedData = jsonDecode(savedResponse.body);
                product.isSaved = savedData['isSaved'] is bool ? savedData['isSaved'] : false;
              }
            }
          }

          return products;
        } else {
          throw Exception('Invalid response format: Expected a list of products');
        }
      } catch (e) {
        throw Exception('Failed to parse response: $e');
      }
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Products"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Product>>(
        future: fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ProductList(products: snapshot.data!, token: token);
        },
      ),
    );
  }
}

class ProductList extends StatelessWidget {
  final List<Product> products;
  final String token;

  const ProductList({
    Key? key,
    required this.products,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return SkinProductCard(product: products[index], token: token);
        },
      ),
    );
  }
}