import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TreatmentsPage extends StatefulWidget {
  @override
  _TreatmentsPageState createState() => _TreatmentsPageState();
}

class _TreatmentsPageState extends State<TreatmentsPage> {
  String baseUrl = '';
  String token = '';
  List<Map<String, dynamic>> treatments = [];

  @override
  void initState() {
    super.initState();
    fetchTreatments();
  }

  Future<void> fetchTreatments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      baseUrl = prefs.getString('base_url') ?? 'http://default_url.com';
      token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/api/treatments/skinType/DRY'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          treatments = data.map((treatment) => treatment as Map<String, dynamic>).toList();
        });
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Treatments for Dry Skin')),
      body: treatments.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: treatments.length,
        itemBuilder: (context, index) {
          final treatment = treatments[index];
          return ListTile(
            title: Text(treatment['problem'] ?? 'Unknown Problem'),
            subtitle: Text('Treatment ID: ${treatment['treatmentId']}'),
            trailing: Text('${treatment['productIds'].length} Products'),
          );
        },
      ),
    );
  }
}
