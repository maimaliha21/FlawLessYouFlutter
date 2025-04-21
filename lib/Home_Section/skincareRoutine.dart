import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../SharedPreferences.dart';

final String _backgroundImageUrl =
    'https://res.cloudinary.com/davwgirjs/image/upload/v1740317838/nhndev/product/320aee5f-ac8b-48be-94c7-e9296259cf99_1740317835039_Screenshot%202025-02-23%20153620.png.png';

class SkincareRoutineFlow extends StatefulWidget {
  final String token;
  SkincareRoutineFlow({required this.token});

  @override
  _SkincareRoutineFlowState createState() => _SkincareRoutineFlowState();
}

class _SkincareRoutineFlowState extends State<SkincareRoutineFlow> {
  TimeOfDay _currentTime = TimeOfDay.now();
  Timer? _timer;
  String _currentPeriod = '';
  List<Period> _periods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePeriods();
    _updateTime();
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _updateTime();
    });
    _isLoading = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _currentTime = TimeOfDay.now();
      _updateCurrentPeriod();
    });
  }

  void _initializePeriods() {
    _periods = [
      Period(name: 'MORNING', start: TimeOfDay(hour: 6, minute: 0), end: TimeOfDay(hour: 11, minute: 59)),
      Period(name: 'AFTERNOON', start: TimeOfDay(hour: 12, minute: 0), end: TimeOfDay(hour: 17, minute: 0)),
      Period(name: 'NIGHT', start: TimeOfDay(hour: 20, minute: 0), end: TimeOfDay(hour: 23, minute: 59)),
    ];
    _updateCurrentPeriod();
  }

  void _updateCurrentPeriod() {
    for (var period in _periods) {
      if (_isTimeInPeriod(_currentTime, period)) {
        _currentPeriod = period.name;
        return;
      }
    }
    _currentPeriod = '';
  }

  bool _isTimeInPeriod(TimeOfDay time, Period period) {
    final now = time.hour * 60 + time.minute;
    final start = period.start.hour * 60 + period.start.minute;
    final end = period.end.hour * 60 + period.end.minute;

    return now >= start && now <= end;
  }

  bool _isPeriodPassed(Period period) {
    final now = _currentTime.hour * 60 + _currentTime.minute;
    final end = period.end.hour * 60 + period.end.minute;
    return now > end;
  }

  bool _isPeriodUpcoming(Period period) {
    final now = _currentTime.hour * 60 + _currentTime.minute;
    final start = period.start.hour * 60 + period.start.minute;
    return now < start;
  }

  Color _getPeriodColor(Period period) {
    if (_currentPeriod == period.name) {
      return Colors.green;
    } else if (_isPeriodPassed(period)) {
      return Colors.green.withOpacity(0.5);
    } else if (_isPeriodUpcoming(period)) {
      return Colors.orange.withOpacity(0.7);
    }
    return Colors.grey.withOpacity(0.3);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Routine'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              _backgroundImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Time: ${_currentTime.format(context)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 10),
                if (_currentPeriod.isNotEmpty)
                  Text(
                    'Current Period: $_currentPeriod',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _periods.length,
                    itemBuilder: (context, index) {
                      final period = _periods[index];
                      return Card(
                        color: _getPeriodColor(period).withOpacity(0.8),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            period.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            '${period.start.format(context)} - ${period.end.format(context)}',
                            style: TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                          trailing: _currentPeriod == period.name
                              ? Icon(Icons.check_circle, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPeriod.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SkincareRoutine(
                              token: widget.token,
                              currentPeriod: _currentPeriod,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No active period now')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 166, 224, 228),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Start Routine',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Period {
  final String name;
  final TimeOfDay start;
  final TimeOfDay end;

  Period({required this.name, required this.start, required this.end});
}

class SkincareRoutine extends StatefulWidget {
  final String token;
  final String currentPeriod;

  SkincareRoutine({required this.token, required this.currentPeriod});

  @override
  _SkincareRoutineScreenState createState() => _SkincareRoutineScreenState();
}

class _SkincareRoutineScreenState extends State<SkincareRoutine> {
  int _currentStep = 0;
  Map<String, List<Map<String, dynamic>>> _routines = {
    "MORNING": [],
    "AFTERNOON": [],
    "NIGHT": [],
  };
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      String? baseUrl = await getBaseUrl();
      if (baseUrl == null) {
        throw Exception("Base URL not found in SharedPreferences");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/routines/by-time'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _routines["MORNING"] = List<Map<String, dynamic>>.from(data["MORNING"] ?? []);
          _routines["AFTERNOON"] = List<Map<String, dynamic>>.from(data["AFTERNOON"] ?? []);
          _routines["NIGHT"] = List<Map<String, dynamic>>.from(data["NIGHT"] ?? []);
          _currentStep = 0;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _getCurrentPeriodRoutines() {
    return _routines[widget.currentPeriod] ?? [];
  }

  void _nextStep(BuildContext context) {
    final currentRoutines = _getCurrentPeriodRoutines();
    if (currentRoutines.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (_currentStep < currentRoutines.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildNoRoutinesScreen() {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              _backgroundImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'No ${widget.currentPeriod.toLowerCase()} routines available',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'You don\'t have any routines scheduled for this period',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 166, 224, 228),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    child: Text(
                      'Go Back',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineItem(Map<String, dynamic> routine) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (routine['photos'] != null && routine['photos'].isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              routine['photos'][0],
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(
                    color: Colors.grey,
                    height: 120,
                    child: Icon(Icons.error, color: Colors.white),
                  ),
            ),
          )
        else
          Container(
            height: 120,
            color: Colors.grey.withOpacity(0.5),
            child: Center(
              child: Icon(Icons.image_not_supported,
                  color: Colors.white, size: 40),
            ),
          ),
        SizedBox(height: 16),
        Text(
          routine['name'] ?? 'No Name',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          routine['smaledescription'] ?? 'No Description',
          style: TextStyle(fontSize: 16, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getPeriodColor() {
    switch (widget.currentPeriod) {
      case 'MORNING':
        return Colors.green;
      case 'AFTERNOON':
        return Colors.orange;
      case 'NIGHT':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load data',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchData,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final currentRoutines = _getCurrentPeriodRoutines();

    if (currentRoutines.isEmpty) {
      return _buildNoRoutinesScreen();
    }

    if (_currentStep >= currentRoutines.length) {
      _currentStep = 0;
    }

    final currentRoutine = currentRoutines[_currentStep];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _getPeriodColor().withOpacity(0.7),
        elevation: 0,
        title: Text(
          '${widget.currentPeriod} Routine ${_currentStep + 1}/${currentRoutines.length}',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              _backgroundImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
            ),
          ),
          Center(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  )),
                  child: child,
                );
              },
              child: BackdropFilter(
                key: ValueKey<int>(_currentStep),
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Card(
                  color: Colors.black.withOpacity(0.5),
                  margin: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRoutineItem(currentRoutine),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => _nextStep(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getPeriodColor(),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 16),
                          ),
                          child: Text(
                            _currentStep < currentRoutines.length - 1
                                ? 'Next'
                                : 'Finish',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}