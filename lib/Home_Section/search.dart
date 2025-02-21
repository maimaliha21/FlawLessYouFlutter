import 'package:flutter/material.dart';
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
      body: TabBarView(
        controller: _tabController,
        children: [
          ProductTabScreen(
            token: widget.token,
            apiUrl: "http://localhost:8080/product/search?name=${widget.searchQuery}",
          ),
        ],
      ),
    );
  }
}