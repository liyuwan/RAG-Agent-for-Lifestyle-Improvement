import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/menu_bar_icon.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  String _weight = '';
  String _height = '';
  String _caloriesBurnt = '';
  String _steps = '';
  List<FlSpot> _caloriesConsumedSpots = [];
  List<FlSpot> _caloriesBurntSpots = [];
  int _consistencyStreak = 0;
  double _mostCaloriesBurnt = 0.0;

  final List<String> motivationalQuotes = [
    'Push yourself: "Push yourself because no one else is going to do it for you."',
    'Believe in yourself: "Believe you can and you’re halfway there."',
    'Stay positive: "Your limitation—it’s only your imagination."',
    'Work hard: "Hard work beats talent when talent doesn’t work hard."',
    'Never give up: "The harder you work for something, the greater you’ll feel when you achieve it."',
    'Stay focused: "Don’t stop when you’re tired. Stop when you’re done."',
    'Be consistent: "Success doesn’t come from what you do occasionally, it comes from what you do consistently."',
  ];

  // Initialize HealthFactory for accessing health data
  final health = Health();

  @override
  void initState() {
    super.initState();
    // Configure the health service and fetch initial data
    health.configure();
    _getBiometricData();
  }

  Future<void> _getBiometricData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw 'No user is logged in';
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _weight = userDoc.data()?['weight']?.toString() ?? 'N/A';
          _height = userDoc.data()?['height']?.toString() ?? 'N/A';
          _consistencyStreak = userDoc.data()?['consistencyStreak'] ?? 0;
          // Note: _caloriesBurnt and _steps will be fetched from HealthKit
        });
      } else {
        setState(() {
          _weight = 'N/A';
          _height = 'N/A';
          _consistencyStreak = 0;
        });
      }

      // Fetch health data (calories burnt and steps) from HealthKit
      await _fetchHealthData();

      // Fetch calories consumed data for the week from Firestore
      final caloriesConsumedData = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('calories_consumed')
          .orderBy('date', descending: true)
          .limit(7)
          .get();

      List<FlSpot> spots = [];
      for (var doc in caloriesConsumedData.docs) {
        DateTime date = (doc.data()['date'] as Timestamp).toDate();
        double calories = doc.data()['calories_consumed'].toDouble();
        spots.add(FlSpot(date.weekday.toDouble(), calories));
      }

      setState(() {
        _caloriesConsumedSpots = spots;
      });
    } catch (e) {
      setState(() {
        _weight = 'Error';
        _height = 'Error';
        _caloriesBurnt = 'Error';
        _steps = 'Error';
        _consistencyStreak = 0;
      });
      debugPrint('Error fetching biometric data: $e');
    }
  }

  Future<void> _fetchHealthData() async {
    try {
      // Request activity recognition permission on Android
      if (Platform.isAndroid) {
        await Permission.activityRecognition.request();
      }

      // Define health data types and permissions
      List<HealthDataType> types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ];
      List<HealthDataAccess> permissions =
          types.map((e) => HealthDataAccess.READ).toList();

      // Check if permissions are granted; request if not
      bool? hasPermissions =
          await health.hasPermissions(types, permissions: permissions);
      if (hasPermissions == null || !hasPermissions) {
        bool authorized =
            await health.requestAuthorization(types, permissions: permissions);
        if (!authorized) {
          setState(() {
            _caloriesBurnt = 'Permission denied';
            _steps = 'Permission denied';
          });
          return;
        }
      }

      // Define time range: today from midnight to now
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      // Fetch total steps today
      int? steps = await health.getTotalStepsInInterval(midnight, now);

      // Fetch calories burnt today
      List<HealthDataPoint> energyData = await health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );
      double caloriesBurnt = 0.0;
      for (var point in energyData) {
        if (point.value is NumericHealthValue) {
          caloriesBurnt += (point.value as NumericHealthValue).numericValue;
        }
      }

      // Fetch historical data to find the most calories burnt in a day
      final startOfYear = DateTime(now.year, 1, 1);
      List<HealthDataPoint> historicalEnergyData = await health.getHealthDataFromTypes(
        startTime: startOfYear,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );

      double mostCaloriesBurnt = 0.0;
      Map<DateTime, double> dailyCalories = {};

      for (var point in historicalEnergyData) {
        if (point.value is NumericHealthValue) {
          DateTime date = DateTime(point.dateFrom.year, point.dateFrom.month, point.dateFrom.day);
          dailyCalories[date] = (dailyCalories[date] ?? 0) + (point.value as NumericHealthValue).numericValue;
        }
      }

      // Clear the existing spots before adding new data
      _caloriesBurntSpots.clear();

      dailyCalories.forEach((date, calories) {
        if (calories > mostCaloriesBurnt) {
          mostCaloriesBurnt = calories;
        }
        _caloriesBurntSpots.add(FlSpot(date.weekday.toDouble(), calories));
      });

      // Update state with fetched data
      setState(() {
        _steps = steps?.toString() ?? '0';
        _caloriesBurnt = caloriesBurnt.toStringAsFixed(0);
        _mostCaloriesBurnt = mostCaloriesBurnt;
      });
    } catch (e) {
      setState(() {
        _caloriesBurnt = 'Error';
        _steps = 'Error';
      });
      debugPrint('Error fetching health data: $e');
    }
  }

  int _dayOfYear(DateTime date) {
    return int.parse(DateFormat("D").format(date));
  }

  String getDailyQuote() {
    int dayOfYear = _dayOfYear(DateTime.now());
    return motivationalQuotes[dayOfYear % motivationalQuotes.length];
  }

  Widget _buildUserCurrentDataSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(13.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: 'Weight: ',
                        style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    TextSpan(
                        text: '$_weight kg',
                        style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.normal,
                            color: Colors.black)),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: 'Height: ',
                        style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    TextSpan(
                        text: '$_height cm',
                        style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.normal,
                            color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.red),
              SizedBox(width: 10.0),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: 'Calories burnt today: ',
                        style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    TextSpan(
                        text: '$_caloriesBurnt kcal',
                        style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.normal,
                            color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Row(
            children: [
              Icon(Icons.directions_walk, color: Colors.blue),
              SizedBox(width: 10.0),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: 'Total steps today: ',
                        style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    TextSpan(
                        text: '$_steps steps',
                        style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.normal,
                            color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
          decoration: BoxDecoration(
            color: Colors.redAccent[100],
            borderRadius: BorderRadius.circular(13.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Achievements',
                style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: 10.0),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: 'Most calories burnt: ',
                        style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                    TextSpan(
                        text: '${_mostCaloriesBurnt.toInt()} kcal',
                        style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.normal,
                            color: Colors.black)),
                  ],
                ),
              ),
              SizedBox(height: 10.0),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: 'Consistency streak: ',
                        style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    TextSpan(
                        text: '$_consistencyStreak days',
                        style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.normal,
                            color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Image.asset(
          'assets/achievements.png',
          width: 90.0,
          height: 90.0,
        ),
      ],
    );
  }

  Widget _buildMotivationalQuoteSection() {
    String dailyQuote = getDailyQuote();
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        borderRadius: BorderRadius.circular(13.0),
      ),
      child: Text(
        dailyQuote,
        style: TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.deepOrangeAccent, 'Calories Consumed'),
          SizedBox(width: 20),
          _buildLegendItem(Colors.blueAccent, 'Calories Burnt'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.blueGrey),
        ),
      ],
    );
  }

  Widget _buildCaloriesOverviewChart() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Card(
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(left: 5.0, right: 15.0),
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    _buildCaloriesConsumedLineChartBarData(),
                    _buildCaloriesBurntLineChartBarData(),
                  ],
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 100,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.blueGrey[100],
                        strokeWidth: 0.5,
                        dashArray: [5],
                      );
                    },
                  ),
                  titlesData: _buildTitlesData(),
                ),
              ),
            ),
          ),
        ),
        _buildLegend(),
      ],
    );
  }

  LineChartBarData _buildCaloriesConsumedLineChartBarData() {
    return LineChartBarData(
        spots: _caloriesConsumedSpots,
        isCurved: true,
        color: Colors.deepOrangeAccent,
        barWidth: 4,
        belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(colors: [
              Colors.deepOrangeAccent.withOpacity(0.5),
              Colors.deepOrangeAccent.withOpacity(0.1),
            ])));
  }

  LineChartBarData _buildCaloriesBurntLineChartBarData() {
    return LineChartBarData(
        spots: _caloriesBurntSpots,
        isCurved: true,
        color: Colors.blueAccent,
        barWidth: 4,
        belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(colors: [
              Colors.blueAccent.withOpacity(0.5),
              Colors.blueAccent.withOpacity(0.1),
            ])));
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (value, meta) {
            switch (value.toInt()) {
              case 1:
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Mon',
                      style: TextStyle(fontSize: 10, color: Colors.red)),
                );
              case 2:
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Tue',
                      style: TextStyle(fontSize: 10, color: Colors.red)),
                );
              case 3:
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Wed',
                      style: TextStyle(fontSize: 10, color: Colors.red)),
                );
              case 4:
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Thu',
                      style: TextStyle(fontSize: 10, color: Colors.red)),
                );
              case 5:
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Fri',
                      style: TextStyle(fontSize: 10, color: Colors.red)),
                );
              case 6:
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Sat',
                      style: TextStyle(fontSize: 10, color: Colors.red)),
                );
              case 7:
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Sun',
                      style: TextStyle(fontSize: 10, color: Colors.red)),
                );
              default:
                return Text('');
            }
          },
          reservedSize: 30,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 100,
          minIncluded: false,
          maxIncluded: false,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: TextStyle(fontSize: 8.0, color: Colors.blueGrey),
            );
          },
          reservedSize: 30,
        ),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String todayDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            todayDate,
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 25.0, bottom: 5.0),
            child: MenuBarIcon(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 5.0),
          child: Column(
            children: [
              _buildUserCurrentDataSection(),
              SizedBox(height: 15.0),
              _buildAchievementSection(),
              SizedBox(height: 15.0),
              _buildMotivationalQuoteSection(),
              SizedBox(height: 18.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 10.0),
                  Text(
                    "Calories Overview",
                    style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: _getBiometricData,
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: Colors.blue[200],
                    ),
                    color: Colors.lightBlue[300],
                    tooltip: 'Refresh Data',
                  ),
                ],
              ),
              SizedBox(height: 15.0),
              _buildCaloriesOverviewChart(),
              SizedBox(height: 100.0),
            ],
          ),
        ),
      ),
    );
  }
}