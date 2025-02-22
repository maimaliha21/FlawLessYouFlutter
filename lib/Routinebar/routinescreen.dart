import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'dart:async';

class RoutineScreen extends StatelessWidget {
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
  String? token;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      // Navigate to profile page
    } else if (index == 3) {
      setState(() {
        _selectedIndex = index;
      });
    } else if (index == 2) {
      // Camera
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RoutineScreen()),
      );
    } else {
      // Navigate to home
    }
  }

  final List<Widget> _pages = [
    Center(child: Text("home")),
    Center(child: Text("routine")),
    Center(child: Text("settings")),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _pages[1] = RoutineTabScreen(token: token);

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: Color(0xFF2A5E38),
              unselectedItemColor: Colors.grey,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
                BottomNavigationBarItem(icon: Icon(Icons.article), label: "routine"),
                BottomNavigationBarItem(icon: SizedBox.shrink(), label: ""),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: ""),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
              ],
            ),
          ),
          Positioned(
            top: -30,
            left: MediaQuery.of(context).size.width / 2 - 32,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF8A794D),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Icon(Icons.face, color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class RoutineTabScreen extends StatefulWidget {
  final String? token;

  RoutineTabScreen({required this.token});

  @override
  _RoutineTabScreenState createState() => _RoutineTabScreenState();
}

class _RoutineTabScreenState extends State<RoutineTabScreen> {
  Map<String, List<Routine>> routines = {
    "MORNING": [],
    "AFTERNOON": [],
    "NIGHT": [],
  };

  final List<String> backgroundImages = [
    "https://res.cloudinary.com/davwgirjs/image/upload/v1738924453/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.28.05%20PM.jpeg_20250207123410.jpg",
    "https://res.cloudinary.com/davwgirjs/image/upload/v1738924475/nhndev/product/WhatsApp%20Image%202025-02-07%20at%2012.27.29%20PM.jpeg_20250207123434.jpg",
  ];

  Map<String, dynamic>? userRoutine;

  @override
  void initState() {
    super.initState();
    fetchRoutines();
    fetchUserRoutine();
  }

  Future<void> fetchRoutines() async {
    if (widget.token == null) {
      throw Exception('Token is null');
    }

    final response = await http.get(
      Uri.parse('http://localhost:8080/api/routines/by-time'),
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
      throw Exception('Failed to load routines');
    }
  }

  Future<void> fetchUserRoutine() async {
    if (widget.token == null) {
      throw Exception('Token is null');
    }

    final response = await http.get(
      Uri.parse('http://localhost:8080/api/routines/userRoutine'),
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
      throw Exception('Failed to load user routine');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          // بطاقة "مرحبا بك في روتينك"
          if (userRoutine != null) UserRoutineCard(userRoutine: userRoutine),
          // التبويبات (Tabs)
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
                        RoutineList(routines: routines["MORNING"]!, backgroundImages: backgroundImages, token: widget.token!),
                        RoutineList(routines: routines["AFTERNOON"]!, backgroundImages: backgroundImages, token: widget.token!),
                        RoutineList(routines: routines["NIGHT"]!, backgroundImages: backgroundImages, token: widget.token!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

class RoutineList extends StatelessWidget {
  final List<Routine> routines;
  final List<String> backgroundImages;
  final String token;

  RoutineList({required this.routines, required this.backgroundImages, required this.token});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: routines.length,
        itemBuilder: (context, index) {
          String imageUrl = backgroundImages[index % backgroundImages.length];
          return RoutineCard(routine: routines[index], imageUrl: imageUrl, token: token);
        },
      ),
    );
  }
}

class UserRoutineCard extends StatelessWidget {
  final Map<String, dynamic>? userRoutine;

  UserRoutineCard({this.userRoutine});

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
                      "مرحبا بك في روتينك",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
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
                        routine.usageTime.join(', '), // عرض الأوقات
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        routine.description, // عرض الوصف
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 2, // تحديد عدد الأسطر
                        overflow: TextOverflow.ellipsis, // تقصير النص إذا كان طويلاً
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
      final response = await http.get(
        Uri.parse('http://localhost:8080/product/${widget.product.productId}/userReview'),
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
      final response = await http.put(
        Uri.parse('http://localhost:8080/product/${widget.product.productId}/reviews'),
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
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.product.photos.length,
              itemBuilder: (context, index) {
                return Image.network(
                  widget.product.photos[index],
                  fit: BoxFit.cover,
                );
              },
            ),
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