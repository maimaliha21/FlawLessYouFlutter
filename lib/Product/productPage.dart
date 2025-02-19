import 'package:flutter/material.dart';
import 'package:projtry1/Product/product.dart'; // Ensure this import is correct

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
      body: ProductTabScreen(
        token: token,
        apiUrl: "http://localhost:8080/product/random?limit=6",
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        token: token,
        userInfo: userInfo,
      ),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    // Implement API call and display products here
    return Center(
      child: Text("Products will be displayed here"), // Placeholder
    );
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
                  onPressed: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => produ(
                    //       token: token,
                    //       apiUrl: "http://localhost:8080/product/random?limit=6",
                    //     ),
                    //   ),
                    // );
                  },
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