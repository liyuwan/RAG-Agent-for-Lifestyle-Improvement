import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../widgets/menu_bar_icon.dart';

class MealsPlanPage extends StatefulWidget {
  const MealsPlanPage({super.key});

  @override
  _MealsPlanPageState createState() => _MealsPlanPageState();
}

class _MealsPlanPageState extends State<MealsPlanPage> {
  DateTime selectedDate = DateTime.now();
  String username = '';
  int _totalCalories = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch the username when the page loads
  }

  // Fetch the username from Firestore
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            username = userDoc['name'] ?? 'User';
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  Stream<QuerySnapshot> getMealPlansForDate(DateTime selectedDate) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.empty();

    // Define the start and end of the selected date
    final startOfDay = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0, 0);
    final endOfDay = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, 23, 59, 59, 999);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('meal_plans') // Changed from 'plans' to 'meal_plans'
        .where('target_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('target_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('target_date', descending: true)
        .limit(1)
        .snapshots();
  }

  /// Handle date selection
  void onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  int _calculateTotalCalories(Map<String, dynamic> content) {
    int total = 0;
    final mealKeys = ['breakfast', 'lunch', 'dinner'];
    for (var mealKey in mealKeys) {
      if (content[mealKey] != null && content[mealKey]['calories'] != null) {
        total += content[mealKey]['calories'] as int;
      }
    }
    return total;
  }

  Widget buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Row(
        children: [
          Text(
            "Welcome back,\n$username", // Display the username here
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey[800]),
          ),
          const Spacer(),
          MenuBarIcon(),
        ],
      ),
    );
  }

  Widget buildCalendar() {
    // Calculate the first and last day of the current month
    DateTime now = DateTime.now();
    DateTime firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
    DateTime lastDayOfCurrentMonth = DateTime(now.year, now.month + 1, 0);

    // Calculate the first and last day of the next month
    DateTime firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);
    DateTime lastDayOfNextMonth = DateTime(now.year, now.month + 2, 0);

    // Calculate the total number of days to display
    int totalDays = lastDayOfCurrentMonth.day + lastDayOfNextMonth.day;

    // Calculate the index of the selected date
    int todayIndex = selectedDate.isBefore(firstDayOfNextMonth)
        ? selectedDate.day - 1
        : lastDayOfCurrentMonth.day + selectedDate.day - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 35, top: 15, bottom: 8),
          child: Text(
            DateFormat.yMMMM().format(selectedDate),
            style: TextStyle(
              fontSize: 17, // Increased font size
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalDays,
              controller: ScrollController(
                initialScrollOffset: (todayIndex * 50).toDouble() - MediaQuery.of(context).size.width / 2 + 25,
              ),
              itemBuilder: (context, index) {
                DateTime date;
                if (index < lastDayOfCurrentMonth.day) {
                  date = firstDayOfCurrentMonth.add(Duration(days: index));
                } else {
                  date = firstDayOfNextMonth.add(Duration(days: index - lastDayOfCurrentMonth.day));
                }

                bool isSelected = date.day == selectedDate.day && date.month == selectedDate.month && date.year == selectedDate.year;
                bool isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;

                return GestureDetector(
                  onTap: () => onDateSelected(date),
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(16), // Increased border radius
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${date.day}",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.teal : (isToday ? Colors.deepOrange[400] : Colors.black),
                          ),
                        ),
                        Text( 
                          DateFormat.E().format(date), // Short day name
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.teal : (isToday ? Colors.deepOrange[300] : Colors.black),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.teal[200],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(String title, dynamic data, IconData icon) {
    if (data == null) return SizedBox.shrink();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.teal[50],
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Upper part: icon and text side by side.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Center the icon vertically
              children: [
                SizedBox(width: 10),
                Icon(icon, color: Colors.grey[700], size: 28),
                SizedBox(width: 25),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
                      ),
                      SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (data['food_items'] as List)
                            .map<Widget>(
                              (item) => Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(item, style: TextStyle(fontSize: 13)),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(color: Colors.white70, thickness: 3,),
            SizedBox(height: 8),
            // Lower part: calories information
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department_outlined, color: Colors.black87),
                SizedBox(width: 4),
                Text(
                  "${data['calories']} kcal",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;// Declare totalCalories here

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: screenHeight * 0.25, // Ensuring full 25% height
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image (Positioned to align from top)
                Positioned.fill(
                  child: Image.asset(
                    'assets/mealplan-banner.png', // Replace with your image path
                    fit: BoxFit.none, // Ensures full width without cropping
                    alignment:
                        Alignment.topCenter, // Aligns the image from the top
                  ),
                ),

                // Foreground content: Profile + Calendar, ensuring they fill the space
                Column(
                  children: [
                    const SizedBox(height: 55),
                    buildProfileSection(),
                    buildCalendar(),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.local_fire_department_outlined,
                    color: Colors.redAccent, size: 30),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black, // Default text color
                    ),
                    children: [
                      const TextSpan(text: "Total Calories : "), // Normal text
                      TextSpan(
                        text: "$_totalCalories kcal", // The variable part (e.g., "Moderate")
                        style: TextStyle(
                          color: Colors.orange[400], // Set only the workout level text to orange
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getMealPlansForDate(selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No meal plans found"));
                }
                try {
                  final mealPlan =
                      snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  final rawContent = mealPlan['content'];
                  final content = rawContent is String
                      ? jsonDecode(rawContent)
                      : rawContent;
                  final int calculatedCalories = _calculateTotalCalories(content);

                  if (_totalCalories != calculatedCalories) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _totalCalories = calculatedCalories;
                      });
                    });
                  }
                  return ListView(
                    padding: EdgeInsets.all(10),
                    children: [
                      _buildMealCard("Breakfast", content['breakfast'],
                          Icons.free_breakfast_outlined),
                      _buildMealCard(
                          "Lunch", content['lunch'], Icons.lunch_dining_outlined),
                      _buildMealCard(
                          "Dinner", content['dinner'], Icons.dinner_dining_outlined),
                      const SizedBox(height: 100),
                    ],
                  );
                } catch (e) {
                  return Center(child: Text("Error parsing meal plan"));
                }
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
