import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'SkinDetailsScreen.dart';

class SkinTypeAnalysisScreen extends StatefulWidget {
  @override
  _SkinTypeAnalysisScreenState createState() => _SkinTypeAnalysisScreenState();
}

class _SkinTypeAnalysisScreenState extends State<SkinTypeAnalysisScreen> {
  File? _selectedImage;
  String _analysisResult = "";
  final ImagePicker _picker = ImagePicker();

  // عنوان الـ API (المسار الأول)
  final String apiUrl = 'http://192.168.1.169:8000/analyze/';

  /// اختيار الصورة من المصدر المحدد (المعرض أو الكاميرا)
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _analysisResult = "";
      });
    }
  }

  /// إرسال الصورة للمسار الأول وتحليل نوع البشرة
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  child: Text("اختيار من المعرض"),
                ),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  child: Text("التقاط من الكاميرا"),
                ),
              ],
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
            // زر "التالي" للانتقال لشاشة تفاصيل البشرة
            // سنمرر الصورة المختارة (_selectedImage) للشاشة الثانية
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
