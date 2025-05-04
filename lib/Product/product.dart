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
  List<String>? photos;
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
      floatingActionButton: userRole == 'ADMIN' && widget.pageName == 'home'
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
          Uri.parse(
              '${widget.baseUrl}/api/treatments/${widget.treatmentId}/products/${widget.product.productId}/${Uri.encodeComponent(widget.product.name!)}'
          ),
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
            SnackBar(content: Text('Failed to add product to treatment. Status code: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
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
                onProductDeleted: widget.onDelete,
              ),
            );
          },
        ).then((shouldRefresh) {
          if (shouldRefresh == true) {
            widget.onDelete(); // Refresh the product list
          }
        });
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
    final VoidCallback? onProductDeleted;
  
    const EditProductPopup({
      Key? key,
      required this.product,
      required this.token,
      required this.baseUrl,
      this.onProductDeleted,
    }) : super(key: key);
  
    @override
    _EditProductPopupState createState() => _EditProductPopupState();
  }
  
  class _EditProductPopupState extends State<EditProductPopup> {
    late TextEditingController _nameController;
    late TextEditingController _descriptionController;
    late TextEditingController _smallDescriptionController;
    late Map<String, bool> _skinType;
    late List<String> _ingredients;
    late Map<String, bool> _usageTime;
    List<File> _newImages = [];
    List<String> _deletedImageUrls = [];
    bool _isLoading = false;
    bool _isDeleting = false;
  
    @override
    void initState() {
      super.initState();
      _nameController = TextEditingController(text: widget.product.name);
      _descriptionController = TextEditingController(text: widget.product.description);
      _smallDescriptionController = TextEditingController(text: widget.product.smallDescription);
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
      setState(() => _isLoading = true);
  
      try {
        // Step 1: Update product details
        final detailsResponse = await http.put(
          Uri.parse('${widget.baseUrl}/product/product'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'productId': widget.product.productId,
            'name': _nameController.text,
            'skinType': _skinType.entries.where((e) => e.value).map((e) => e.key).toList(),
            'description': _descriptionController.text,
            'smaledescription': _smallDescriptionController.text,
            'ingredients': _ingredients,
            'usageTime': _usageTime.entries.where((e) => e.value).map((e) => e.key).toList(),
          }),
        );
  
        if (detailsResponse.statusCode == 200) {
          // Step 2: Delete marked images
          if (_deletedImageUrls.isNotEmpty) {
            final deleteResponse = await http.post(
              Uri.parse('${widget.baseUrl}/product/${widget.product.productId}/deletePhotos'),
              headers: {
                'Authorization': 'Bearer ${widget.token}',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'photoUrls': _deletedImageUrls}),
            );
  
            if (deleteResponse.statusCode != 200) {
              throw Exception('Failed to delete images');
            }
          }
  
          // Step 3: Upload new images
          if (_newImages.isNotEmpty) {
            var request = http.MultipartRequest(
              'POST',
              Uri.parse('${widget.baseUrl}/product/${widget.product.productId}/photos'),
            );
  
            request.headers['Authorization'] = 'Bearer ${widget.token}';
  
            for (var image in _newImages) {
              request.files.add(
                await http.MultipartFile.fromPath(
                  'files',
                  image.path,
                  contentType: MediaType('image', 'jpeg'),
                ),
              );
            }
  
            var response = await request.send();
            if (response.statusCode != 200) {
              throw Exception('Failed to upload images');
            }
          }
  
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product updated successfully')),
          );
          Navigator.of(context).pop(true);
        } else {
          throw Exception('Failed to update product details');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  
    Future<void> _deleteProduct() async {
      setState(() => _isDeleting = true);
  
      try {
        final response = await http.delete(
          Uri.parse('${widget.baseUrl}/product/${widget.product.productId}'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'accept': '*/*',
          },
        );
  
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product deleted successfully')),
          );
  
          // إغلاق النافذة وإرسال إشارة أن المنتج تم حذفه
          Navigator.of(context).pop(true);
  
          // استدعاء callback إذا كان موجوداً
          if (widget.onProductDeleted != null) {
            widget.onProductDeleted!();
          }
        } else {
          throw Exception('Failed to delete product: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      } finally {
        setState(() => _isDeleting = false);
      }
    }
  
    void _confirmDelete() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this product? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteProduct();
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }
  
    Future<void> _pickImages() async {
      final pickedFiles = await ImagePicker().pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
  
      if (pickedFiles != null) {
        setState(() {
          _newImages.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    }
  
    void _addIngredient() async {
      final newIngredient = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Add Ingredient'),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: 'Enter ingredient name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final controller = (context as Element).findAncestorWidgetOfExactType<TextField>()?.controller as TextEditingController?;
                Navigator.pop(context, controller?.text ?? '');
              },
              child: Text('Add'),
            ),
          ],
        ),
      );
  
      if (newIngredient != null && newIngredient.isNotEmpty) {
        setState(() => _ingredients.add(newIngredient));
      }
    }
  
    Future<void> _deleteImageByIndex(int index) async {
      try {
        final response = await http.delete(
          Uri.parse('${widget.baseUrl}/product/${widget.product.productId}/photos/$index'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
          },
        );
  
        if (response.statusCode == 200) {
          setState(() {
            widget.product.photos!.removeAt(index);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete image')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting image: $e')),
        );
      }
    }

    Future<void> _addNewImages(BuildContext context) async {
      final pickedFiles = await ImagePicker().pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = true);

        try {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse('${widget.baseUrl}/product/${widget.product.productId}/photos'),
          );

          request.headers['Authorization'] = 'Bearer ${widget.token}';

          for (var pickedFile in pickedFiles) {
            final file = File(pickedFile.path);
            request.files.add(
              await http.MultipartFile.fromPath(
                'files',
                file.path,
                contentType: MediaType('image', 'jpeg'),
              ),
            );
          }

          var response = await request.send();
          final responseBody = await response.stream.bytesToString();

          if (response.statusCode == 200) {
            // Parse the updated product data
            final updatedProduct = Product.fromJson(json.decode(responseBody));

            // Update the product photos in the widget
            if (!mounted) return;
            setState(() {
              widget.product.photos = updatedProduct.photos ?? widget.product.photos;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Images added successfully')),
            );
          } else {
            throw Exception('Failed to upload images: ${response.statusCode}');
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding images: $e')),
          );
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      }
    }
    @override
    Widget build(BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Product',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 24),
  
                // Product Images Section
                _buildSectionHeader('Product Images'),
                SizedBox(height: 8),
  
                if (widget.product.photos?.isEmpty ?? true)
                  Text('No images available', style: TextStyle(color: Colors.grey)),
  
                if (widget.product.photos?.isNotEmpty ?? false)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.product.photos!.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.product.photos![index],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _deleteImageByIndex(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
  
                SizedBox(height: 16),

                Builder(
                  builder: (innerContext) {
                    return ElevatedButton.icon(
                      onPressed: () => _addNewImages(innerContext),
                      icon: Icon(Icons.add_photo_alternate),
                      label: Text('Add Images'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    );
                  },
                ),


                SizedBox(height: 24),
  
                // Product Details Section
                _buildSectionHeader('Product Details'),
                SizedBox(height: 16),
  
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                ),
  
                SizedBox(height: 16),
  
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
  
                SizedBox(height: 16),
  
                TextFormField(
                  controller: _smallDescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Short Description',
                    border: OutlineInputBorder(),
                  ),
                ),
  
                SizedBox(height: 24),
  
                // Skin Type Section
                _buildSectionHeader('Skin Type'),
                SizedBox(height: 8),
  
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skinType.entries.map((e) => ChoiceChip(
                    label: Text(e.key),
                    selected: e.value,
                    onSelected: (v) => setState(() => _skinType[e.key] = v),
                  )).toList(),
                ),
  
                SizedBox(height: 24),
  
                // Ingredients Section
                _buildSectionHeader('Ingredients'),
                SizedBox(height: 8),
  
                if (_ingredients.isEmpty)
                  Text('No ingredients added', style: TextStyle(color: Colors.grey)),
  
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ingredients.map((ingredient) => Chip(
                    label: Text(ingredient),
                    deleteIcon: Icon(Icons.close, size: 18),
                    onDeleted: () => setState(() => _ingredients.remove(ingredient)),
                  )).toList(),
                ),
  
                TextButton.icon(
                  onPressed: _addIngredient,
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Add Ingredient'),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                  ),
                ),
  
                SizedBox(height: 24),
  
                // Usage Time Section
                _buildSectionHeader('Usage Time'),
                SizedBox(height: 8),
  
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _usageTime.entries.map((e) => ChoiceChip(
                    label: Text(e.key),
                    selected: e.value,
                    onSelected: (v) => setState(() => _usageTime[e.key] = v),
                  )).toList(),
                ),
  
                SizedBox(height: 32),
  
                // Update Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateProduct,
                  child: _isLoading
                      ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text('Update Product'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
  
                SizedBox(height: 16),
  
                // Delete Button
                ElevatedButton(
                  onPressed: _isDeleting ? null : _confirmDelete,
                  child: _isDeleting
                      ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    'Delete Product',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  
    Widget _buildSectionHeader(String title) {
      return Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      );
    }
  }