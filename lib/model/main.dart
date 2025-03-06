










import 'package:flutter/material.dart';
import 'SkinTypeAnalysisScreen.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SkinTypeAnalysisScreen(),
  ));
}






/*
previous code for only on model


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SkinTypeAnalysisScreen(),
  ));
}

class SkinTypeAnalysisScreen extends StatefulWidget {
  @override
  _SkinTypeAnalysisScreenState createState() => _SkinTypeAnalysisScreenState();
}

class _SkinTypeAnalysisScreenState extends State<SkinTypeAnalysisScreen> {
  File? _selectedImage;
  String _analysisResult = "";
  final ImagePicker _picker = ImagePicker();
  // عنوان API الخاص بتحليل الصورة (يُرجى التأكد من تحديثه حسب إعدادات الخادم)
  final String apiUrl = 'http://127.0.0.1:8000/analyze/';

  /// دالة لالتقاط صورة من المصدر المحدد (المعرض أو الكاميرا)
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _analysisResult = ""; // إعادة تعيين النتيجة عند اختيار صورة جديدة
      });
    }
  }

  /// دالة لإرسال الصورة إلى API واستقبال نتيجة التحليل
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      // يُفترض أن API يتوقع المفتاح "skin_type" لإرسال الصورة
      request.files.add(await http.MultipartFile.fromPath('skin_type', _selectedImage!.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        String responseString = await response.stream.bytesToString();
        final data = json.decode(responseString);
        setState(() {
          // يفترض أن API تُرجع المفتاح "skin_type" مع قيمة "dry" أو "normal" أو "oily"
          _analysisResult = data['skin_type'];
        });
      } else {
        setState(() {
          _analysisResult = 'حدث خطأ: ${response.statusCode}';
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
            // صف يحتوي على زرين: أحدهما لفتح المعرض والآخر لفتح الكاميرا
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
            // زر لإرسال الصورة للتحليل
            ElevatedButton(
              onPressed: _analyzeImage,
              child: Text("تحليل الصورة"),
            ),
            SizedBox(height: 20),
            // عرض نتيجة التحليل
            Text(
              "نتيجة التحليل: $_analysisResult",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
*/