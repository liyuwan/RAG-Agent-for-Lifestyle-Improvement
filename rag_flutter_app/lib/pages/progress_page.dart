import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/menu_bar_icon.dart';

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
  int _consistencyStreak = 0; // Add this line

  final List<String> motivationalQuotes = [
    'Push yourself: "Push yourself because no one else is going to do it for you."',
    'Believe in yourself: "Believe you can and you’re halfway there."',
    'Stay positive: "Your limitation—it’s only your imagination."',
    'Work hard: "Hard work beats talent when talent doesn’t work hard."',
    'Never give up: "The harder you work for something, the greater you’ll feel when you achieve it."',
    'Stay focused: "Don’t stop when you’re tired. Stop when you’re done."',
    'Be consistent: "Success doesn’t come from what you do occasionally, it comes from what you do consistently."',
  ];

  @override
  void initState() {
    super.initState();
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
          _caloriesBurnt = userDoc.data()?['caloriesBurnt']?.toString() ?? 'N/A';
          _steps = userDoc.data()?['steps']?.toString() ?? 'N/A';
          _consistencyStreak = userDoc.data()?['consistencyStreak'] ?? 0; // Add this line
        });

        // Fetch calories consumed data for the week
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
      } else {
        setState(() {
          _weight = 'N/A';
          _height = 'N/A';
          _caloriesBurnt = 'N/A';
          _steps = 'N/A';
          _consistencyStreak = 0; // Add this line
        });
      }
    } catch (e) {
      setState(() {
        _weight = 'Error';
        _height = 'Error';
        _caloriesBurnt = 'Error';
        _steps = 'Error';
        _consistencyStreak = 0; // Add this line
      });
      debugPrint('Error fetching biometric data: $e');
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
                    TextSpan(text: 'Weight: ', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.black)),
                    TextSpan(text: '$_weight kg', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.normal, color: Colors.black)),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Height: ', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.black)),
                    TextSpan(text: '$_height cm', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.normal, color: Colors.black)),
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
                    TextSpan(text: 'Calories burnt today: ', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.black)),
                    TextSpan(text: '$_caloriesBurnt kcal', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.normal, color: Colors.black)),
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
                    TextSpan(text: 'Total steps today: ', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.black)),
                    TextSpan(text: '$_steps steps', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.normal, color: Colors.black)),
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
                style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 10.0),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Most calories burnt: ', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600, color: Colors.black)),
                    TextSpan(text: 'static', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.normal, color: Colors.black)),
                  ],
                ),
              ),
              SizedBox(height: 10.0),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Consistency streak: ', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.black)),
                    TextSpan(text: '$_consistencyStreak days', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.normal, color: Colors.black)), // Update this line
                  ],
                ),
              ),
            ],
          ),
        ),
        Image.asset(
          'assets/achievements.png', // Make sure to add the trophy image in the assets folder
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
        style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCaloriesConsumedChart() {
    return SizedBox(
      height: 200,
      child: Card(
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: LineChart(
            LineChartData(
              lineBarsData: [_buildLineChartBarData()],
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
    );
  }

  LineChartBarData _buildLineChartBarData() {
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
        ])
      )
    );
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
                  padding: const EdgeInsets.only(top: 8.0), // Add padding to move the titles away from the chart
                  child: Text('Mon', style: TextStyle(fontSize: 10, color: Colors.red)),
                );
              case 2:
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0), // Add padding to move the titles away from the chart
                  child: Text('Tue', style: TextStyle(fontSize: 10, color: Colors.red)),
                );
              case 3:
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0), // Add padding to move the titles away from the chart
                  child: Text('Wed', style: TextStyle(fontSize: 10, color: Colors.red)),
                );
              case 4:
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0), // Add padding to move the titles away from the chart
                  child: Text('Thu', style: TextStyle(fontSize: 10, color: Colors.red)),
                );
              case 5:
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0), // Add padding to move the titles away from the chart
                  child: Text('Fri', style: TextStyle(fontSize: 10, color: Colors.red)),
                );
              case 6:
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0), // Add padding to move the titles away from the chart
                  child: Text('Sat', style: TextStyle(fontSize: 10, color: Colors.red)),
                );
              case 7:
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0), // Add padding to move the titles away from the chart
                  child: Text('Sun', style: TextStyle(fontSize: 10, color: Colors.red)),
                );
              default:
                return Text('');
            }
          },
          reservedSize: 30, // Reserve space to move the titles away from the chart
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
              style: TextStyle(fontSize: 8.0, color: Colors.blueGrey) // Reduce font size,
            );
          },
          reservedSize: 30, // Reserve space for left titles
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
    String todayDate = DateFormat('MMMM dd, yyyy').format(DateTime.now()); // Format today's date

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal margin
          child: Text(
            todayDate,
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500), // Reduce font size
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 25.0, bottom: 5.0), // Adjust padding as needed
            child: MenuBarIcon(), // Your custom icon
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
          child: Column(
            children: [
              _buildUserCurrentDataSection(),
              SizedBox(height: 15.0), // Add some space between sections
              _buildAchievementSection(),
              SizedBox(height: 15.0), // Add some space between sections
              _buildMotivationalQuoteSection(),
              SizedBox(height: 18.0), // Add some space between sections
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 10.0),
                  Text(
                    "Calories Consumed Chart",
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: _getBiometricData,
                    icon: Icon(Icons.refresh_rounded, color: Colors.blue[200],),
                    color: Colors.lightBlue[300],
                    tooltip: 'Refresh Data',
                    
                  ),
                ],
              ),
              SizedBox(height: 15.0), // Add some space between sections
              _buildCaloriesConsumedChart(),
              SizedBox(height: 100.0), // Add some space between sections
            ],
          ),
        ),
      ),
    );
  }
}
