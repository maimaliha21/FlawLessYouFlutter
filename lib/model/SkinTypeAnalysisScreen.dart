import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'SkinDetailsScreen.dart'; // إذا كنت تحتاج إلى شاشة تفاصيل البشرة

class SkinTypeAnalysisScreen extends StatefulWidget {
  final File imageFile;

  const SkinTypeAnalysisScreen({Key? key, required this.imageFile}) : super(key: key);

  @override
  _SkinTypeAnalysisScreenState createState() => _SkinTypeAnalysisScreenState();
}

class _SkinTypeAnalysisScreenState extends State<SkinTypeAnalysisScreen> {
  File? _selectedImage;
  String _analysisResult = "";

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.imageFile; // استخدام الصورة الممررة
  }

  /// إرسال الصورة للمسار الأول وتحليل نوع البشرة
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.13:8000/analyze/'), // تأكد من عنوان الـ API
      );
      request.files.add(
        await http.MultipartFile.fromPath('skin_type', _selectedImage!.path),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        final data = json.decode(responseString);
        setState(() {
          _analysisResult = data['skin_type'] ?? "No result";
        });
      } else {
        setState(() {
          _analysisResult = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _analysisResult = 'Exception: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("تحليل نوع البشرة"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _selectedImage == null
                ? Text("لم يتم اختيار صورة بعد")
                : Image.file(
              _selectedImage!,
              height: 300,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _analyzeImage,
              child: Text("تحليل الصورة"),
            ),
            SizedBox(height: 20),
            Text(
              "نتيجة التحليل: $_analysisResult",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectedImage == null
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SkinDetailsScreen(imageFile: _selectedImage!),
                  ),
                );
              },
              child: Text("التالي"),
            ),
          ],
        ),
      ),
    );
  }
}