import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projtry1/SharedPreferences.dart'; // استيراد الملف المساعد

class TreatmentPage extends StatefulWidget {
  @override
  _TreatmentPageState createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  List<dynamic> treatments = [];
  List<dynamic> oilyTreatments = [];
  List<dynamic> normalTreatments = [];
  List<dynamic> dryTreatments = [];

  @override
  void initState() {
    super.initState();
    fetchTreatments();
  }

  Future<void> fetchTreatments() async {
    try {
      // استرجاع التوكن والرابط الأساسي
      final userData = await getUserData();
      final baseUrl = await getBaseUrl();

      if (userData == null || baseUrl == null) {
        throw Exception('User data or base URL is missing');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/treatments'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer ${userData['token']}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          treatments = json.decode(response.body);
          oilyTreatments = treatments.where((treatment) => treatment['skinType'] == 'OILY').toList();
          normalTreatments = treatments.where((treatment) => treatment['skinType'] == 'NORMAL').toList();
          dryTreatments = treatments.where((treatment) => treatment['skinType'] == 'DRY').toList();
        });
      } else {
        throw Exception('Failed to load treatments');
      }
    } catch (e) {
      print('Error fetching treatments: $e');
      throw Exception('Failed to fetch treatments');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Skin Treatments'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Oily'),
              Tab(text: 'Normal'),
              Tab(text: 'Dry'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TreatmentList(treatments: oilyTreatments),
            TreatmentList(treatments: normalTreatments),
            TreatmentList(treatments: dryTreatments),
          ],
        ),
      ),
    );
  }
}

class TreatmentList extends StatelessWidget {
  final List<dynamic> treatments;

  TreatmentList({required this.treatments});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: treatments.length,
      itemBuilder: (context, index) {
        final treatment = treatments[index];
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            title: Text(treatment['description'] ?? 'No Description'),
            subtitle: Text('Problem: ${treatment['problem']}'),
            trailing: Icon(Icons.arrow_forward),
          ),
        );
      },
    );
  }
}