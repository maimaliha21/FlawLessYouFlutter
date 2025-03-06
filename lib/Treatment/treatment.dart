import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TreatmentScreen extends StatefulWidget {
  @override
  _TreatmentScreenState createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  String? token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("auth_token");
    });
  }

  Future<List<Map<String, dynamic>>> fetchTreatments(String skinType) async {
    if (token == null) return [];
    final response = await http.get(
      Uri.parse('http://localhost:8080/api/treatments/skinType/$skinType'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load treatments');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Treatments'),
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
            TreatmentList(skinType: 'OILY', fetchTreatments: fetchTreatments),
            TreatmentList(skinType: 'NORMAL', fetchTreatments: fetchTreatments),
            TreatmentList(skinType: 'DRY', fetchTreatments: fetchTreatments),
          ],
        ),
      ),
    );
  }
}

class TreatmentList extends StatelessWidget {
  final String skinType;
  final Future<List<Map<String, dynamic>>> Function(String) fetchTreatments;

  TreatmentList({required this.skinType, required this.fetchTreatments});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchTreatments(skinType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No treatments found'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final treatment = snapshot.data![index];
            return Card(
              child: ListTile(
                title: Text(treatment['problem']),
                subtitle: Text('ID: ${treatment['treatmentId']}'),
              ),
            );
          },
        );
      },
    );
  }
}