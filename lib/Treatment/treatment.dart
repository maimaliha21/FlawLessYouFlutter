import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:FlawlessYou/SharedPreferences.dart';
import '../CustomBottomNavigationBarAdmin.dart';
import '../Home_Section/search.dart';
import '../Product/product.dart';

void main() {
  runApp(MaterialApp(
    home: TreatmentPage(),
  ));
}

class TreatmentPage extends StatefulWidget {
  @override
  _TreatmentPageState createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  List<dynamic> treatments = [];
  List<dynamic> oilyTreatments = [];
  List<dynamic> normalTreatments = [];
  List<dynamic> dryTreatments = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchTreatments();
  }

  Future<void> fetchTreatments() async {
    try {
      final userData = await getUserData();
      final baseUrl = await getBaseUrl();

      if (userData == null || baseUrl == null) {
        throw Exception('User data or base URL is missing');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/treatments'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer ${userData['token']}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is List) {
          setState(() {
            treatments = responseData;
            oilyTreatments = treatments.where((treatment) => treatment['skinType'] == 'OILY').toList();
            normalTreatments = treatments.where((treatment) => treatment['skinType'] == 'NORMAL').toList();
            dryTreatments = treatments.where((treatment) => treatment['skinType'] == 'DRY').toList();
            isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load treatments: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading treatments: ${e.toString()}';
      });
      print('Error fetching treatments: $e');
    }
  }

  Future<void> createTreatment(Map<String, dynamic> treatmentData, List<dynamic> products) async {
    try {
      final userData = await getUserData();
      final baseUrl = await getBaseUrl();

      if (userData == null || baseUrl == null) {
        throw Exception('User data or base URL is missing');
      }

      final productIdsMap = {};
      for (final product in products) {
        final productId = product['productId']?.toString();
        if (productId != null) {
          productIdsMap[productId] = product['name'] ?? 'Unnamed Product';
        }
      }

      final requestBody = {
        'skinType': treatmentData['skinType'],
        'description': treatmentData['description'],
        'problem': treatmentData['problem'],
        'productIds': productIdsMap,
      };

      print('Sending request with body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/treatments'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer ${userData['token']}',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Treatment created successfully')),
        );
        await fetchTreatments();
      } else {
        throw Exception('Failed to create treatment: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create treatment: ${e.toString()}')),
      );
      print('Error creating treatment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: Text(errorMessage)),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Color(0xFF88A383),
          title: Text(
            'Skin Treatments',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            tabs: [
              Tab(
                text: 'Oily',
                icon: Icon(Icons.opacity),
              ),
              Tab(
                text: 'Normal',
                icon: Icon(Icons.balance),
              ),
              Tab(
                text: 'Dry',
                icon: Icon(Icons.water_drop),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TreatmentCategoryList(treatments: oilyTreatments),
            TreatmentCategoryList(treatments: normalTreatments),
            TreatmentCategoryList(treatments: dryTreatments),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigationBarAdmin(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateTreatmentPage(
                  createTreatment: createTreatment,
                ),
              ),
            );
          },
          child: Icon(Icons.add, color: Colors.white),
          backgroundColor: Color(0xFF88A383),
          elevation: 4,
        ),
      ),
    );
  }
}

class CreateTreatmentPage extends StatefulWidget {
  final Function(Map<String, dynamic>, List<dynamic>) createTreatment;

  const CreateTreatmentPage({
    Key? key,
    required this.createTreatment,
  }) : super(key: key);

  @override
  _CreateTreatmentPageState createState() => _CreateTreatmentPageState();
}

class _CreateTreatmentPageState extends State<CreateTreatmentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  String? _selectedSkinType;
  String? _selectedProblem;
  List<dynamic> _selectedProducts = [];

  final List<String> _skinTypes = ['OILY', 'NORMAL', 'DRY'];
  final List<String> _problems = ['ACNE', 'WRINKLES', 'PIGMENTATION','NORMAL'];

  Future<void> _addProducts() async {
    final selectedProducts = await Navigator.push<List<dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductSearchPage(
          onProductsSelected: (products) => products,
        ),
      ),
    );

    if (selectedProducts != null && selectedProducts.isNotEmpty) {
      setState(() {
        _selectedProducts = selectedProducts;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedSkinType == null || _selectedProblem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select both skin type and problem')),
        );
        return;
      }

      final treatmentData = {
        'description': _descriptionController.text,
        'skinType': _selectedSkinType,
        'problem': _selectedProblem,
      };

      widget.createTreatment(treatmentData, _selectedProducts);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Treatment', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF88A383),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Treatment Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF596D56),
                        ),
                      ),
                      SizedBox(height: 20),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                        maxLines: 3,
                      ),
                      SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value: _selectedSkinType,
                        decoration: InputDecoration(
                          labelText: 'Skin Type',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: _skinTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSkinType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select skin type';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value: _selectedProblem,
                        decoration: InputDecoration(
                          labelText: 'Problem',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: _problems.map((problem) {
                          return DropdownMenuItem<String>(
                            value: problem,
                            child: Text(problem),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProblem = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select problem';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF596D56),
                        ),
                      ),
                      SizedBox(height: 10),

                      _selectedProducts.isEmpty
                          ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No products selected',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                          : Column(
                        children: _selectedProducts.map((product) {
                          return ListTile(
                            leading: product['photos'] != null && product['photos'].isNotEmpty
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product['photos'][0],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                                : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.image, size: 30, color: Colors.grey),
                            ),
                            title: Text(product['name'] ?? 'Unknown Product'),
                            subtitle: Text(product['productId']?.toString() ?? ''),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _selectedProducts.removeWhere(
                                          (p) => p['productId'] == product['productId']);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: 10),

                      Center(
                        child: ElevatedButton(
                          onPressed: _addProducts,
                          child: Text('Add Products'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF88A383),
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),

              ElevatedButton(
                onPressed: _submitForm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Create Treatment',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF596D56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductSearchPage extends StatefulWidget {
  final Function(List<dynamic>) onProductsSelected;

  const ProductSearchPage({
    Key? key,
    required this.onProductsSelected,
  }) : super(key: key);

  @override
  _ProductSearchPageState createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  List<dynamic> _selectedProducts = [];

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await getUserData();
      final baseUrl = await getBaseUrl();

      if (userData == null || baseUrl == null) {
        throw Exception('User data or base URL is missing');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/product/search?name=$query'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer ${userData['token']}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is List) {
          setState(() {
            _searchResults = responseData.map((item) {
              return item['product'] ?? item;
            }).toList();
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching products: ${e.toString()}')),
      );
      print('Error searching products: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleProductSelection(dynamic product) {
    setState(() {
      final productId = product['productId'];
      if (productId == null) return;

      if (_selectedProducts.any((p) => p['productId'] == productId)) {
        _selectedProducts.removeWhere((p) => p['productId'] == productId);
      } else {
        _selectedProducts.add({
          'productId': productId,
          'name': product['name'],
          'photos': product['photos'],
        });
      }
    });
  }

  void _submitSelectedProducts() {
    if (_selectedProducts.isNotEmpty) {
      Navigator.pop(context, _selectedProducts);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one product')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Products', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF88A383),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search, color: Color(0xFF88A383)),
                      onPressed: () => _searchProducts(_searchController.text),
                    ),
                  ),
                  onSubmitted: (value) => _searchProducts(value),
                ),
              ),
            ),
          ),

          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Expanded(
            child: _searchResults.isEmpty
                ? Center(
              child: Text(
                'No products found',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final product = _searchResults[index];
                final productId = product['productId'];
                final isSelected = _selectedProducts.any(
                        (p) => p['productId'] == productId);

                return Card(
                  margin: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: product['photos'] != null &&
                        product['photos'].isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product['photos'][0],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.image,
                          size: 30, color: Colors.grey),
                    ),
                    title: Text(product['name'] ?? 'Unknown Product'),
                    subtitle: Text(productId?.toString() ?? ''),
                    trailing: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: isSelected ? Color(0xFF88A383) : null,
                    ),
                    onTap: () => _toggleProductSelection(product),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitSelectedProducts,
        child: Icon(Icons.check, color: Colors.white),
        backgroundColor: Color(0xFF88A383),
        elevation: 4,
      ),
    );
  }
}

class TreatmentCategoryList extends StatelessWidget {
  final List<dynamic> treatments;

  TreatmentCategoryList({required this.treatments});

  Map<String, List<dynamic>> categorizeTreatments(List<dynamic> treatments) {
    Map<String, List<dynamic>> categorized = {
      'ACNE': [],
      'WRINKLES': [],
      'PIGMENTATION': [],
      'NORMAL': [],
    };

    for (var treatment in treatments) {
      if (categorized.containsKey(treatment['problem'])) {
        categorized[treatment['problem']]!.add(treatment);
      }
    }

    return categorized;
  }

  @override
  Widget build(BuildContext context) {
    final categorizedTreatments = categorizeTreatments(treatments);

    return ListView(
      padding: EdgeInsets.all(12),
      children: categorizedTreatments.entries.map((entry) {
        if (entry.value.isEmpty) return SizedBox();

        return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        ),
        child: ExpansionTile(
        title: Text(
        entry.key,
        style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF596D56),
        ),
        ),
        children: entry.value.map((treatment) {
        return _buildTreatmentCard(context, treatment);
        }).toList(),
        ),

        );
      }).toList(),
    );
  }

  Widget _buildTreatmentCard(BuildContext context, dynamic treatment) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TreatmentDetailsPage(treatment: treatment),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
        BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        spreadRadius: 1,
        blurRadius: 3,
        offset: Offset(0, 2),
        ),  ],

      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            treatment['description'] ?? 'No Description',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.face_retouching_natural, size: 16, color: Colors.grey),
              SizedBox(width: 3),
              Text(
                'Skin: ${treatment['skinType']}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(width: 16),
              Icon(Icons.medical_services, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                'Problem: ${treatment['problem']}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class TreatmentDetailsPage extends StatefulWidget {
  final dynamic treatment;

  TreatmentDetailsPage({required this.treatment});

  @override
  _TreatmentDetailsPageState createState() => _TreatmentDetailsPageState();
}

class _TreatmentDetailsPageState extends State<TreatmentDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController searchController = TextEditingController();
  late Future<String> _baseUrlFuture;
  late TextEditingController _descriptionController;
  late String _selectedSkinType;
  late String _selectedProblem;
  bool _isEditing = false;
  bool _isLoading = false;

  final List<String> _skinTypes = ['OILY', 'NORMAL', 'DRY'];
  final List<String> _problems = ['ACNE', 'WRINKLES', 'PIGMENTATION', 'NORMAL'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _baseUrlFuture = getBaseUrl();
    _descriptionController = TextEditingController(text: widget.treatment['description']);
    _selectedSkinType = widget.treatment['skinType'];
    _selectedProblem = widget.treatment['problem'];
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateTreatment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await getUserData();
      final baseUrl = await getBaseUrl();

      if (userData == null || baseUrl == null) {
        throw Exception('User data or base URL is missing');
      }

      final requestBody = {
        'skinType': _selectedSkinType,
        'description': _descriptionController.text,
        'problem': _selectedProblem,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/api/treatments/${widget.treatment['treatmentId']}'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer ${userData['token']}',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Treatment updated successfully')),
        );

        setState(() {
          _isEditing = false;
          widget.treatment['description'] = _descriptionController.text;
          widget.treatment['skinType'] = _selectedSkinType;
          widget.treatment['problem'] = _selectedProblem;
        });
      } else {
        throw Exception('Failed to update treatment: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating treatment: ${e.toString()}')),
      );
      setState(() {
        _descriptionController.text = widget.treatment['description'];
        _selectedSkinType = widget.treatment['skinType'];
        _selectedProblem = widget.treatment['problem'];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTreatment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this treatment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await getUserData();
      final baseUrl = await getBaseUrl();

      if (userData == null || baseUrl == null) {
        throw Exception('User data or base URL is missing');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/treatments/${widget.treatment['treatmentId']}'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${userData['token']}',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Treatment deleted successfully')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to delete treatment: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting treatment: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Treatment Details', style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        )),
        backgroundColor: Color(0xFF88A383),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[200]),
              onPressed: _isLoading ? null : _deleteTreatment,
            ),
          ],
          if (_isEditing) ...[
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: _resetEditing,
            ),
            IconButton(
              icon: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Icon(Icons.check, color: Colors.white),
              onPressed: _isLoading ? null : _updateTreatment,
            ),
          ],
        ],
      ),
      body: FutureBuilder<String>(
        future: _baseUrlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final baseUrl = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Treatment Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF596D56),
                      ),
                    ),
                    SizedBox(height: 20),

                    _buildInfoField(
                      label: 'Description',
                      value: widget.treatment['description'],
                      isEditing: _isEditing,
                      controller: _descriptionController,
                      isMultiline: true,
                    ),

                    SizedBox(height: 15),

                    _buildInfoField(
                      label: 'Problem',
                      value: widget.treatment['problem'],
                      isEditing: _isEditing,
                      isDropdown: true,
                      items: _problems,
                      selectedValue: _selectedProblem,
                      onChanged: (value) => setState(() => _selectedProblem = value!),
                    ),

                    SizedBox(height: 15),

                    _buildInfoField(
                      label: 'Skin Type',
                      value: widget.treatment['skinType'],
                      isEditing: _isEditing,
                      isDropdown: true,
                      items: _skinTypes,
                      selectedValue: _selectedSkinType,
                      onChanged: (value) => setState(() => _selectedSkinType = value!),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 25),

            Text(
              'Treatment Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF596D56),
              ),
              ),
              SizedBox(height: 10),

              Container(
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: ProductTabScreen(
                    apiUrl: "$baseUrl/api/treatments/${widget.treatment['treatmentId']}/products",
                    pageName: 'treatment',
                    treatmentId: widget.treatment['treatmentId'],
                  ),
                ),
                ),

              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSearchPage(context),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFF88A383),
        elevation: 4,
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required bool isEditing,
    TextEditingController? controller,
    bool isMultiline = false,
    bool isDropdown = false,
    List<String>? items,
    String? selectedValue,
    ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 5),

        if (!isEditing && !isDropdown)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),

        if (!isEditing && isDropdown)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              selectedValue ?? value,
              style: TextStyle(fontSize: 16),
            ),
          ),

        if (isEditing && !isDropdown)
          TextFormField(
            controller: controller,
            maxLines: isMultiline ? 3 : 1,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: EdgeInsets.all(12),
            ),
          ),

        if (isEditing && isDropdown)
          DropdownButtonFormField<String>(
            value: selectedValue,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            items: items!.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
      ],
    );
  }

  void _resetEditing() {
    setState(() {
      _isEditing = false;
      _descriptionController.text = widget.treatment['description'];
      _selectedSkinType = widget.treatment['skinType'];
      _selectedProblem = widget.treatment['problem'];
    });
  }

  void _openSearchPage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search products',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: Color(0xFF88A383)),
                    onPressed: () {
                      if (searchController.text.isNotEmpty) {
                        Navigator.pop(context);
                        _navigateToSearch(context, searchController.text);
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF596D56)),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _navigateToSearch(BuildContext context, String query) async {
    try {
      final userData = await getUserData();
      if (userData == null) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => search(
            token: userData['token'],
            searchQuery: query,
            pageName: 'add',
            treatmentId: widget.treatment['treatmentId'],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}