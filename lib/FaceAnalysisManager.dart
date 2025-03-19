import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import 'model/SkinDetailsScreen.dart';

class FaceAnalysisManager {
  final BuildContext context;
  final String token;
  final Map<String, dynamic> userInfo;

  FaceAnalysisManager({
    required this.context,
    required this.token,
    required this.userInfo,
  });

  Future<String> _analyzeSkinType(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.29:8000/analyze/'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'skin_type',
          imageFile.path,
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);
        String skinType = jsonResponse['skin_type'];
        return skinType;
      } else {
        print('Failed to analyze skin type1: ${response.statusCode}');
        return 'Failed to analyze skin type2';
      }
    } catch (e) {
      print('Error analyzing skin type: $e');
      return e.toString();
    }
  }

  void _showImagePickerOptions() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await showModalBottomSheet<XFile>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera),
                title: Text('التقاط صورة من الكاميرا'),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('تحميل صورة من المعرض'),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
        );
      },
    );

    if (image != null) {
      _showImagePreviewDialog(File(image.path));
    }
  }

  void _showImagePreviewDialog(File imageFile) async {
    final skinType = await _analyzeSkinType(imageFile);
    List<String> skinTypes = [skinType, 'Normal', 'Dry', 'Oily'];
    String selectedSkinType = skinType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(imageFile),
            const SizedBox(height: 20),
            Text(
              'نوع بشرتك هو: $skinType',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedSkinType,
              onChanged: (String? newValue) {
                selectedSkinType = newValue!;
              },
              items: skinTypes.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SkinDetailsScreen(
                      imageFile: imageFile,
                      skinType: selectedSkinType,
                    ),
                  ),
                );
              },
              child: const Text('التالي'),
            ),
          ],
        ),
      ),
    );
  }

  void analyzeFace() {
    _showImagePickerOptions();
  }
}