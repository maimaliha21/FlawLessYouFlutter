import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class Product {
  final String productId;
  final String? name;
  final List<String>? skinType;
  final String? description;
  final List<String>? ingredients;
  final String adminId;
  final List<String> photos;
  final List<String>? reviewIds;

  const Product({
    required this.productId,
    this.name,
    this.skinType,
    this.description,
    this.ingredients,
    required this.adminId,
    required this.photos,
    this.reviewIds,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'],
      name: json['name'],
      skinType: json['skinType'] != null ? List<String>.from(json['skinType']) : null,
      description: json['description'],
      ingredients: json['ingredients'] != null ? List<String>.from(json['ingredients']) : null,
      adminId: json['adminId'],
      photos: List<String>.from(json['photos']),
      reviewIds: json['reviewIds'] != null ? List<String>.from(json['reviewIds']) : null,
    );
  }
}

class ProductTabScreen extends StatelessWidget {
  final String token;

  const ProductTabScreen({Key? key, required this.token}) : super(key: key);

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/product/random?limit=6'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
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

          return ProductList(products: snapshot.data!);
        },
      ),
    );
  }
}

class ProductList extends StatelessWidget {
  final List<Product> products;

  const ProductList({Key? key, required this.products}) : super(key: key);

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
          return ProductCard(product: products[index]);
        },
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isSaved = false;

  // Function to get the first 3 words of the description
  String _getShortDescription(String? description) {
    if (description == null || description.isEmpty) return 'No Description';
    List<String> words = description.split(' ');
    if (words.length > 3) {
      return '${words.take(3).join(' ')}...';
    }
    return description;
  }

  // Show product details in a dialog
  void _showProductDetails(BuildContext context) {
    int currentImageIndex = 0;
    Timer? _timer;

    if (widget.product.photos.length > 1) {
      _timer = Timer.periodic(Duration(seconds: 6), (timer) {
        setState(() {
          currentImageIndex = (currentImageIndex + 1) % widget.product.photos.length;
        });
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero, // إزالة الحواف الداخلية للبوبر
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.9, // عرض البوبر 90% من الشاشة
                height: MediaQuery.of(context).size.height * 0.7, // ارتفاع البوبر 70% من الشاشة
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // عرض الصورة
                    Expanded(
                      child: Image.network(
                        widget.product.photos[currentImageIndex],
                        fit: BoxFit.cover, // تغطية المساحة المتاحة
                      ),
                    ),
                    const SizedBox(height: 16),
                    // عرض الوصف الكامل
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.product.description ?? 'No Description',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _timer?.cancel(); // إيقاف الـ Timer عند إغلاق البوبر
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProductDetails(context),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Product Image
              Image.network(
                widget.product.photos[0], // Always show the first image
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.error),
              ),
              // Product Details Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        widget.product.name ?? 'No Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Short Description
                      Text(
                        _getShortDescription(widget.product.description),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // Save Button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.yellow : Colors.white,
                  ),
                  onPressed: () => saveProduct(widget.product.productId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Save product to the user's saved items
  Future<void> saveProduct(String productId) async {
    final url = Uri.parse('https://your-backend-api.com/save');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_TOKEN_HERE', // Include token if needed
        },
        body: jsonEncode({'productId': productId}),
      );

      if (response.statusCode == 200) {
        setState(() => isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product saved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save product.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}