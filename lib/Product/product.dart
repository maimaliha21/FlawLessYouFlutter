import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const ProductApp());
}

class ProductApp extends StatelessWidget {
  const ProductApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    const Center(child: Text("Home")),
    const ProductTabScreen(),
    const Center(child: Text("Search")),
    const Center(child: Text("Settings")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue.shade900,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Products"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

class ProductTabScreen extends StatelessWidget {
  const ProductTabScreen({Key? key}) : super(key: key);

  static final List<Product> products = [
    Product(
      id: 1,
      name: "Face Cleanser",
      description: "Gentle cleanser for all skin types.",
      rating: 4.5,
      imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738924453/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.28.05%20PM.jpeg_20250207123410.jpg",
    ),
    Product(
      id: 2,
      name: "Moisturizer",
      description: "Hydrates and nourishes the skin.",
      rating: 4.7,
      imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738924475/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.27.29%20PM.jpeg_20250207123434.jpg",
    ),
    Product(
      id: 3,
      name: "Sunscreen",
      description: "SPF 50+ protection from UV rays.",
      rating: 4.8,
      imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738924453/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.28.05%20PM.jpeg_20250207123410.jpg",
    ),
    // Add more products here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Products"),
        centerTitle: true,
      ),
      body: ProductList(products: products),
    );
  }
}

class Product {
  final int id;
  final String name;
  final String description;
  final double rating;
  final String imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.rating,
    required this.imageUrl,
  });
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

  Future<void> saveProduct(int productId) async {
    final url = Uri.parse('https://your-backend-api.com/save'); // استبدل ب URL الباكند
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'productId': productId}),
    );

    if (response.statusCode == 200) {
      setState(() {
        isSaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product saved successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save product.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.product.imageUrl,
              fit: BoxFit.cover,
            ),
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
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.description,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                              (index) => Icon(
                            Icons.star,
                            color: index < widget.product.rating.floor()
                                ? Colors.yellow
                                : Colors.grey,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.product.rating.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  saveProduct(widget.product.id); // إرسال طلب حفظ المنتج
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}