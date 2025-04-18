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
  Map<String, bool> _selectedProducts = {};
  Map<String, String> _productIdMap = {};
  bool _routineCreated = false;
  List<String> _confirmedProducts = [];

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
    // Initialize selected products map
    _selectedProducts.clear();
    _productIdMap.clear();

    for (var treatment in analysis['treatmentId']) {
      var products = treatment['productIds'] as Map<String, dynamic>;
      products.forEach((id, name) {
        _selectedProducts[name] = false;
        _productIdMap[name] = id;
      });
    }

    setState(() {
      _selectedAnalysis = analysis;
      _showDetails = true;
      _routineCreated = false;
      _confirmedProducts.clear();
    });
  }

  void _hideDetails() {
    setState(() {
      _showDetails = false;
      _selectedAnalysis = null;
    });
  }

  Future<void> _confirmSelection() async {
    // Get selected product IDs
    List<String> selectedIds = [];
    _selectedProducts.forEach((name, isSelected) {
      if (isSelected && _productIdMap.containsKey(name)) {
        selectedIds.add(_productIdMap[name]!);
      }
    });

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one product')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? baseUrl = prefs.getString('baseUrl');
      String? userInfoJson = prefs.getString('userInfo');

      if (token == null || baseUrl == null || userInfoJson == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please login first')),
        );
        return;
      }

      Map<String, dynamic> userInfo = jsonDecode(userInfoJson);
      String userId = userInfo['userId'];

      // Determine main problem
      String mainProblem = "General Care";
      final problems = _selectedAnalysis!['problems'] as Map<String, dynamic>;
      if (problems['WRINKLES'] > 0) {
        mainProblem = "Wrinkles";
      } else if (problems['ACNE'] > 0) {
        mainProblem = "Acne";
      } else if (problems['PIGMENTATION'] > 0) {
        mainProblem = "Pigmentation";
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/routines/create'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "userId": userId,
          "productIds": selectedIds,
          "timeAnalysis": DateTime.now().toIso8601String(),
          "description": "Routine for $mainProblem",
          "analysisId": _selectedAnalysis!['id'],
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _routineCreated = true;
          _confirmedProducts = _selectedProducts.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Routine created successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create routine: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating routine: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatAnalysisDate(String? dateString) {
    if (dateString == null) return 'No date';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildAnalysisItem(Map<String, dynamic> analysis) {
    final problems = analysis['problems'] as Map<String, dynamic>;
    final formattedDate = _formatAnalysisDate(analysis['createdAt']);

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
    if (_selectedAnalysis == null) return Container();

    final formattedDate = _formatAnalysisDate(_selectedAnalysis!['createdAt']);

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
                      Text(
                        'Date: $formattedDate',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 10),

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
                                      Checkbox(
                                        value: _selectedProducts[entry.value] ?? false,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _selectedProducts[entry.value] = value!;
                                          });
                                        },
                                      ),
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

                      if (_routineCreated) ...[
                        const SizedBox(height: 20),
                        Card(
                          color: Colors.green[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Selected Products:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ..._confirmedProducts.map((product) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(product)),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _routineCreated ? null : _confirmSelection,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 12.0
                            ),
                            child: Text(
                              _routineCreated ? 'Routine Created!' : 'Confirm Selection',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                              backgroundColor: _routineCreated ? Colors.grey : Colors.blue,                          ),
                        ),
                      ),
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