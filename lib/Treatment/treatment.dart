import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projtry1/SharedPreferences.dart';
import '../Home_Section/search.dart';
import '../Product/product.dart'; // استيراد الملف المساعد

void main() {
  runApp(MaterialApp(
    home: TreatmentPage(),
  ));
}

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
          title: Text('Skin Treatments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Oily', icon: Icon(Icons.opacity)),
              Tab(text: 'Normal', icon: Icon(Icons.balance)),
              Tab(text: 'Dry', icon: Icon(Icons.water_drop)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TreatmentCategoryList(treatments: oilyTreatments),
            TreatmentCategoryList(treatments: normalTreatments),
            TreatmentCategoryList(treatments: dryTreatments),
          ],
        ),
      ),
    );
  }
}

class TreatmentCategoryList extends StatelessWidget {
  final List<dynamic> treatments;

  TreatmentCategoryList({required this.treatments});

  // تصنيف العلاجات حسب المشكلة
  Map<String, List<dynamic>> categorizeTreatments(List<dynamic> treatments) {
    Map<String, List<dynamic>> categorized = {
      'ACNE': [],
      'WRINKLES': [],
      'PIGMENTATION': [],
      'NORMAL': [],
    };

    for (var treatment in treatments) {
      if (categorized.containsKey(treatment['problem'])) {
        categorized[treatment['problem']]!.add(treatment);
      }
    }

    return categorized;
  }

  @override
  Widget build(BuildContext context) {
    final categorizedTreatments = categorizeTreatments(treatments);

    return ListView(
      padding: EdgeInsets.all(12),
      children: categorizedTreatments.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: InkWell(
                onTap: () {
                  // الانتقال إلى صفحة جديدة لعرض جميع العلاجات لهذه المشكلة
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProblemDetailsPage(
                        problem: entry.key,
                        treatments: entry.value,
                      ),
                    ),
                  );
                },
                child: Text(
                  entry.key,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
              ),
            ),
            ...entry.value.map((treatment) {
              return GestureDetector(
                onTap: () {
                  // الانتقال إلى صفحة تفاصيل العلاج
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TreatmentDetailsPage(
                        treatment: treatment,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 6),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                  BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                  )],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treatment['description'] ?? 'No Description',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Problem: ${treatment['problem']}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              );
            }).toList(),
          ],
        );
      }).toList(),
    );
  }
}

class ProblemDetailsPage extends StatelessWidget {
  final String problem;
  final List<dynamic> treatments;

  ProblemDetailsPage({required this.problem, required this.treatments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(problem, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: EdgeInsets.all(12),
        children: treatments.map((treatment) {
          return GestureDetector(
            onTap: () {
              // الانتقال إلى صفحة تفاصيل العلاج
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TreatmentDetailsPage(
                    treatment: treatment,
                  ),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 6),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
              BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
              )],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  treatment['description'] ?? 'No Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                SizedBox(height: 8),
                Text(
                  'Problem: ${treatment['problem']}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          );
        }).toList(),
      ),
    );
  }
}

class TreatmentDetailsPage extends StatefulWidget {
  final dynamic treatment;

  TreatmentDetailsPage({required this.treatment});

  @override
  _TreatmentDetailsPageState createState() => _TreatmentDetailsPageState();
}

class _TreatmentDetailsPageState extends State<TreatmentDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // طول التبويب 1 لأن لدينا تبويب واحد فقط
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Treatment Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.treatment['description'] ?? 'No Description',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            SizedBox(height: 16),
            Text(
              'Problem: ${widget.treatment['problem']}',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            SizedBox(height: 16),
            Text(
              'Details: ${widget.treatment['details'] ?? 'No details available'}',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            SizedBox(height: 16),
            Text(
              'Skin Type: ${widget.treatment['skinType']}',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),


            SizedBox(height: 20), // مسافة بين النص و TabBarView
            Text(
              'Treatment Products ',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ProductTabScreen(
                    apiUrl: "http://localhost:8080/api/treatments/${widget.treatment['treatmentId']}/products", // استخدام الرابط المسترجع
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openSearchPage(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _openSearchPage(BuildContext context) {
    Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search products',
              prefixIcon: Icon(Icons.search, color: Color(0xFF88A383)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        IconButton(
          icon: Icon(Icons.search, color: Color(0xFF88A383)),
          onPressed: () {
            if (searchController.text.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => search(
                    token: token,
                    searchQuery: searchController.text,
                  ),
                ),
              );
            }
          },
        ),
      ],
    ),
}



