import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Product/product.dart';

class search extends StatefulWidget {
  final String token;
  final String searchQuery;
  final String pageName; // إضافة مدخل اسم الصفحة

  const search({
    Key? key,
    required this.token,
    required this.searchQuery,
    required this.pageName, // تمرير اسم الصفحة
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
        title: Text('Search Results for "${widget.searchQuery}"'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Products'),
          ],
        ),
      ),
      body: FutureBuilder<String>(
        future: getBaseUrl(), // استرجاع الرابط من SharedPreferences
        builder: (context, baseUrlSnapshot) {
          if (baseUrlSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (baseUrlSnapshot.hasError) {
            return Center(child: Text('Error loading base URL'));
          }

          final baseUrl = baseUrlSnapshot.data!;

          // تحديد الـ apiUrl بناءً على اسم الصفحة
          final add = widget.pageName == 'add'
              ? "add" // إذا كانت الصفحة هي 'add'
              : "home";
          final apiUrl ="$baseUrl/product/search?name=${widget.searchQuery}"; // إذا كانت الصفحة هي 'home' أو أي شيء آخر

          return TabBarView(
            controller: _tabController,
            children: [
              ProductTabScreen(
                apiUrl: apiUrl, // تمرير الـ apiUrl المناسب
                pageName: add, // تمرير اسم الصفحة
                // emptyStateMessage: 'No products found for "${widget.searchQuery}"', // رسالة إذا لم يتم العثور على منتجات
              ),
            ],
          );
        },
      ),
    );
  }
}