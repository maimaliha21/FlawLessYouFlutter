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
        Uri.parse('http://192.168.107.80:8000/analyze/'),
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
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 10,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF818181)!, Colors.white],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.face_retouching_natural,
                  size: 50,
                  color: Color(0xFF3F3F3F),
                ),
                SizedBox(height: 15),
                Text(
                  'Skin Analysis Preparation',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F3F3F),
                  ),
                ),
                SizedBox(height: 15),
                Divider(color: Color(0xFF88A383), thickness: 1),
                SizedBox(height: 15),
                _buildInstructionItem(Icons.lightbulb_outline, 'Ensure good, uniform lighting'),
                _buildInstructionItem(Icons.zoom_in, 'Focus on the area of interest'),
                _buildInstructionItem(Icons.face, 'Remove glasses/hair from face'),
                _buildInstructionItem(Icons.high_quality, 'Use clear, high-quality images'),
                _buildInstructionItem(Icons.palette, 'Avoid makeup for accurate results'),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF88A383),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showImagePickerOptions();
                    },
                    child: Text(
                      'I Understand, Continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Color(0xFF88A383)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
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
                leading: Icon(Icons.camera, color: Color(0xFF00000C)),
                title: Text('Take Photo',
                    style: TextStyle(color: Color(0xFF00000C))),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(
                      source: ImageSource.camera);
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF00000C)),
                title: Text('Choose from Gallery',
                    style: TextStyle(color: Color(0xFF00000C))),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(
                      source: ImageSource.gallery);
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF88A383)),
        ),
      ),
    );

    try {
      final skinType = await _analyzeSkinType(imageFile);
      Navigator.pop(context);
      _showAnalysisResult(imageFile, skinType);
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog(e.toString());
    }
  }

  void _showAnalysisResult(File imageFile, String skinType) {
    List<String> skinTypes = [skinType, 'Normal', 'Dry', 'Oily'];
    String selectedSkinType = skinType;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(imageFile),
                ),
                SizedBox(height: 20),
                Text(
                  'Analysis Result:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF88A383),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Detected Skin Type: $skinType',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF88A383)!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedSkinType,
                    icon: Icon(Icons.arrow_drop_down, color: Color(0xFF88A383)),
                    isExpanded: true,
                    underline: SizedBox(),
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
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size(double.infinity, 45),
                  ),
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
                  child: Text(
                    'View Detailed Analysis',
                    style: TextStyle(fontSize: 16,color: Color(0xFF88A383)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Analysis Error',
            style: TextStyle(color: Colors.red),
          ),
          content: Text(
            'Unable to analyze skin type:\n$errorMessage',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(color: Color(0xFF88A383)),
              ),
            ),
          ],
        );
      },
    );
  }

  void analyzeFace() {
    _showInstructionsDialog();
  }
}