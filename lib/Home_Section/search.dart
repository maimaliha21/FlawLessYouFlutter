import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Product/product.dart';

class search extends StatefulWidget {
  final String token;
  final String searchQuery;
  final String pageName; // إضافة مدخل اسم الصفحة
  final String? treatmentId; // إضافة treatmentId كمعامل اختياري

  const search({
    Key? key,
    required this.token,
    required this.searchQuery,
    required this.pageName,
    this.treatmentId, // تمرير treatmentId
  }) : super(key: key);

  @override
  _searchState createState() => _searchState();
}

class _searchState extends State<search> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // دالة لاسترجاع الرابط من SharedPreferences
  Future<String> getBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('baseUrl') ?? 'http://192.168.0.13:8080'; // قيمة افتراضية إذا لم يتم العثور على الرابط
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // طول التبويب 1
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
        title: Text('search Results for "${widget.searchQuery}"'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Products'),
          ], labelColor: Color(0xFF88A383),indicatorColor: Color(0xFF88A383), // Color of the indicator
          indicatorWeight: 2.0,
        ),
      ),
      body: FutureBuilder<String>(
        future: getBaseUrl(), // استرجاع الرابط من SharedPreferences
        builder: (context, baseUrlSnapshot) {
          if (baseUrlSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (baseUrlSnapshot.hasError) {
            return const Center(child: Text('Error loading base URL'));
          }

          final baseUrl = baseUrlSnapshot.data!;

          // بناء الـ apiUrl بناءً على وجود treatmentId
          String  apiUrl = "$baseUrl/product/search?name=${widget.searchQuery}";


          return TabBarView(
            controller: _tabController,
            children: [
              ProductTabScreen(
                apiUrl: apiUrl,
                pageName: widget.pageName == 'add' ? "add" : "home",
                treatmentId: widget.treatmentId.toString() ?? '', // تمرير treatmentId إلى ProductTabScreen
              ),
            ],
          );
        },
      ),
    );
  }
}