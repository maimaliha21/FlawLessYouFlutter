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
          'accept': '*/*',
          'Authorization': 'Bearer ${userData['token']}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          treatments = json.decode(response.body);
          oilyTreatments = treatments.where((treatment) => treatment['skinType'] == 'OILY').toList();
          normalTreatments = treatments.where((treatment) => treatment['skinType'] == 'NORMAL').toList();
          dryTreatments = treatments.where((treatment) => treatment['skinType'] == 'DRY').toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load treatments');
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

      // 1. Create the treatment first
      final response = await http.post(
        Uri.parse('$baseUrl/api/treatments'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${userData['token']}',
          'Content-Type': 'application/json',
        },
        body: json.encode(treatmentData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newTreatment = json.decode(response.body);
        final treatmentId = newTreatment['treatmentId'];

        // 2. Add products to the treatment
        for (final product in products) {
          await http.post(
            Uri.parse('$baseUrl/api/treatments/$treatmentId/products/${product['id']}/${product['name']}'),
            headers: {
              'accept': '*/*',
              'Authorization': 'Bearer ${userData['token']}',
            },
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إنشاء العلاج بنجاح')),
        );
        await fetchTreatments(); // Refresh the list
      } else {
        throw Exception('Failed to create treatment: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إنشاء العلاج: ${e.toString()}')),
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          bottom: TabBar(
            indicatorColor: Color(0xFF596D56),
            labelStyle: TextStyle(color: Color(0xFF596D56)),
            tabs: [
              Tab(
                text: 'Oily',
                icon: Icon(Icons.opacity, color: Colors.white),
              ),
              Tab(
                text: 'Normal',
                icon: Icon(Icons.balance, color: Colors.white),
              ),
              Tab(
                text: 'Dry',
                icon: Icon(Icons.water_drop, color: Colors.white),
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
          child: Icon(Icons.add, color: Colors.black),
          backgroundColor: Color(0xFFFFFDA),
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
  final List<String> _problems = ['ACNE', 'WRINKLES', 'PIGMENTATION'];

  Future<void> _addProducts() async {
    final selectedProducts = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductSearchPage(
          treatmentId: null,
          onProductSelected: (product) => product,
        ),
      ),
    );

    if (selectedProducts != null && selectedProducts is List) {
      setState(() {
        _selectedProducts = List<dynamic>.from(selectedProducts);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final treatmentData = {
        'description': _descriptionController.text,
        'details': _detailsController.text,
        'skinType': _selectedSkinType,
        'problem': _selectedProblem,
      };

      widget.createTreatment(treatmentData, _selectedProducts);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Treatment'),
        backgroundColor: Color(0xFF88A383),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
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

              TextFormField(
                controller: _detailsController,
                decoration: InputDecoration(
                  labelText: 'Details (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedSkinType,
                decoration: InputDecoration(
                  labelText: 'Skin Type',
                  border: OutlineInputBorder(),
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
              SizedBox(height: 20),

              Text('Selected Products:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),

              _selectedProducts.isEmpty
                  ? Text('No products selected')
                  : Wrap(
                spacing: 8,
                children: _selectedProducts.map((product) {
                  return Chip(
                    label: Text(product['name']),
                    onDeleted: () {
                      setState(() {
                        _selectedProducts.removeWhere((p) => p['id'] == product['id']);
                      });
                    },
                  );
                }).toList(),
              ),

              SizedBox(height: 16),

              ElevatedButton(
                onPressed: _addProducts,
                child: Text('Add Products'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF88A383),
                ),
              ),

              SizedBox(height: 30),

              ElevatedButton(
                onPressed: _submitForm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Create Treatment', style: TextStyle(fontSize: 18)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF596D56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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

class ProductSearchPage extends StatefulWidget {
  final String? treatmentId;
  final Function(dynamic) onProductSelected;

  const ProductSearchPage({
    Key? key,
    this.treatmentId,
    required this.onProductSelected,
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
    if (query.isEmpty) return;

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
        Uri.parse('$baseUrl/api/products/search?query=$query'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${userData['token']}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to search products');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching products: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addProductToTreatment(dynamic product) async {
    if (widget.treatmentId == null) {
      // For new treatment - just add to selected list
      setState(() {
        if (!_selectedProducts.any((p) => p['id'] == product['id'])) {
          _selectedProducts.add({
            'id': product['id'],
            'name': product['name'],
          });
        }
      });
      return;
    }

    try {
      final userData = await getUserData();
      final baseUrl = await getBaseUrl();

      if (userData == null || baseUrl == null) {
        throw Exception('User data or base URL is missing');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/treatments/${widget.treatmentId}/products/${product['id']}/${Uri.encodeComponent(product['name'])}'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${userData['token']}',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة المنتج بنجاح')),
        );
        setState(() {
          _selectedProducts.add({
            'id': product['id'],
            'name': product['name'],
          });
        });
      } else {
        throw Exception('Failed to add product: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إضافة المنتج: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Products'),
        backgroundColor: Color(0xFF88A383),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search products',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchProducts(_searchController.text),
                ),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => _searchProducts(value),
            ),
          ),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final product = _searchResults[index];
                final isSelected = _selectedProducts.any((p) => p['id'] == product['id']);

                return ListTile(
                  title: Text(product['name']),
                  trailing: IconButton(
                    icon: Icon(
                      isSelected ? Icons.check : Icons.add,
                      color: isSelected ? Colors.green : null,
                    ),
                    onPressed: () => _addProductToTreatment(product),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedProducts.isNotEmpty
          ? FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, _selectedProducts);
        },
        child: Icon(Icons.check),
        backgroundColor: Colors.green,
      )
          : null,
    );
  }
}

// باقي الأكواد الأخرى (TreatmentCategoryList, TreatmentDetailsPage) تبقى كما هي بدون تغيير
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
        return ExpansionTile(
          title: Text(
            entry.key,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF596D56)),
          ),
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.6,
              child: ListView(
                padding: EdgeInsets.all(8),
                children: entry.value.length > 4
                    ? [
                  ...entry.value.take(4).map((treatment) {
                    return _buildTreatmentCard(context, treatment);
                  }).toList(),
                  _buildViewMoreCard(context, entry.value[4]),
                ]
                    : entry.value.map((treatment) {
                  return _buildTreatmentCard(context, treatment);
                }).toList(),
              ),
            ),
          ],
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
        margin: EdgeInsets.symmetric(vertical: 6),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              treatment['description'] ?? 'No Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF596D56)),
            ),
            SizedBox(height: 8),
            Text(
              'Problem: ${treatment['problem']}',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewMoreCard(BuildContext context, dynamic treatment) {
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
        margin: EdgeInsets.symmetric(vertical: 6),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'View More',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF596D56)),
          ),
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

class _TreatmentDetailsPageState extends State<TreatmentDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController searchController = TextEditingController();
  late Future<String> _baseUrlFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _baseUrlFuture = getBaseUrl();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Treatment Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF88A383),
        iconTheme: IconThemeData(color: Colors.black),
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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.treatment['description'] ?? 'No Description',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF596D56)),
                ),
                SizedBox(height: 16),
                Text(
                  'Problem: ${widget.treatment['problem']}',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
                SizedBox(height: 16),
                Text(
                  'Details: ${widget.treatment['details'] ?? 'No details available'}',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
                SizedBox(height: 16),
                Text(
                  'Skin Type: ${widget.treatment['skinType']}',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
                SizedBox(height: 20),
                Text(
                  'Treatment Products',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ProductTabScreen(
                        apiUrl: "$baseUrl/api/treatments/${widget.treatment['treatmentId']}/products",
                        pageName: 'treatment',
                        treatmentId: widget.treatment['treatmentId'],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSearchPage(context),
        child: Icon(Icons.add, color: Colors.black),
        backgroundColor: Color(0xFFFFFDA),
      ),
    );
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