import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SkinAnalysisHistoryScreen extends StatefulWidget {
  const SkinAnalysisHistoryScreen({Key? key}) : super(key: key);

  @override
  _SkinAnalysisHistoryScreenState createState() => _SkinAnalysisHistoryScreenState();
}

class _SkinAnalysisHistoryScreenState extends State<SkinAnalysisHistoryScreen> {
  List<dynamic> _analysisHistory = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, dynamic>? _selectedAnalysis;
  bool _showDetails = false;
  final String _cacheKey = 'skin_analysis_history_cache';

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _fetchAnalysisHistory();
  }

  Future<void> _loadCachedData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        setState(() {
          _analysisHistory = json.decode(cachedData);
        });
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  Future<void> _saveToCache(List<dynamic> data) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(data));
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  Future<void> _fetchAnalysisHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? baseUrl = prefs.getString('baseUrl');

      if (token == null || baseUrl == null) {
        setState(() {
          _errorMessage = 'Please login first';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/skin-analysis/user'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        await _saveToCache(data);
        setState(() {
          _analysisHistory = data;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load analysis history: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAnalysisDetails(Map<String, dynamic> analysis) {
    setState(() {
      _selectedAnalysis = analysis;
      _showDetails = true;
    });
  }

  void _hideDetails() {
    setState(() {
      _showDetails = false;
      _selectedAnalysis = null;
    });
  }

  Widget _buildAnalysisItem(Map<String, dynamic> analysis) {
    final problems = analysis['problems'] as Map<String, dynamic>;
    final date = DateTime.parse(analysis['timeAnalysis'] ?? DateTime.now().toString());
    final formattedDate = '${date.day}/${date.month}/${date.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: InkWell(
        onTap: () => _showAnalysisDetails(analysis),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (analysis['imageUrl'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: analysis['imageUrl'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skin Type: ${analysis['skintype']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Date: $formattedDate',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: problems.entries.map((entry) {
                            return Chip(
                              label: Text(
                                '${entry.key}: ${entry.value}%',
                              ),
                              backgroundColor: entry.value > 0
                                  ? Colors.blue[100]
                                  : Colors.grey[200],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisDetails() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Analysis Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _hideDetails,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_selectedAnalysis!['imageUrl'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: _selectedAnalysis!['imageUrl'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Icon(Icons.error),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      Text(
                        'Skin Type: ${_selectedAnalysis!['skintype']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        'Problems Detected:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: (_selectedAnalysis!['problems'] as Map<String, dynamic>)
                            .entries
                            .map((entry) => Chip(
                          label: Text('${entry.key}: ${entry.value}%'),
                          backgroundColor: entry.value > 0
                              ? Colors.blue[100]
                              : Colors.grey[200],
                        ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Recommended Treatments:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...(_selectedAnalysis!['treatmentId'] as List).map((treatment) {
                        final products = treatment['productIds'] as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Problem: ${treatment['problem']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  treatment['description'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Recommended Products:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...products.entries.map((entry) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.arrow_right, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _isLoading && _analysisHistory.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty && _analysisHistory.isEmpty
          ? Center(child: Text(_errorMessage))
          : Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchAnalysisHistory,
            child: _analysisHistory.isEmpty
                ? const Center(child: Text('No analysis history available'))
                : ListView.builder(
              padding: const EdgeInsets.only(top: 16),
              itemCount: _analysisHistory.length,
              itemBuilder: (context, index) => _buildAnalysisItem(_analysisHistory[index]),
            ),
          ),
          if (_showDetails && _selectedAnalysis != null) _buildAnalysisDetails(),
        ],
      ),
    );
  }
}