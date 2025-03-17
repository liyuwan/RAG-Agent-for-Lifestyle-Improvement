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

  //From Firestore database
  String _weight = '';
  String _height = '';
  int _consistencyStreak = 0;
  List<FlSpot> _caloriesConsumedSpots = [];

  //From HealthKit
  String _caloriesBurnt = '';
  String _steps = '';
  double _mostCaloriesBurnt = 0.0;
  Map<DateTime, double> dailyCaloriesBurnt = {};
  List<FlSpot> _caloriesBurntSpots = [];

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
        });
      } else {
        setState(() {
          _weight = 'N/A';
          _height = 'N/A';
          _consistencyStreak = 0;
        });
      }

      // Calculate the start date for the last 7 days
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day - 6);

      // Fetch calories consumed data for the last 7 days from Firestore
      final startTimestamp = Timestamp.fromDate(startDate);
      final caloriesConsumedData = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('calories_consumed')
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .orderBy('date', descending: false)
          .get();

      Map<DateTime, double> caloriesConsumedMap = {};
      for (var doc in caloriesConsumedData.docs) {
        DateTime date = (doc.data()['date'] as Timestamp).toDate();
        date = DateTime(date.year, date.month, date.day); // Normalize to midnight
        double calories = doc.data()['calories_consumed'].toDouble();
        caloriesConsumedMap[date] = calories; // Assumes one entry per day; sum if multiple
      }

      // Fetch health data for the last 7 days
      await _fetchHealthData(startDate, now);

      // Generate spots for the last 7 days
      List<FlSpot> caloriesConsumedSpots = [];
      List<FlSpot> caloriesBurntSpots = [];
      for (int i = 0; i < 7; i++) {
        DateTime day = startDate.add(Duration(days: i));
        double consumed = caloriesConsumedMap[day] ?? 0.0; // 0 if no data
        double burnt = dailyCaloriesBurnt[day] ?? 0.0; // 0 if no data
        caloriesConsumedSpots.add(FlSpot(i.toDouble(), consumed));
        caloriesBurntSpots.add(FlSpot(i.toDouble(), burnt));
      }

      setState(() {
        _caloriesConsumedSpots = caloriesConsumedSpots;
        _caloriesBurntSpots = caloriesBurntSpots;
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

  Future<void> _fetchHealthData(DateTime startDate, DateTime now) async {
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

      // Fetch total steps today
      final midnight = DateTime(now.year, now.month, now.day);
      int? steps = await health.getTotalStepsInInterval(midnight, now);

      // Fetch calories burnt for the last 7 days
      List<HealthDataPoint> energyData = await health.getHealthDataFromTypes(
        startTime: startDate,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );

      Map<DateTime, double> dailyCaloriesBurntTemp = {};
      for (var point in energyData) {
        if (point.value is NumericHealthValue) {
          DateTime date = DateTime(
              point.dateFrom.year, point.dateFrom.month, point.dateFrom.day);
          double calories = (point.value as NumericHealthValue).numericValue.toDouble();
          dailyCaloriesBurntTemp[date] =
              (dailyCaloriesBurntTemp[date] ?? 0) + calories;
        }
      }

      // Calculate most calories burnt in the last 7 days
      double mostCaloriesBurnt = 0.0;
      dailyCaloriesBurntTemp.forEach((date, calories) {
        if (calories > mostCaloriesBurnt) {
          mostCaloriesBurnt = calories;
        }
      });

      // Update state with fetched data
      setState(() {
        _steps = steps?.toString() ?? '0';
        _caloriesBurnt = (dailyCaloriesBurntTemp[midnight] ?? 0).toStringAsFixed(0);
        _mostCaloriesBurnt = mostCaloriesBurnt;
        dailyCaloriesBurnt = dailyCaloriesBurntTemp; // Store for chart use
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
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day - 6);

    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (value, meta) {
            int index = value.toInt();
            if (index >= 0 && index < 7) {
              DateTime day = startDate.add(Duration(days: index));
              String weekday;
              switch (day.weekday) {
                case 1:
                  weekday = 'Mon';
                  break;
                case 2:
                  weekday = 'Tue';
                  break;
                case 3:
                  weekday = 'Wed';
                  break;
                case 4:
                  weekday = 'Thu';
                  break;
                case 5:
                  weekday = 'Fri';
                  break;
                case 6:
                  weekday = 'Sat';
                  break;
                case 7:
                  weekday = 'Sun';
                  break;
                default:
                  weekday = ''; // Shouldn’t happen
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  weekday,
                  style: TextStyle(fontSize: 10, color: Colors.red),
                ),
              );
            }
            return Text('');
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
      body: RefreshIndicator(
        onRefresh: _getBiometricData,
        child: SingleChildScrollView(
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
      ),
    );
  }
}