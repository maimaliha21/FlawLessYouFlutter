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
        Uri.parse('http://192.168.0.106:8000/analyze/'),
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

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Instructions Before Skin Analysis'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('For an accurate skin analysis, please follow the instructions below:'),
              SizedBox(height: 10),
              Text('1.Ensure good and uniform lighting.', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('2. Focus on capturing the affected area .', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('3.Remove glasses, hair, or any obstacles from the face.', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('4.Make sure the photo is clear and of high quality.', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('5.Avoid makeup to achieve more accurate results.', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showImagePickerOptions();
            },
            child: const Text('Understood', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
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
                title: Text('Capture a photo from the camera'),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Upload a photo from the gallery'),
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
      _processSelectedImage(File(image.path));
    }
  }

  void _processSelectedImage(File imageFile) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final skinType = await _analyzeSkinType(imageFile);
      Navigator.pop(context); // Close loading dialog
      _showAnalysisResult(imageFile, skinType);
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog(e.toString());
    }
  }

  void _showAnalysisResult(File imageFile, String skinType) {
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
              'Your skin type is: $skinType',
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
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text('Failed to analyze skin type: $errorMessage'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void analyzeFace() {
    _showInstructionsDialog();
  }
}