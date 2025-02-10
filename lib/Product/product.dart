import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
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
    Center(child: Text("Home")),
    ProductTabScreen(),
    Center(child: Text("Camera")),
    Center(child: Text("Settings")),
    Center(child: Text("Profile")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade900,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
      ),
    );
  }
}

class ProductTabScreen extends StatelessWidget {
  final List<Product> products = [
    Product(
      name: "Unicorn Sprinkles",
      imageUrl: "https://example.com/unicorn_sprinkles.jpg",
      details: "A fluffy fresh cooked donut covered by a creamy strawberry flavour with rainbow sprinkles.",
      rating: 4.5,
    ),
    Product(
      name: "Dark Sprinkles",
      imageUrl: "https://example.com/dark_sprinkles.jpg",
      details: "Chocolate donut with sprinkles.",
      rating: 4.2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: Text("Sweets"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        ),
      ),
    );
  }
}

class Product {
  final String name;
  final String imageUrl;
  final String details;
  final double rating;

  Product({required this.name, required this.imageUrl, required this.details, required this.rating});
}

class ProductCard extends StatelessWidget {
  final Product product;

  ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Image.network(product.imageUrl, width: double.infinity, height: 200, fit: BoxFit.cover),
            Container(
              padding: EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 5),
                  Text(product.details, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  SizedBox(height: 5),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < product.rating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.yellow,
                        size: 18,
                      );
                    }),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.favorite_border),
                        onPressed: () {},
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
                        child: Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}