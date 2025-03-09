import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SkinDetailsScreen extends StatefulWidget {
  final File imageFile;

  SkinDetailsScreen({required this.imageFile});

  @override
  _SkinDetailsScreenState createState() => _SkinDetailsScreenState();
}

class _SkinDetailsScreenState extends State<SkinDetailsScreen> {
  String _detailsResult = "";
  final String apiDetailsUrl = 'http://192.168.0.13:8000/analyze_details/';

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
تصبغات: ${data['pigmentation']}%
تجاعيد: ${data['wrinkles']}%
حب شباب: ${data['acne']}%
طبيعي: ${data['normal']}%
""";
        });
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
            Text(
              "نتائج التحليل التفصيلي:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              _detailsResult,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}