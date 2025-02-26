import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:rag_flutter_app/pages/login_page.dart';
import 'package:rag_flutter_app/pages/profile_page.dart';
import 'package:rag_flutter_app/widgets/menu_bar_icon.dart';

class MealsPlanPage extends StatefulWidget {
  const MealsPlanPage({super.key});

  @override
  _MealsPlanPageState createState() => _MealsPlanPageState();
}

class _MealsPlanPageState extends State<MealsPlanPage> {
  DateTime selectedDate = DateTime.now();

  String get userId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? '';
  }

  Stream<QuerySnapshot> getLatestMealPlans() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('plans')
        .where('type', isEqualTo: 'meal')
        .orderBy('date', descending: true)
        .snapshots();
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

  Widget _buildCalendar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        DateTime date = DateTime.now().subtract(Duration(days: 3 - index));
        return GestureDetector(
          onTap: () => setState(() => selectedDate = date),
          child: Column(
            children: [
              Text(
                DateFormat('E').format(date),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selectedDate == date ? Colors.teal : Colors.black,
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 5),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      selectedDate == date ? Colors.teal : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selectedDate == date ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMealCard(String title, dynamic data, IconData icon) {
    if (data == null) return SizedBox.shrink();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal, size: 30),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (data['food_items'] as List)
                  .map<Widget>(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(item, style: TextStyle(fontSize: 14)),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 8),
            Text(
              "${data['calories']} kcal",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.teal),
            SizedBox(width: 10),
            Text("Welcome back!"),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert), // Vertical three dots icon
            onSelected: (value) {
              switch (value) {
                case 'Profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()),
                  );
                  break;
                case 'Settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                  );
                  break;
                case 'Logout':
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Profile', 'Settings', 'Logout'}.map((String choice) {
                IconData icon;
                Color iconColor = const Color(0xFF008080);
                switch (choice) {
                  case 'Profile':
                    icon = Icons.account_circle;
                    iconColor = iconColor;
                    break;
                  case 'Settings':
                    icon = Icons.settings;
                    iconColor = iconColor;
                    break;
                  case 'Logout':
                    icon = Icons.exit_to_app;
                    iconColor = Colors.red;
                    break;
                  default:
                    icon = Icons.help;
                }

                return PopupMenuItem<String>(
                  value: choice,
                  padding:
                      EdgeInsets.zero, // Remove any padding to prevent spacing
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Wrapping CircleAvatar with a Container for the shadow effect
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.3), // Shadow color
                              blurRadius: 10.0, // Blurry effect
                              spreadRadius: 1.0, // Spread of the shadow
                              offset: Offset(3, 3), // Position of the shadow
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor:
                              Colors.grey[200], // Set a color if needed
                          radius: 20,
                          child: Icon(icon, color: iconColor),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
            color: Colors
                .transparent, // Make the background of the popup transparent
            elevation: 0, // Remove the shadow effect of the menu
            offset: const Offset(30, 30),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: _buildCalendar(),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getLatestMealPlans(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error loading meal plans"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No meal plans found"));
                }
                try {
                  final mealPlan =
                      snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  final rawContent = mealPlan['content'];
                  final content = rawContent is String
                      ? jsonDecode(rawContent)
                      : rawContent;
                  final totalCalories = _calculateTotalCalories(content);

                  return ListView(
                    padding: EdgeInsets.all(10),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Total Calories: $totalCalories kcal",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildMealCard("Breakfast", content['breakfast'],
                          Icons.free_breakfast),
                      _buildMealCard(
                          "Lunch", content['lunch'], Icons.lunch_dining),
                      _buildMealCard(
                          "Dinner", content['dinner'], Icons.dinner_dining),
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
    );
  }
}
