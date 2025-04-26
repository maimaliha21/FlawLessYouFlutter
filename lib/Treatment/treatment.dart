import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:FlawlessYou/SharedPreferences.dart';
import '../CustomBottomNavigationBarAdmin.dart';
import '../Product/product.dart';

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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (!await _checkInternetConnection()) {
        throw Exception('No internet connection');
      }
      await fetchTreatments();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = _getUserFriendlyError(e);
      });
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  String _getUserFriendlyError(dynamic e) {
    if (e.toString().contains('Null is not a subtype')) {
      return 'Missing required data from server';
    } else if (e.toString().contains('FormatException')) {
      return 'Data format error. Please try again';
    } else if (e.toString().contains('No internet')) {
      return 'No internet connection';
    }
    return 'Error loading data: ${e.toString()}';
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
        final data = jsonDecode(response.body);
        if (data == null) throw Exception('Null data received');

        setState(() {
          treatments = data;
          oilyTreatments = treatments.where((t) => t['skinType'] == 'OILY').toList();
          normalTreatments = treatments.where((t) => t['skinType'] == 'NORMAL').toList();
          dryTreatments = treatments.where((t) => t['skinType'] == 'DRY').toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load treatments: ${response.statusCode}');
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> createTreatment(Map<String, dynamic> treatmentData, List<dynamic> products) async {
    try {
      if (!await _checkInternetConnection()) {
        throw Exception('No internet connection');
      }

      if (treatmentData['description'] == null ||
          treatmentData['skinType'] == null ||
          treatmentData['problem'] == null) {
        throw Exception('Required fields are missing');
      }

      final userData = await getUserData();
      final baseUrl = await getBaseUrl();

      if (userData == null || baseUrl == null) {
        throw Exception('User data or base URL is missing');
      }

      final treatmentResponse = await http.post(
        Uri.parse('$baseUrl/api/treatments'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${userData['token']}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'description': treatmentData['description'],
          'details': treatmentData['details'] ?? '',
          'skinType': treatmentData['skinType'],
          'problem': treatmentData['problem'],
        }),
      );

      if (treatmentResponse.statusCode == 200 || treatmentResponse.statusCode == 201) {
        final newTreatment = jsonDecode(treatmentResponse.body);
        if (newTreatment['treatmentId'] == null) {
          throw Exception('Invalid treatment ID in response');
        }

        final treatmentId = newTreatment['treatmentId'];

        for (final product in products) {
          try {
            await http.post(
              Uri.parse('$baseUrl/api/treatments/$treatmentId/products/${product['id']}/${Uri.encodeComponent(product['name'])}'),
              headers: {
                'accept': '*/*',
                'Authorization': 'Bearer ${userData['token']}',
              },
            );
          } catch (e) {
            print('Failed to add product ${product['id']}: $e');
          }
        }

        _showSuccessMessage('Treatment created successfully');
        await fetchTreatments();
      } else {
        throw Exception('Failed to create treatment: ${treatmentResponse.body}');
      }
    } catch (e) {
      _showErrorMessage(_getUserFriendlyError(e));
      print('Error creating treatment: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadData,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
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
            labelColor: Color(0xFF596D56),
            tabs: [
              Tab(text: 'Oily', icon: Icon(Icons.opacity, color: Colors.white)),
              Tab(text: 'Normal', icon: Icon(Icons.balance, color: Colors.white)),
              Tab(text: 'Dry', icon: Icon(Icons.water_drop, color: Colors.white)),
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
          backgroundColor: Color(0xFFFFD700),
        ),
      ),
    );
  }
}

class CreateTreatmentPage extends StatefulWidget {
  final Function(Map<String, dynamic>, List<dynamic>) createTreatment;

  const CreateTreatmentPage({required this.createTreatment});

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

  Future<void> _searchProducts() async {
    final userData = await getUserData();
    final baseUrl = await getBaseUrl();

    if (userData == null || baseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication error')),
      );
      return;
    }

    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductSearchPage(
          token: userData['token'],
          baseUrl: baseUrl,
        ),
      ),
    );

    if (selected != null && selected is List) {
      setState(() => _selectedProducts = List.from(selected));
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedSkinType == null || _selectedProblem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select skin type and problem')),
        );
        return;
      }

      widget.createTreatment(
        {
          'description': _descriptionController.text.trim(),
          'details': _detailsController.text.trim(),
          'skinType': _selectedSkinType,
          'problem': _selectedProblem,
        },
        _selectedProducts,
      );
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
    labelText: 'Description *',
    border: OutlineInputBorder(),
    ),
    validator: (value) => value?.isEmpty ?? true ? 'Required field' : null,
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
    items: _skinTypes.map((type) => DropdownMenuItem(
    value: type,
    child: Text(type),
    )).toList(),
    onChanged: (value) => setState(() => _selectedSkinType = value),
    decoration: InputDecoration(
    labelText: 'Skin Type *',
    border: OutlineInputBorder(),
    ),
    validator: (value) => value == null ? 'Please select skin type' : null,
    ),
    SizedBox(height: 20),
    DropdownButtonFormField<String>(
    value: _selectedProblem,
    items: _problems.map((problem) => DropdownMenuItem(
    value: problem,
    child: Text(problem),
    )).toList(),
    onChanged: (value) => setState(() => _selectedProblem = value),
    decoration: InputDecoration(
    labelText: 'Problem *',
    border: OutlineInputBorder(),
    ),
    validator: (value) => value == null ? 'Please select problem' : null,
    ),
    SizedBox(height: 20),
    Text('Selected Products:', style: TextStyle(fontWeight: FontWeight.bold)),
    _selectedProducts.isEmpty
    ? Text('No products selected')
        : Wrap(
    spacing: 8,
    children: _selectedProducts.map((p) => Chip(
    label: Text(p['name']),
    onDeleted: () => setState(() => _selectedProducts.removeWhere((prod) => prod['id'] == p['id'])),
    )).toList(),
    ),
    SizedBox(height: 16),
      ElevatedButton(
        onPressed: _searchProducts,
        child: Text('Search and Add Products'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF88A383),
          padding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),  // <-- Added this comma
      SizedBox(height: 30),  // <-- Fixed this SizedBox
      ElevatedButton(
        onPressed: _submitForm,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Create Treatment', style: TextStyle(fontSize: 18)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF596D56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),




    ],
    ),
    ),
    ),
    );
  }
}

// باقي الكلاسات (ProductSearchPage, TreatmentCategoryList, TreatmentDetailsPage) تبقى كما هي
// مع تطبيق نفس مبادئ التحقق من القيم الفارغة ومعالجة الأخطاء
class ProductSearchPage extends StatefulWidget {
  final String token;
  final String baseUrl;

  const ProductSearchPage({required this.token, required this.baseUrl});

  @override
  _ProductSearchPageState createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _products = [];
  List<dynamic> _selectedProducts = [];
  bool _isLoading = false;

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _products = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/product/search?name=$query'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final results = json.decode(response.body);
        setState(() => _products = results.map((p) => p['product']).toList());
      } else {
        throw Exception('Failed to search products');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
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
                labelText: 'Search',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _search(_searchController.text),
                ),
              ),
              onSubmitted: (value) => _search(value),
            ),
          ),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final isSelected = _selectedProducts.any((p) => p['id'] == product['productId']);

                return ListTile(
                  title: Text(product['name']),
                  subtitle: Text(product['description'] ?? ''),
                  trailing: IconButton(
                    icon: Icon(isSelected ? Icons.check_circle : Icons.add_circle),
                    color: isSelected ? Colors.green : null,
                    onPressed: () {
                      setState(() {
                        if (isSelected) {
                          _selectedProducts.removeWhere((p) => p['id'] == product['productId']);
                        } else {
                          _selectedProducts.add({
                            'id': product['productId'],
                            'name': product['name'],
                          });
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedProducts.isNotEmpty
          ? FloatingActionButton(
        onPressed: () => Navigator.pop(context, _selectedProducts),
        child: Icon(Icons.check),
        backgroundColor: Colors.green,
      )
          : null,
    );
  }
}

class TreatmentCategoryList extends StatelessWidget {
  final List<dynamic> treatments;

  const TreatmentCategoryList({required this.treatments});

  @override
  Widget build(BuildContext context) {
    final categorized = {
      'ACNE': treatments.where((t) => t['problem'] == 'ACNE').toList(),
      'WRINKLES': treatments.where((t) => t['problem'] == 'WRINKLES').toList(),
      'PIGMENTATION': treatments.where((t) => t['problem'] == 'PIGMENTATION').toList(),
    };

    return ListView(
      padding: EdgeInsets.all(12),
      children: categorized.entries.map((entry) {
        return ExpansionTile(
          title: Text(entry.key, style: TextStyle(color: Color(0xFF596D56), fontWeight: FontWeight.bold)),
          children: entry.value.map((treatment) => _buildTreatmentCard(context, treatment)).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildTreatmentCard(BuildContext context, dynamic treatment) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(treatment['description']),
        subtitle: Text('Skin: ${treatment['skinType']}'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TreatmentDetailsPage(treatment: treatment),
          ),
        ),
      ),
    );
  }
}

class TreatmentDetailsPage extends StatelessWidget {
  final dynamic treatment;

  const TreatmentDetailsPage({required this.treatment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Treatment Details'),
        backgroundColor: Color(0xFF88A383),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(treatment['description'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Problem: ${treatment['problem']}'),
            Text('Skin Type: ${treatment['skinType']}'),
            SizedBox(height: 16),
            Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(treatment['details'] ?? 'No details provided'),
            SizedBox(height: 16),
            Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _fetchTreatmentProducts(treatment['treatmentId']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading products'));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data?.length ?? 0,
                    itemBuilder: (context, index) {
                      final product = snapshot.data![index];
                      return ListTile(
                        title: Text(product['name']),
                        subtitle: Text(product['description'] ?? ''),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<dynamic>> _fetchTreatmentProducts(String treatmentId) async {
    final userData = await getUserData();
    final baseUrl = await getBaseUrl();

    if (userData == null || baseUrl == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/api/treatments/$treatmentId/products'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer ${userData['token']}',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }
}