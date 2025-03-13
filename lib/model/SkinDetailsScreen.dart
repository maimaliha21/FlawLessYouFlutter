import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  final String apiDetailsUrl = 'http://192.168.114.6:8000/analyze_details/';
  String apiTreatmentUrl = '';
  List<Map<String, dynamic>> treatments = [];
  Map<String, bool> selectedProducts = {};

  Future<void> _analyzeDetails() async {
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
pigmentation: ${data['PIGMENTATION']}%
wrinkles: ${data['WRINKLES']}%
acne: ${data['ACNE']}%
normal: ${data['NORMAL']}%
""";
        });
        // بعد الحصول على النتائج، نرسلها إلى API التوصيات
        _fetchTreatmentRecommendations(data);
      } else {
        setState(() {
          _detailsResult = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _detailsResult = 'Exception: $e';
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
          _treatmentResult = 'Error: Token or base URL not found';
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
          treatments = List<Map<String, dynamic>>.from(data['treatmentId']);
          treatments.forEach((treatment) {
            treatment['productIds'].forEach((productId) {
              selectedProducts[productId] = false;
            });
          });
        });
      } else {
        setState(() {
          _treatmentResult = 'Error fetching treatments: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _treatmentResult = 'Exception fetching treatments: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _analyzeDetails(); // تحليل الصورة تلقائيًا
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("تفاصيل البشرة"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.file(
              widget.imageFile,
              height: 300,
            ),
            SizedBox(height: 20),
            Text('Skin Type: ${widget.skinType}'),
            SizedBox(height: 10),
            Text(
              _detailsResult,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: treatments.length,
                itemBuilder: (context, index) {
                  final treatment = treatments[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Problem: ${treatment['problem']}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('Skin Type: ${treatment['skinType']}'),
                          SizedBox(height: 8),
                          Text('Products:'),
                          ...treatment['productIds'].map<Widget>((productId) {
                            return CheckboxListTile(
                              title: Text(productId),
                              value: selectedProducts[productId],
                              onChanged: (bool? value) {
                                setState(() {
                                  selectedProducts[productId] = value!;
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}