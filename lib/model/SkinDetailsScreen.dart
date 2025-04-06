import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../CustomBottomNavigationBar.dart';

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
  final String apiDetailsUrl = 'http://192.168.60.114:8000/analyze_details/';
  String apiTreatmentUrl = '';
  List<dynamic> treatments = [];
  Map<String, bool> selectedProducts = {};
  List<String> confirmedProducts = [];

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
          Wrinkles: ${data['WRINKLES']}%
          Pigmentation: ${data['PIGMENTATION']}%
          Acne: ${data['ACNE']}%
          Normal: ${data['NORMAL']}%
          """;
        });
        await _fetchTreatmentRecommendations(data);
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
          treatments = data['treatmentId'];
          // Initialize selected products map
          for (var treatment in treatments) {
            var products = treatment['productIds'] as Map<String, dynamic>;
            products.forEach((id, name) {
              selectedProducts[name] = false;
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

  void _confirmSelection() {
    setState(() {
      confirmedProducts = selectedProducts.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${confirmedProducts.length} products selected'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
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
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full width image at top
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

            // Skin type and analysis results
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Skin Type: ${widget.skinType}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),
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
                                fontWeight: FontWeight.bold
                            ),
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

            // Error message if any
            if (_treatmentResult.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _treatmentResult,
                  style: TextStyle(color: Colors.red),
                ),
              ),

            // Treatments grouped by problem
            if (treatments.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Recommended Treatments:',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Group treatments by problem
              ...treatments.map((treatment) {
                var products = treatment['productIds'] as Map<String, dynamic>;
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Problem: ${treatment['problem']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          treatment['description'],
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Recommended Products:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ...products.entries.map((entry) {
                          String productName = entry.value;
                          return CheckboxListTile(
                            title: Text(productName),
                            value: selectedProducts[productName],
                            onChanged: (bool? value) {
                              setState(() {
                                selectedProducts[productName] = value!;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }).toList(),

              // Confirm button
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: _confirmSelection,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0
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

              // Selected products
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
      bottomNavigationBar: CustomBottomNavigationBar2(),
    );
  }
}