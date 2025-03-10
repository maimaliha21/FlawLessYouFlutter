import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final String apiDetailsUrl = 'http://192.168.0.102:8000/analyze_details/';
  final String apiTreatmentUrl = 'http://localhost:8080/api/skin-analysis/recommend-treatments';

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
      final response = await http.post(
        Uri.parse('$apiTreatmentUrl?skinType=${widget.skinType}'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJyb2xlcyI6WyJST0xFX1VTRVIiXSwic3ViIjoiZmF0bWEiLCJpYXQiOjE3NDE2MjUyOTIsImV4cCI6MTc0MTcxMTY5Mn0.xevQ8yvbbIVMLKh0QbZwR3DKDWwjP4i2CNMmTo-Vr_0',
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
          _treatmentResult = "Treatment Recommendations:\n${data['treatmentId'].map((t) => "Problem: ${t['problem']}, Products: ${t['productIds'].join(', ')}").join('\n')}";
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
            Text(
              _treatmentResult,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}