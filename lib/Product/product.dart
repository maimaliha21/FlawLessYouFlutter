import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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
      bottomNavigationBar: CustomBottomNavigationBar(
        onItemTapped: _onItemTapped,
        selectedIndex: _selectedIndex,
      ),
    );
  }
}

class ProductTabScreen extends StatelessWidget {
  const ProductTabScreen({Key? key}) : super(key: key);

  Future<List<Product>> fetchProducts() async {
    // final response = await http.get(
    //   Uri.parse('https://your-backend-api.com/products'),
    //
    // );
    //
    // if (response.statusCode == 200) {
    //   List<dynamic> data = json.decode(response.body);
    //   return data.map((json) => Product.fromJson(json)).toList();
    return [
    Product(
      id: 1,
      name: "Face Cleanser",
      description: "Gentle cleanser for all skin types.",
      rating: 4.5,
      imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738924453/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.28.05%20PM.jpeg_20250207123410.jpg",
    ),
    ];
  }
    // else {  return [
    //   Product(
    //     id: 1,
    //     name: "Face Cleanser",
    //     description: "Gentle cleanser for all skin types.",
    //     rating: 4.5,
    //     imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738924453/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.28.05%20PM.jpeg_20250207123410.jpg",
    //   ),
    //   Product(
    //     id: 2,
    //     name: "Moisturizer",
    //     description: "Hydrates and nourishes the skin.",
    //     rating: 4.7,
    //     imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738924475/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.27.29%20PM.jpeg_20250207123434.jpg",
    //   ),
    //   Product(
    //     id: 3,
    //     name: "Sunscreen",
    //     description: "SPF 50+ protection from UV rays.",
    //     rating: 4.8,
    //     imageUrl: "https://res.cloudinary.com/davwgirjs/image/upload/v1738924453/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.28.05%20PM.jpeg_20250207123410.jpg",
    //   ),
    // ];
    //   }
  // }

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

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      rating: json['rating'].toDouble(),
      imageUrl: json['imageUrl'],
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

  Future<void> saveProduct(int productId) async {
    final url = Uri.parse('https://your-backend-api.com/save');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
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
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.product.imageUrl,
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
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
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
                        ...List.generate(5, (index) {
                          double starPosition = index + 1.0;
                          if (widget.product.rating >= starPosition) {
                            return const Icon(
                              Icons.star,
                              color: Colors.yellow,
                              size: 16,
                            );
                          } else if (widget.product.rating >= starPosition - 0.5) {
                            return const Icon(
                              Icons.star_half,
                              color: Colors.yellow,
                              size: 16,
                            );
                          } else {
                            return const Icon(
                              Icons.star_border,
                              color: Colors.grey,
                              size: 16,
                            );
                          }
                        }),
                        const SizedBox(width: 4),
                        Text(
                          widget.product.rating.toStringAsFixed(1),
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
                  color: isSaved ? Colors.yellow : Colors.white,
                ),
                onPressed: () => saveProduct(widget.product.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CustomBottomNavigationBar و BottomWaveClipper يبقى نفس الكود السابق دون تغيير
class CustomBottomNavigationBar extends StatelessWidget {
  final Function(int) onItemTapped;
  final int selectedIndex;

  const CustomBottomNavigationBar({
    super.key,
    required this.onItemTapped,
    required this.selectedIndex,
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
                  icon: Icon(Icons.home, color: selectedIndex == 0 ? Colors.blue : Colors.grey),
                  onPressed: () => onItemTapped(0),
                ),
                IconButton(
                  icon: Icon(Icons.shopping_cart, color: selectedIndex == 1 ? Colors.blue : Colors.grey),
                  onPressed: () => onItemTapped(1),
                ),
                const SizedBox(width: 60),
                IconButton(
                  icon: Icon(Icons.search, color: selectedIndex == 2 ? Colors.blue : Colors.grey),
                  onPressed: () => onItemTapped(2),
                ),
                IconButton(
                  icon: Icon(Icons.settings, color: selectedIndex == 3 ? Colors.blue : Colors.grey),
                  onPressed: () => onItemTapped(3),
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

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 4), size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 30);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, size.height - 30);
    path.lineTo(size.width, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}