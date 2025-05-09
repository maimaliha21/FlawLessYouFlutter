import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../CustomBottomNavigationBar.dart';
import '../CustomBottomNavigationBarAdmin.dart';

class SkinDetailsScreen extends StatefulWidget {
  final File imageFile;
  final String skinType;

  const SkinDetailsScreen({
    Key? key,
    required this.imageFile,
    required this.skinType,
  }) : super(key: key);

  @override
  _SkinDetailsScreenState createState() => _SkinDetailsScreenState();
}

class _SkinDetailsScreenState extends State<SkinDetailsScreen> {
  String _detailsResult = "";
  String _treatmentResult = "";
  bool _isLoading = false;
  final String apiDetailsUrl = 'http://192.168.0.100:8000/analyze_details/';
  String apiTreatmentUrl = '';
  List<dynamic> treatments = [];
  Map<String, String?> selectedProductsPerProblem = {};
  Map<String, String> productIdMap = {};
  List<String> confirmedProducts = [];
  List<String> confirmedProductIds = [];
  Map<String, dynamic>? _productDetails;
  bool _showProductDetails = false;
  String? _analysisId;
  Map<String, dynamic>? _userInfo;
  String _userRole = 'USER';

  Future<Map<String, dynamic>?> _getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userInfoJson = prefs.getString('userInfo');
    if (userInfoJson != null) {
      return jsonDecode(userInfoJson);
    }
    return null;
  }

  Future<void> _loadUserRole() async {
    final userInfo = await _getUserInfo();
    setState(() {
      _userInfo = userInfo;
      _userRole = userInfo?['role'] ?? 'USER';
    });
  }

  Future<void> _analyzeDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiDetailsUrl));
      request.files.add(
        await http.MultipartFile.fromPath('details_file', widget.imageFile.path),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        final data = json.decode(responseString);
        setState(() {
          _detailsResult = """
Wrinkles: ${data['WRINKLES']?.toString() ?? '0'}%
Pigmentation: ${data['PIGMENTATION']?.toString() ?? '0'}%
Acne: ${data['ACNE']?.toString() ?? '0'}%
Normal: ${data['NORMAL']?.toString() ?? '0'}%
""";
        });
        await _fetchTreatmentRecommendations(data);
        await _uploadImageToServer();
      } else {
        setState(() {
          _detailsResult = 'Analysis Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _detailsResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImageToServer() async {
    if (_analysisId == null) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? baseUrl = prefs.getString('baseUrl');

      if (token == null || baseUrl == null) {
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/skin-analysis/$_analysisId/upload-image'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['accept'] = '*/*';

      request.files.add(
        await http.MultipartFile.fromPath(
          'imageFile',
          widget.imageFile.path,
          filename: 'skin_analysis_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        print('Image uploaded successfully');
      } else {
        print('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _fetchTreatmentRecommendations(Map<String, dynamic> skinData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? baseUrl = prefs.getString('baseUrl');

      if (token == null || baseUrl == null) {
        setState(() {
          _treatmentResult = 'Please login first';
        });
        return;
      }

      apiTreatmentUrl = '$baseUrl/api/skin-analysis/recommend-treatments';

      final response = await http.post(
        Uri.parse('$apiTreatmentUrl?skinType=${widget.skinType.toUpperCase()}'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "WRINKLES": skinData['WRINKLES'],
          "PIGMENTATION": skinData['PIGMENTATION'],
          "ACNE": skinData['ACNE'],
          "NORMAL": skinData['NORMAL'],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          treatments = data['treatmentId'] ?? [];
          _analysisId = data['id'];
          selectedProductsPerProblem = {};
          productIdMap = {};

          for (int i = 0; i < treatments.length; i++) {
            var treatment = treatments[i];
            var problem = treatment['problem']?.toString() ?? 'Unknown Problem';
            String uniqueKey = '$problem-$i'; // Unique key with index
            selectedProductsPerProblem[uniqueKey] = null;

            var products = (treatment['productIds'] as Map<String, dynamic>?) ?? {};
            products.forEach((id, name) {
              productIdMap[name.toString()] = id.toString();
            });
          }
        });
      } else {
        setState(() {
          _treatmentResult = 'Error loading treatments: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _treatmentResult = 'Error: $e';
      });
    }
  }

  Future<void> _fetchProductDetails(String productId) async {
    setState(() {
      _isLoading = true;
      _showProductDetails = false;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? baseUrl = prefs.getString('baseUrl');

      if (token == null || baseUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please login first')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/product/$productId'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _productDetails = data;
          _showProductDetails = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load product details')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmSelection() async {
    confirmedProductIds = [];
    confirmedProducts = [];

    selectedProductsPerProblem.forEach((problem, productName) {
      if (productName != null && productIdMap.containsKey(productName)) {
        confirmedProducts.add(productName);
        confirmedProductIds.add(productIdMap[productName]!);
      }
    });

    if (confirmedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one product from any problem')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? baseUrl = prefs.getString('baseUrl');
      String? userInfoJson = prefs.getString('userInfo');

      if (token == null || baseUrl == null || userInfoJson == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please login first')),
        );
        return;
      }

      Map<String, dynamic> userInfo = jsonDecode(userInfoJson);
      String userId = userInfo['userId'];

      String mainProblem = "general care";
      if (_detailsResult.isNotEmpty) {
        final problems = _detailsResult.split('\n');
        if (problems.isNotEmpty && problems[0].contains(':')) {
          mainProblem = problems[0].split(':')[0].trim().toLowerCase();
        }
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/routines/create'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "userId": userId,
          "productIds": confirmedProductIds,
          "timeAnalysis": DateTime.now().toIso8601String(),
          "description": "This routine is for $mainProblem problem",
          "analysisId": _analysisId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Routine created successfully!'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create routine: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating routine: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _closeProductDetails() {
    setState(() {
      _showProductDetails = false;
      _productDetails = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _analyzeDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Skin Analysis Results"),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Image.file(
                    widget.imageFile,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Skin Type: ${widget.skinType}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 15),
                      Card(
                        elevation: 3,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analysis Results:',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              Text(
                                _detailsResult,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                if (_treatmentResult.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _treatmentResult,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                if (treatments.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Recommended Treatments:',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 10),
                  ...treatments.asMap().entries.map((entry) {
                    int index = entry.key;
                    var treatment = entry.value;
                    var problem = treatment['problem']?.toString() ?? 'Unknown Problem';
                    String uniqueKey = '$problem-$index';
                    var products = treatment['productIds'] as Map<String, dynamic>? ?? {};

                    return Card(
                      margin: EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Problem: $problem',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              treatment['description']?.toString() ?? 'No description available',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Recommended Products: (Choose one)',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Column(
                              children: products.entries.map((entry) {
                                String productId = entry.key;
                                String productName = entry.value.toString();

                                return RadioListTile<String>(
                                  title: Text(productName),
                                  value: productName,
                                  groupValue: selectedProductsPerProblem[uniqueKey],
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedProductsPerProblem[uniqueKey] = value;
                                    });
                                  },
                                  secondary: IconButton(
                                    icon: Icon(Icons.info_outline, color: Colors.blue),
                                    onPressed: () {
                                      _fetchProductDetails(productId);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _confirmSelection,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 12.0,
                          ),
                          child: Text(
                            'Confirm Selection',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (confirmedProducts.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        color: Colors.green[50],
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Selected Products:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                              SizedBox(height: 10),
                              ...confirmedProducts.map((product) => Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green),
                                    SizedBox(width: 8),
                                    Expanded(child: Text(product)),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                SizedBox(height: 20),
              ],
            ),
          ),
          if (_showProductDetails && _productDetails != null)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _productDetails?['name']?.toString() ?? 'No name available',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),),
                                  IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: _closeProductDetails,
                                  ),
                                ],
                              ),
                              SizedBox(height: 15),
                              if (_productDetails!['photos'] != null &&
                                  _productDetails!['photos'].isNotEmpty)
                                Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: NetworkImage(_productDetails!['photos'][0]),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 20),
                              Text(
                                'Description:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                _productDetails!['description'] ?? 'No description available',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 15),
                              if (_productDetails!['ingredients'] != null &&
                                  _productDetails!['ingredients'].isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ingredients:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Wrap(
                                      spacing: 8,
                                      children: _productDetails!['ingredients']
                                          .map<Widget>((ingredient) => Chip(
                                        label: Text(ingredient),
                                      ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              SizedBox(height: 15),
                              if (_productDetails!['usageTime'] != null &&
                                  _productDetails!['usageTime'].isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recommended Usage Time:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Wrap(
                                      spacing: 8,
                                      children: _productDetails!['usageTime']
                                          .map<Widget>((time) => Chip(
                                        label: Text(time),
                                        backgroundColor: Colors.blue[100],
                                      ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              SizedBox(height: 15),
                              if (_productDetails!['skinType'] != null &&
                                  _productDetails!['skinType'].isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Suitable for Skin Types:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Wrap(
                                      spacing: 8,
                                      children: _productDetails!['skinType']
                                          .map<Widget>((type) => Chip(
                                        label: Text(type),
                                        backgroundColor: Colors.green[100],
                                      ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _userRole == "ADMIN"
          ? CustomBottomNavigationBarAdmin()
          : CustomBottomNavigationBar2(),
    );
  }
}