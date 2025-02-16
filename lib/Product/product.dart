import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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
    // ProductTabScreen(token: "your_token_here"), // قم بتغيير "your_token_here" إلى التوكن الفعلي
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

class Product {
  final String productId;
  final String? name;
  final String? description;
  final double rating;
  final String? imageUrl;
  bool isSaved;

  Product({
    required this.productId,
    this.name,
    this.description,
    required this.rating,
    this.imageUrl,
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

    String? imageUrl;
    final photos = json['photos'];
    if (photos is List && photos.isNotEmpty) {
      imageUrl = photos[0];
    }

    return Product(
      productId: json['productId'] as String? ?? 'unknown',
      name: json['name'] as String?,
      description: json['description'] as String?,
      rating: avgRating,
      imageUrl: imageUrl,
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
      // Check if the response body is valid JSON
      try {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is List) {
          List<Product> products = decodedBody.map((json) => Product.fromJson(json)).toList();

          // Fetch saved status for each product
          for (var product in products) {
            final savedResponse = await http.get(
              Uri.parse('http://localhost:8080/product/${product.productId}/isSaved'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );

            if (savedResponse.statusCode == 200) {
              // Handle the case where the response is a bool directly
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
          return ProductCard(product: products[index], token: token);
        },
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;
  final String token;

  const ProductCard({Key? key, required this.product, required this.token}) : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    isSaved = widget.product.isSaved;
  }

  Future<void> toggleSave() async {
    final newState = !isSaved;
    setState(() => isSaved = newState);

    try {
      final response = await (newState
          ? http.post(
        Uri.parse('http://localhost:8080/product/${widget.product.productId}/savedProduct'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      )
          : http.post(
        Uri.parse('http://localhost:8080/product/${widget.product.productId}/savedProduct'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      ));

      if (response.statusCode != 200) {
        setState(() => isSaved = !newState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${newState ? 'save' : 'unsave'} product')),
        );
      }
    } catch (e) {
      setState(() => isSaved = !newState);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error')),
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
            if (widget.product.imageUrl != null)
              Image.network(
                widget.product.imageUrl!,
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
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              )
            else
              Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.white),
                ),
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
                      widget.product.name ?? 'No Name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.description ?? 'No description available',
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
                onPressed: toggleSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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