import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
class Product {
  final String productId;
  final String? name;
  final List<String> skinType;
  final List<String> ingredients;
  final String? description;
  final String? smallDescription;
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
    this.smallDescription,
    required this.rating,
    this.photos,
    this.usageTime,
    this.isSaved = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final productData = json['product'] ?? json;

    double avgRating = 0.0;
    final reviews = productData['reviews'];
    if (reviews != null && reviews is Map<String, dynamic>) {
      final ratings = reviews.values.whereType<int>().toList();
      if (ratings.isNotEmpty) {
        avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
      }
    }

    List<String>? photos;
    if (productData['photos'] is List) {
      photos = List<String>.from(productData['photos']);
    }

    List<String>? usageTime;
    if (productData['usageTime'] is List) {
      usageTime = List<String>.from(productData['usageTime']);
    }

    return Product(
      productId: productData['productId'] as String? ?? 'unknown',
      name: productData['name'] as String?,
      skinType: List<String>.from(productData['skinType'] ?? []),
      ingredients: List<String>.from(productData['ingredients'] ?? []),
      description: productData['description'] as String?,
      smallDescription: productData['smaledescription'] as String?,
      rating: avgRating,
      photos: photos,
      usageTime: usageTime,
      isSaved: json['saved'] is bool ? json['saved'] : false,
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
  bool _isLoadingMore = false;
  String? _baseUrl;
  List<Product> _products = [];
  int _currentPage = 0;
  bool _hasMore = true;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadBaseUrl();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    try {
      final newProducts = await _fetchProducts();

      final existingIds = _products.map((p) => p.productId).toSet();

      final filteredNewProducts = newProducts.where(
              (product) => !existingIds.contains(product.productId)
      ).toList();

      setState(() {
        _products.addAll(filteredNewProducts);
        _hasMore = newProducts.isNotEmpty;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more products')),
      );
    }
  }

  Future<List<Product>> _fetchProducts() async {
    if (token == null) throw Exception('Token is not available');

    final Uri uri = Uri.parse(widget.apiUrl);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final decodedBody = jsonDecode(response.body);
        List<Product> products = [];

        if (decodedBody is List) {
          products = decodedBody.map((json) => Product.fromJson(json)).toList();
        } else if (decodedBody['products'] is List) {
          products = List<Product>.from(
              decodedBody['products'].map((x) => Product.fromJson(x)));
        } else {
          throw Exception('Invalid response format');
        }

        final uniqueProducts = <String, Product>{};
        for (var product in products) {
          uniqueProducts[product.productId] = product;
        }

        return uniqueProducts.values.toList();
      } catch (e) {
        throw Exception('Failed to parse response: $e');
      }
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userInfoString = prefs.getString('userInfo');
    Map<String, dynamic> userInfoMap = json.decode(userInfoString ?? '{}');

    setState(() {
      token = prefs.getString('token');
      userRole = userInfoMap['role'];
    });
    await _refreshProducts();
  }

  Future<void> _loadBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseUrl = prefs.getString('baseUrl') ?? 'http://localhost:8080';
    });
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _products = [];
      _hasMore = true;
    });

    try {
      final products = await _fetchProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load products: $e')),
      );
    }
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: AddProductPopup(
            token: token!,
            baseUrl: _baseUrl!,
            onProductAdded: _refreshProducts,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      floatingActionButton: userRole == 'ADMIN'
          ? FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      )
          : null,
      body: _isLoading && _products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refreshProducts,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return ProductCard(
                      product: _products[index],
                      token: token!,
                      userRole: userRole!,
                      baseUrl: _baseUrl!,
                      pageName: widget.pageName,
                      treatmentId: widget.treatmentId,
                      onDelete: _refreshProducts,
                    );
                  },
                  childCount: _products.length,
                ),
              ),
            ),
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            if (!_hasMore && _products.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No more products')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class AddProductPopup extends StatefulWidget {
  final String token;
  final String baseUrl;
  final VoidCallback onProductAdded;

  const AddProductPopup({
    Key? key,
    required this.token,
    required this.baseUrl,
    required this.onProductAdded,
  }) : super(key: key);

  @override
  _AddProductPopupState createState() => _AddProductPopupState();
}

class _AddProductPopupState extends State<AddProductPopup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _smallDescriptionController = TextEditingController();

  List<String> _ingredients = [];
  final TextEditingController _ingredientController = TextEditingController();

  String? _selectedSkinType;
  final List<String> _skinTypes = ['OILY', 'DRY', 'NORMAL'];

  List<String> _selectedUsageTimes = [];
  final List<String> _usageTimeOptions = ['MORNING', 'AFTERNOON', 'NIGHT'];

  List<File> _selectedImages = [];
  bool _isUploading = false;
  String? _newProductId;

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage(
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFiles != null) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
    }
  }

  Future<void> _uploadImages(String productId) async {
    if (_selectedImages.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.baseUrl}/product/$productId/photos'),
      );

      request.headers['Authorization'] = 'Bearer ${widget.token}';

      for (var image in _selectedImages) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            image.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Images uploaded successfully')),
        );
      } else {
        throw Exception('Failed to upload images: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading images: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      // First create the product
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/product'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'skinType': _selectedSkinType != null ? [_selectedSkinType!] : [],
          'description': _descriptionController.text,
          'smaledescription': _smallDescriptionController.text,
          'ingredients': _ingredients,
          'usageTime': _selectedUsageTimes,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _newProductId = responseData['productId'];

        // Then upload images if any
        if (_selectedImages.isNotEmpty) {
          await _uploadImages(_newProductId!);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product added successfully')),
        );
        widget.onProductAdded();
        Navigator.of(context).pop();
      } else {
        throw Exception('Failed to add product: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _addIngredient() {
    if (_ingredientController.text.isNotEmpty) {
      setState(() {
        _ingredients.add(_ingredientController.text);
        _ingredientController.clear();
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _toggleUsageTime(String time) {
    setState(() {
      if (_selectedUsageTimes.contains(time)) {
        _selectedUsageTimes.remove(time);
      } else {
        _selectedUsageTimes.add(time);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Product',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Product Images Section
            Text('Product Images', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),

            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () => _removeImage(index),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: Icon(Icons.photo_library),
              label: Text('Add Images'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 16),

            // Product Details Section
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedSkinType,
              decoration: InputDecoration(
                labelText: 'Skin Type',
                border: OutlineInputBorder(),
              ),
              items: _skinTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSkinType = value;
                });
              },
              validator: (value) => value == null ? 'Required' : null,
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _smallDescriptionController,
              decoration: InputDecoration(
                labelText: 'Small Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            SizedBox(height: 16),

            // Ingredients Section
            Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ingredientController,
                    decoration: InputDecoration(
                      labelText: 'Add Ingredient',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addIngredient,
                ),
              ],
            ),

            if (_ingredients.isNotEmpty) ...[
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(_ingredients.length, (index) {
                  return Chip(
                    label: Text(_ingredients[index]),
                    onDeleted: () => _removeIngredient(index),
                  );
                }),
              ),
            ],
            SizedBox(height: 16),

            // Usage Time Section
            Text('Usage Time', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: _usageTimeOptions.map((time) {
                return FilterChip(
                  label: Text(time),
                  selected: _selectedUsageTimes.contains(time),
                  onSelected: (selected) => _toggleUsageTime(time),
                );
              }).toList(),
            ),
            SizedBox(height: 24),

            // Submit Button
            Center(
              child: _isUploading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _addProduct,
                child: Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50),
                ),
              ),
            ),
          ],
        ),
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
      final response = await (newState
          ? http.post(
        Uri.parse('${widget.baseUrl}/product/${widget.product.productId}/savedProduct'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      )
          : http.post(
        Uri.parse('${widget.baseUrl}/product/${widget.product.productId}/savedProduct'),
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
          SnackBar(content: Text('${widget.baseUrl}/api/treatments/${widget.treatmentId}/products/${widget.product.productId}')),
          // SnackBar(content: Text('Failed to add product to treatment')),
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

// باقي الأكواد (ProductDetailsPopup, EditProductPopup, CustomBottomNavigationBar, BottomWaveClipper) تبقى كما هي.
// باقي الأكواد (ProductDetailsPopup, EditProductPopup, CustomBottomNavigationBar, BottomWaveClipper) تبقى كما هي.
class ProductDetailsPopup extends StatefulWidget {
  final Product product;
  final String token;
  final String baseUrl;
  final String? treatmentId; // إضافة treatmentId هنا

  const ProductDetailsPopup({
    Key? key,
    required this.product,
    required this.token,
    required this.baseUrl,
    this.treatmentId, // إضافة treatmentId هنا
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
  const EditProductPopup({Key? key, required this.product, required this.token,required this.baseUrl}) : super(key: key);

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
        Uri.parse('http://localhost:8080/product/product'),
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