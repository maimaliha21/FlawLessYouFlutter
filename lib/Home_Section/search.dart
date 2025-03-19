import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Product/product.dart';

class search extends StatefulWidget {
  final String token;
  final String searchQuery;

  const search({
    Key? key,
    required this.token,
    required this.searchQuery,
  }) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<search> with SingleTickerProviderStateMixin {
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

          return TabBarView(
            controller: _tabController,
            children: [
              ProductTabScreen(
                apiUrl: "$baseUrl/product/search?name=${widget.searchQuery}", pageName: 'home', // استخدام الرابط المسترجع
              //  emptyStateMessage: 'No products found for "${widget.searchQuery}"', // رسالة إذا لم يتم العثور على منتجات
              ),
            ],
          );
        },
      ),
    );
  }
}