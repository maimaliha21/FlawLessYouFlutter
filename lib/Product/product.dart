import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? _baseUrl;

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseUrl = prefs.getString('baseUrl') ?? 'http://localhost:8080';
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    const Center(child: Text("Home")),
    const Center(child: Text("Search")),
    const Center(child: Text("Settings")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
    );
  }
}

class Product {
  final String productId;
  final String? name;
  final List<String> skinType;
  final List<String> ingredients;
  final String? description;
  final double rating;
  final List<String>? photos;
  final List<String>? usageTime;
  bool isSaved;

  Product({
    required this.productId,
    this.name,
    required this.skinType,
    required this.ingredients,
    this.description,
    required this.rating,
    this.photos,
    this.usageTime,
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

    List<String>? usageTime;
    if (json['usageTime'] is List) {
      usageTime = List<String>.from(json['usageTime']);
    }

    return Product(
      productId: json['productId'] as String? ?? 'unknown',
      name: json['name'] as String?,
      skinType: List<String>.from(json['skinType'] ?? []),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      description: json['description'] as String?,
      rating: avgRating,
      photos: photos,
      usageTime: usageTime,
      isSaved: json['isSaved'] is bool ? json['isSaved'] : false,
    );
  }
}

class ProductTabScreen extends StatefulWidget {
  final String apiUrl;
  final String pageName;
  final String? treatmentId;

  const ProductTabScreen({
    Key? key,
    required this.apiUrl,
    required this.pageName,
    this.treatmentId,
  }) : super(key: key);

  @override
  _ProductTabScreenState createState() => _ProductTabScreenState();
}

class _ProductTabScreenState extends State<ProductTabScreen> {
  String? token;
  String? userRole;
  bool _isLoading = true;
  String? _baseUrl;
  List<Product> _products = [];
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadToken();
    await _loadBaseUrl();
    await _loadProducts();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userInfoString = prefs.getString('userInfo');
    Map<String, dynamic> userInfoMap = json.decode(userInfoString ?? '{}');

    setState(() {
      token = prefs.getString('token');
      userRole = userInfoMap['role'];
    });
  }

  Future<void> _loadBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseUrl = prefs.getString('baseUrl') ?? 'http://localhost:8080';
    });
  }

  Future<void> _loadProducts() async {
    if (token == null) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/product/random?limit=12'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        List<Product> products = [];

        for (var item in responseData) {
          if (item is Map<String, dynamic>) {
            Product product = Product.fromJson(item['product']);
            product.isSaved = item['saved'] is bool ? item['saved'] : false;
            products.add(product);
          }
        }

        setState(() {
          _products = products;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        color: Colors.blue,
        backgroundColor: Colors.white,
        displacement: 40.0,
        edgeOffset: 20.0,
        strokeWidth: 3.0,
        triggerMode: RefreshIndicatorTriggerMode.onEdge,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Failed to load products',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 50, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'No products available',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ProductList(
      products: _products,
      token: token!,
      userRole: userRole!,
      baseUrl: _baseUrl!,
      pageName: widget.pageName,
      treatmentId: widget.treatmentId,
      onDelete: _loadProducts,
    );
  }
}

class ProductList extends StatelessWidget {
  final List<Product> products;
  final String token;
  final String userRole;
  final String baseUrl;
  final String pageName;
  final String? treatmentId;
  final VoidCallback onDelete;

  const ProductList({
    Key? key,
    required this.products,
    required this.token,
    required this.userRole,
    required this.baseUrl,
    required this.pageName,
    this.treatmentId,
    required this.onDelete,
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
          return ProductCard(
            product: products[index],
            token: token,
            userRole: userRole,
            baseUrl: baseUrl,
            pageName: pageName,
            treatmentId: treatmentId,
            onDelete: onDelete,
          );
        },
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;
  final String token;
  final String userRole;
  final String baseUrl;
  final String pageName;
  final String? treatmentId;
  final VoidCallback onDelete;

  const ProductCard({
    Key? key,
    required this.product,
    required this.token,
    required this.userRole,
    required this.baseUrl,
    required this.pageName,
    this.treatmentId,
    required this.onDelete,
  }) : super(key: key);

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
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/product/${widget.product.productId}/savedProduct'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'saved': newState}),
      );

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

  Future<void> _deleteProduct() async {
    try {
      final response = await http.delete(
        Uri.parse('${widget.baseUrl}/api/treatments/${widget.treatmentId}/products/${widget.product.productId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product deleted successfully')),
        );
        widget.onDelete();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete product')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error')),
      );
    }
  }

  Future<void> _addProductToTreatment() async {
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/api/treatments/${widget.treatmentId}/products/${widget.product.productId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product added to treatment successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product to treatment')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error')),
      );
    }
  }

  void _showProductDetails(BuildContext context) {
    if (widget.userRole == 'ADMIN') {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: EdgeInsets.all(16),
            child: EditProductPopup(
              product: widget.product,
              token: widget.token,
              baseUrl: widget.baseUrl,
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: EdgeInsets.all(16),
            child: ProductDetailsPopup(
              product: widget.product,
              token: widget.token,
              baseUrl: widget.baseUrl,
              treatmentId: widget.treatmentId,
            ),
          );
        },
      );
    }
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
              if (widget.product.photos != null && widget.product.photos!.isNotEmpty)
                Image.network(
                  widget.product.photos![0],
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
                    widget.pageName == 'treatment' ? Icons.delete :
                    widget.pageName == 'add' ? Icons.add :
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: widget.pageName == 'treatment' ? Colors.red :
                    widget.pageName == 'add' ? Colors.green :
                    isSaved ? Colors.yellow : Colors.white,
                  ),
                  onPressed: widget.pageName == 'treatment' ? _deleteProduct :
                  widget.pageName == 'add' ? _addProductToTreatment : toggleSave,
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
  final Product product;
  final String token;
  final String baseUrl;
  final String? treatmentId;

  const ProductDetailsPopup({
    Key? key,
    required this.product,
    required this.token,
    required this.baseUrl,
    this.treatmentId,
  }) : super(key: key);

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
      if (_currentPage < (widget.product.photos?.length ?? 1) - 1) {
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
        Uri.parse('${widget.baseUrl}/product/${widget.product.productId}/userReview'),
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
        const SnackBar(content: Text('Connection error')),
      );
    }
  }

  Future<void> _submitRating(double rating) async {
    try {
      final response = await http.put(
        Uri.parse('${widget.baseUrl}/product/${widget.product.productId}/reviews'),
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
              itemCount: widget.product.photos?.length ?? 1,
              itemBuilder: (context, index) {
                return Image.network(
                  widget.product.photos?[index] ?? widget.product.photos?.first ?? '',
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
                  widget.product.name ?? 'No Name',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  widget.product.description ?? 'No description available',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                if (widget.treatmentId != null)
                  Text(
                    'Treatment ID: ${widget.treatmentId}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

class EditProductPopup extends StatefulWidget {
  final Product product;
  final String token;
  final String baseUrl;
  const EditProductPopup({Key? key, required this.product, required this.token, required this.baseUrl}) : super(key: key);

  @override
  _EditProductPopupState createState() => _EditProductPopupState();
}

class _EditProductPopupState extends State<EditProductPopup> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late Map<String, bool> _skinType;
  late List<String> _ingredients;
  late Map<String, bool> _usageTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _skinType = {
      'OILY': widget.product.skinType.contains('OILY'),
      'DRY': widget.product.skinType.contains('DRY'),
      'NORMAL': widget.product.skinType.contains('NORMAL'),
    };
    _ingredients = List.from(widget.product.ingredients);
    _usageTime = {
      'MORNING': widget.product.usageTime?.contains('MORNING') ?? false,
      'NIGHT': widget.product.usageTime?.contains('NIGHT') ?? false,
      'AFTERNOON': widget.product.usageTime?.contains('AFTERNOON') ?? false,
    };
  }

  Future<void> _updateProduct() async {
    try {
      final response = await http.put(
        Uri.parse('${widget.baseUrl}/product/product'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'productId': widget.product.productId,
          'name': _nameController.text,
          'skinType': _skinType.entries.where((entry) => entry.value).map((entry) => entry.key).toList(),
          'description': _descriptionController.text,
          'ingredients': _ingredients,
          'usageTime': _usageTime.entries.where((entry) => entry.value).map((entry) => entry.key).toList(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product updated successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update product')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error')),
      );
    }
  }

  void _addIngredient() async {
    final newIngredient = await showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: Text('Add Ingredient'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter ingredient'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );

    if (newIngredient != null && newIngredient.isNotEmpty) {
      setState(() {
        _ingredients.add(newIngredient);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.product.photos != null && widget.product.photos!.isNotEmpty)
            Image.network(
              widget.product.photos![0],
              fit: BoxFit.cover,
              height: 200,
              width: double.infinity,
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Product Name'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Skin Type:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: _skinType.entries.map((entry) {
                    return Expanded(
                      child: CheckboxListTile(
                        title: Text(entry.key),
                        value: entry.value,
                        onChanged: (value) {
                          setState(() {
                            _skinType[entry.key] = value ?? false;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                Text(
                  'Ingredients:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: _ingredients.map((ingredient) {
                    return Chip(
                      label: Text(ingredient),
                      onDeleted: () {
                        setState(() {
                          _ingredients.remove(ingredient);
                        });
                      },
                    );
                  }).toList(),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addIngredient,
                ),
                SizedBox(height: 16),
                Text(
                  'Usage Time:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: _usageTime.entries.map((entry) {
                    return Expanded(
                      child: CheckboxListTile(
                        title: Text(entry.key),
                        value: entry.value,
                        onChanged: (value) {
                          setState(() {
                            _usageTime[entry.key] = value ?? false;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _updateProduct,
                  child: Text('Update Product'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}