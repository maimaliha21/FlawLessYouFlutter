import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class SkinTypeAnalysisScreen extends StatelessWidget {
  final File imageFile;

  const SkinTypeAnalysisScreen({Key? key, required this.imageFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.file(
            imageFile,
            height: 150,
          ),
          const SizedBox(height: 20),
          Text(
            "نتيجة التحليل: Normal", // يمكنك تغيير هذا بناءً على النتيجة الفعلية
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          DropdownButton<String>(
            value: 'Normal', // يمكنك تغيير هذا بناءً على النتيجة الفعلية
            onChanged: (String? newValue) {
              // يمكنك تغيير القيمة المحددة هنا
            },
            items: <String>[
              'Normal',
              'Oily',
              'Dry'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, 'Normal'); // إرجاع النتيجة المحددة
            },
            child: const Text("التالي"),
          ),
        ],
      ),
    );
  }
}