import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'dart:async';

import '../CustomBottomNavigationBar.dart';
import '../ProfileSection/profile.dart';
import '../SharedPreferences.dart';

class RoutineScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;
  String? token;
  bool _isLoading = true;
  String? userInfo;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userInfoString = prefs.getString('userInfo');
    Map<String, dynamic> userInfoMap = json.decode(userInfoString ?? '{}');

    setState(() {
      token = prefs.getString('token');
      userInfo = userInfoMap['userName'];
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RoutineTabScreen(token: token, userName: userInfo),
    );
  }
}

class RoutineTabScreen extends StatefulWidget {
  final String? token;
  final String? userName;

  RoutineTabScreen({required this.token, this.userName});

  @override
  _RoutineTabScreenState createState() => _RoutineTabScreenState();
}

class _RoutineTabScreenState extends State<RoutineTabScreen> {
  Map<String, List<Routine>> routines = {
    "MORNING": [],
    "AFTERNOON": [],
    "NIGHT": [],
  };

  final List<String> morningBackgroundImages = [
    "https://res.cloudinary.com/davwgirjs/image/upload/v1746352809/nhndev/product/NWE2SFwq86zEmb03694l_1746352809636_WhatsApp%20Image%202025-05-04%20at%2012.59.16_2f7b005b.jpg.jpg",
    "https://res.cloudinary.com/davwgirjs/image/upload/v1746354105/nhndev/product/NWE2SFwq86zEmb03694l_1746354106058_WhatsApp%20Image%202025-05-04%20at%2013.20.37_dea70b38.jpg.jpg"
  ];

  final List<String> afternoonBackgroundImages = [
    "https://res.cloudinary.com/davwgirjs/image/upload/v1746354581/nhndev/product/NWE2SFwq86zEmb03694l_1746354581240_WhatsApp%20Image%202025-05-04%20at%2013.29.10_b523eab1.jpg.jpg",
    "https://res.cloudinary.com/davwgirjs/image/upload/v1746354357/nhndev/product/NWE2SFwq86zEmb03694l_1746354357364_WhatsApp%20Image%202025-05-04%20at%2013.25.21_d1b5d2bc.jpg.jpg"
  ];

  final List<String> eveningBackgroundImages = [
    "https://res.cloudinary.com/davwgirjs/image/upload/v1746354751/nhndev/product/NWE2SFwq86zEmb03694l_1746354751028_WhatsApp%20Image%202025-05-04%20at%2013.32.04_04787fe5.jpg.jpg",
    "https://res.cloudinary.com/davwgirjs/image/upload/v1746354998/nhndev/product/NWE2SFwq86zEmb03694l_1746354999195_WhatsApp%20Image%202025-05-04%20at%2013.36.17_c034e5d9.jpg.jpg"
  ];

  Map<String, dynamic>? userRoutine;
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRoutines();
    fetchUserRoutine();
  }

  Future<void> fetchRoutines() async {
    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token is null')),
      );
      return;
    }

    try {
      String? baseUrl = await getBaseUrl();
      if (baseUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Base URL is not set')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/routines/by-time'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          routines["MORNING"] = (data["MORNING"] as List)
              .map((item) => Routine.fromJson(item))
              .toList();
          routines["AFTERNOON"] = (data["AFTERNOON"] as List)
              .map((item) => Routine.fromJson(item))
              .toList();
          routines["NIGHT"] = (data["NIGHT"] as List)
              .map((item) => Routine.fromJson(item))
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load routines')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error')),
      );
    }
  }

  Future<void> fetchUserRoutine() async {
    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token is null')),
      );
      return;
    }

    try {
      String? baseUrl = await getBaseUrl();
      if (baseUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Base URL is not set')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/routines/userRoutine'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          userRoutine = data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user routine')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error')),
      );
    }
  }

  Widget _buildTabContent(List<Routine> routines, List<String> backgroundImages) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: routines.map((routine) {
            String imageUrl = backgroundImages[routines.indexOf(routine) % backgroundImages.length];
            return RoutineCard(
              routine: routine,
              imageUrl: imageUrl,
              token: widget.token!,
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          if (userRoutine != null)
            UserRoutineCard(
              userRoutine: userRoutine,
              userName: widget.userName,
            ),

          SizedBox(height: 20),

          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey[700],
                    indicatorColor: Colors.yellow[700],
                    tabs: const [
                      Tab(text: "Morning"),
                      Tab(text: "Afternoon"),
                      Tab(text: "Evening"),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        // Morning Tab
                        _buildTabContent(
                          routines["MORNING"]!,
                          morningBackgroundImages,
                        ),

                        // Afternoon Tab
                        _buildTabContent(
                          routines["AFTERNOON"]!,
                          afternoonBackgroundImages,
                        ),

                        // Evening Tab
                        _buildTabContent(
                          routines["NIGHT"]!,
                          eveningBackgroundImages,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar2(),
    );
  }
}

class Routine {
  final String productId;
  final String name;
  final List<String> skinType;
  final String description;
  final List<String> ingredients;
  final String adminId;
  final List<String> photos;
  final Map<String, dynamic> reviews;
  final List<String> usageTime;

  Routine({
    required this.productId,
    required this.name,
    required this.skinType,
    required this.description,
    required this.ingredients,
    required this.adminId,
    required this.photos,
    required this.reviews,
    required this.usageTime,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      productId: json['productId'],
      name: json['name'],
      skinType: List<String>.from(json['skinType']),
      description: json['description'],
      ingredients: List<String>.from(json['ingredients']),
      adminId: json['adminId'],
      photos: List<String>.from(json['photos']),
      reviews: json['reviews'],
      usageTime: List<String>.from(json['usageTime']),
    );
  }
}

class UserRoutineCard extends StatelessWidget {
  final Map<String, dynamic>? userRoutine;
  final String? userName;

  UserRoutineCard({this.userRoutine, this.userName});

  @override
  Widget build(BuildContext context) {
    if (userRoutine == null) {
      return Container();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.network(
              "https://res.cloudinary.com/davwgirjs/image/upload/v1740264486/nhndev/product/320aee5f-ac8b-48be-94c7-e9296259cf99_1740264484011_download.jpg.jpg",
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(12),
                color: Colors.grey.withOpacity(0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to your routine, $userName!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      userRoutine!['description'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Analysis ID: ${userRoutine!['analysisId']}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoutineCard extends StatelessWidget {
  final Routine routine;
  final String imageUrl;
  final String token;

  RoutineCard({required this.routine, required this.imageUrl, required this.token});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return ProductDetailsPopup(product: routine, token: token);
          },
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(12),
                  color: Colors.grey.withOpacity(0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        routine.usageTime.join(', '),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        routine.description,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductDetailsPopup extends StatefulWidget {
  final Routine product;
  final String token;

  const ProductDetailsPopup({Key? key, required this.product, required this.token}) : super(key: key);

  @override
  _ProductDetailsPopupState createState() => _ProductDetailsPopupState();
}

class _ProductDetailsPopupState extends State<ProductDetailsPopup> {
  late PageController _pageController;
  int _currentPage = 0;
  double _userRating = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
    _fetchUserRating();
  }

  void _startAutoSlide() {
    Timer.periodic(Duration(seconds: 8), (timer) {
      if (_currentPage < (widget.product.photos.length ?? 1) - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _fetchUserRating() async {
    try {
      String? baseUrl = await getBaseUrl();
      if (baseUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Base URL is not set')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/product/${widget.product.productId}/userReview'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final rating = jsonDecode(response.body);
        setState(() {
          _userRating = rating.toDouble();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch user rating')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error')),
      );
    }
  }

  Future<void> _submitRating(double rating) async {
    try {
      String? baseUrl = await getBaseUrl();
      if (baseUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Base URL is not set')),
        );
        return;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/product/${widget.product.productId}/reviews'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'rating': rating.toInt()}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rating submitted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit rating')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 300,
            child: widget.product.photos.isNotEmpty
                ? PageView.builder(
              controller: _pageController,
              itemCount: widget.product.photos.length,
              itemBuilder: (context, index) {
                return Image.network(
                  widget.product.photos[index],
                  fit: BoxFit.cover,
                );
              },
            )
                : Center(child: Text('No photos available')),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  widget.product.description,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                if (widget.product.skinType.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skin Type:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.product.skinType.join(', '),
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                if (widget.product.ingredients.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ingredients:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.product.ingredients.join(', '),
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                _isLoading
                    ? CircularProgressIndicator()
                    : RatingBar.builder(
                  initialRating: _userRating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _userRating = rating;
                    });
                    _submitRating(rating);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}