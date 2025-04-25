import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:FlawlessYou/SharedPreferences.dart';
import '../CustomBottomNavigationBarAdmin.dart';
import '../Home_Section/search.dart';
import '../Product/product.dart';

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
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchTreatments();
  }

  Future<void> fetchTreatments() async {
    try {
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
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load treatments');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading treatments: ${e.toString()}';
      });
      print('Error fetching treatments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: Text(errorMessage)),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Color(0xFF88A383),
          title: Text(
            'Skin Treatments',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          bottom: TabBar(
            indicatorColor: Color(0xFF596D56),
            labelStyle: TextStyle(color: Color(0xFF596D56)),
            tabs: [
              Tab(
                text: 'Oily',
                icon: Icon(Icons.opacity, color: Colors.white),
              ),
              Tab(
                text: 'Normal',
                icon: Icon(Icons.balance, color: Colors.white),
              ),
              Tab(
                text: 'Dry',
                icon: Icon(Icons.water_drop, color: Colors.white),
              ),
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
        bottomNavigationBar: CustomBottomNavigationBarAdmin(),
      ),
    );
  }
}

class TreatmentCategoryList extends StatelessWidget {
  final List<dynamic> treatments;

  TreatmentCategoryList({required this.treatments});

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
        return ExpansionTile(
          title: Text(
            entry.key,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF596D56)),
          ),
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.6,
              child: ListView(
                padding: EdgeInsets.all(8),
                children: entry.value.length > 4
                    ? [
                  ...entry.value.take(4).map((treatment) {
                    return _buildTreatmentCard(context, treatment);
                  }).toList(),
                  _buildViewMoreCard(context, entry.value[4]),
                ]
                    : entry.value.map((treatment) {
                  return _buildTreatmentCard(context, treatment);
                }).toList(),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTreatmentCard(BuildContext context, dynamic treatment) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TreatmentDetailsPage(treatment: treatment),
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
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              treatment['description'] ?? 'No Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF596D56)),
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
  }

  Widget _buildViewMoreCard(BuildContext context, dynamic treatment) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TreatmentDetailsPage(treatment: treatment),
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
            ),
          ],
        ),
        child: Center(
          child: Text(
            'View More',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF596D56)),
          ),
        ),
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
  final TextEditingController searchController = TextEditingController();
  late Future<String> _baseUrlFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _baseUrlFuture = getBaseUrl();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Treatment Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF88A383),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<String>(
        future: _baseUrlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final baseUrl = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.treatment['description'] ?? 'No Description',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF596D56)),
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
                SizedBox(height: 20),
                Text(
                  'Treatment Products',
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
                        apiUrl: "$baseUrl/api/treatments/${widget.treatment['treatmentId']}/products",
                        pageName: 'treatment',
                        treatmentId: widget.treatment['treatmentId'],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSearchPage(context),
        child: Icon(Icons.add, color: Colors.black),
        backgroundColor: Color(0xFFFFFDA),
      ),
    );
  }

  void _openSearchPage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search products',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: Color(0xFF88A383)),
                    onPressed: () {
                      if (searchController.text.isNotEmpty) {
                        Navigator.pop(context);
                        _navigateToSearch(context, searchController.text);
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF596D56)),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _navigateToSearch(BuildContext context, String query) async {
    try {
      final userData = await getUserData();
      if (userData == null) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => search(
            token: userData['token'],
            searchQuery: query,
            pageName: 'add',
            treatmentId: widget.treatment['treatmentId'],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}