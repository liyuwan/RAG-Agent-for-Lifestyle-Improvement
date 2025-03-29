import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../widgets/settings_button.dart';
import '/services/globals.dart'; // Import the globals file for isDarkMode
import '/services/api_service.dart'; // Import the ApiService class

class MealsPlanPage extends StatefulWidget {
  const MealsPlanPage({super.key});

  @override
  _MealsPlanPageState createState() => _MealsPlanPageState();
}

class _MealsPlanPageState extends State<MealsPlanPage> {
  DateTime selectedDate = DateTime.now();
  String username = '';
  int _totalCalories = 0;
  int caloriesConsumed = 0;
  Map<String, bool> _completedMeals = {};
  bool isGenerating = false;
  ApiService apiService = ApiService(baseUrl: 'http://127.0.0.1:5000');

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch the username and calories consumed data when the page loads
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

          final caloriesDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('calories_consumed')
              .doc(DateFormat('yyyy-MM-dd').format(selectedDate))
              .get();

          if (caloriesDoc.exists) {
            setState(() {
              caloriesConsumed = caloriesDoc['calories_consumed'] ?? 0;
              _completedMeals = Map<String, bool>.from(caloriesDoc['completed_meals'] ?? {});
            });
          }
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
        .collection('meal_plans')
        .where('target_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('target_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: true)
        .orderBy('target_date', descending: true)
        .limit(1)
        .snapshots();
  }

  /// Handle date selection
  void onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    _fetchUserData(); // Fetch the calories consumed data for the selected date
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
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.teal[50],
                  child: CircularProgressIndicator(color: Colors.teal),
                );
              }
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.teal[50],
                  backgroundImage: AssetImage("assets/default_profile.png"),
                );
              }
              String? profileImageUrl = snapshot.data!['profileImage'];
              return CircleAvatar(
                radius: 20,
                backgroundColor: Colors.teal[50],
                backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                    ? AssetImage(profileImageUrl)
                    : AssetImage("assets/default_profile.png"),
              );
            },
          ),
          SizedBox(width: 15),
          Text(
            "Welcome back,\n$username", // Display the username here
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode.value ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          SettingsButton(),
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
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: SizedBox(
            height: 90, // Increased height to accommodate the month text
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
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? (isDarkMode.value ? Colors.white30 : Colors.white) : Colors.transparent,
                      borderRadius: BorderRadius.circular(28), // Increased border radius
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat.MMM().format(date), // Short month name
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? (isDarkMode.value ? Colors.tealAccent : Colors.teal) : (isToday ? Colors.deepOrange[300] : (isDarkMode.value ? Colors.grey : Colors.black)),
                          ),
                        ),
                        Text(
                          "${date.day}",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isSelected ?  (isDarkMode.value ? Colors.tealAccent : Colors.teal) : (isToday ? Colors.deepOrange[400] : (isDarkMode.value ? Colors.grey : Colors.black)),
                          ),
                        ),
                        Text(
                          DateFormat.E().format(date), // Short day name
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ?  (isDarkMode.value ? Colors.tealAccent : Colors.teal) : (isToday ? Colors.deepOrange[300] : (isDarkMode.value ? Colors.grey : Colors.black)),
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

  Future<void> _saveCaloriesConsumed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('calories_consumed')
            .doc(DateFormat('yyyy-MM-dd').format(selectedDate))
            .set({
          'date': Timestamp.fromDate(selectedDate),
          'calories_consumed': caloriesConsumed,
          'completed_meals': _completedMeals,
        });
      } catch (e) {
        print('Error saving calories consumed: $e');
      }
    }
  }

  Widget buildMealsPlanGenerateButton(buttonText, isWeekly) {
    return ElevatedButton(
      onPressed: isGenerating
          ? null // Disable button when Generating
          : () async {
              setState(() => isGenerating = true);
              try {
                // Pass the selected date as the start_date parameter
                await apiService.getResponseFromApi(
                  "Update my meals plan",
                  isWeekly,
                  startDate: DateFormat('yyyy-MM-dd').format(selectedDate),
                );
              } finally {
                setState(() => isGenerating = false);
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode.value ? Colors.grey[850] : Colors.teal[400],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: isGenerating
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(buttonText,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              )),
    );
  }


  Widget _buildMealCard(String title, dynamic data, IconData icon) {
    if (data == null) return SizedBox.shrink();

    bool isToday = selectedDate.day == DateTime.now().day &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.year == DateTime.now().year;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        bool isCompleted = _completedMeals[title] ?? false;

        return ValueListenableBuilder<bool>(
          valueListenable: isDarkMode,
          builder: (context, darkMode, child) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: darkMode ? Colors.grey[800] : Colors.teal[50], // Adjusted for dark mode
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Upper part: icon and text side by side.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center, // Center the icon vertically
                          children: [
                            SizedBox(width: 10),
                            Icon(icon, color: darkMode ? Colors.white70 : Colors.grey[700], size: 28),
                            SizedBox(width: 25),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17,
                                      color: darkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: (data['food_items'] as List)
                                        .map<Widget>(
                                          (item) => Padding(
                                            padding: EdgeInsets.only(bottom: 4),
                                            child: Text(
                                              item,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: darkMode ? Colors.white70 : Colors.black,
                                              ),
                                            ),
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
                        Divider(
                          color: darkMode ? Colors.white24 : Colors.white70,
                          thickness: 3,
                        ),
                        SizedBox(height: 8),
                        // Lower part: calories information
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_fire_department_outlined,
                                color: darkMode ? Colors.orange[300] : Colors.black87),
                            SizedBox(width: 4),
                            Text(
                              "${data['calories']} kcal",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: darkMode ? Colors.orange[300] : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (isToday)
                      Positioned(
                        top: -15,
                        right: -10,
                        child: Checkbox(
                          shape: CircleBorder(),
                          value: isCompleted,
                          activeColor: darkMode ? Colors.white : Colors.teal,
                          checkColor: darkMode ? Colors.teal : Colors.white,
                          side: BorderSide(
                            color: darkMode ? Colors.white24 : Colors.grey, // Border color for inactive state
                            width: 2, // Thickness of the border
                          ),
                          onChanged: (bool? value) {
                            setState(() {
                              _completedMeals[title] = value ?? false;
                              if (value == true) {
                                caloriesConsumed += data['calories'] as int;
                              } else {
                                caloriesConsumed -= data['calories'] as int;
                              }
                              _saveCaloriesConsumed(); // Save the data to Firestore
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;// Declare totalCalories here
    bool isCurrentDay = selectedDate.day == DateTime.now().day &&
                        selectedDate.month == DateTime.now().month &&
                        selectedDate.year == DateTime.now().year;

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, darkMode, child) {
        return Scaffold(
          backgroundColor: darkMode ? Colors.grey[900] : Colors.white,
          body: Column(
            children: [
              SizedBox(
                height: screenHeight * 0.25, // Ensuring full 25% height
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image with reduced opacity
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.5, // Reduced opacity for better visibility in dark mode
                        child: SizedBox(
                          width: double.infinity,
                          child: Image.asset(
                            'assets/mealplan-banner.png', // Replace with your image path
                            fit: BoxFit.cover, // Ensures the image covers the entire area
                            alignment: Alignment.topCenter, // Aligns the image from the top
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay to create a fade effect at the bottom
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent, // Fully transparent at the top
                              darkMode ? Colors.grey[900]! : Colors.transparent, // Fade to background color
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Foreground content: Profile + Calendar
                    Column(
                      children: [
                        const SizedBox(height: 55),
                        buildProfileSection(),
                        const SizedBox(height: 20),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: darkMode ? Colors.white : Colors.black,
                        ),
                        children: [
                          const TextSpan(text: "Total Calories : "),
                          TextSpan(
                            text: "$_totalCalories kcal",
                            style: TextStyle(
                              color: Colors.orange[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: getMealPlansForDate(selectedDate),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      // Check if the selected date meets the conditions
                      final now = DateTime.now();
                      final isWithinOneWeek = selectedDate.isAfter(now) && selectedDate.difference(now).inDays <= 7;

                      if (isWithinOneWeek) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "No meal plans found",
                                style: TextStyle(
                                  color: darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 20),
                              buildMealsPlanGenerateButton("Generate a meals plan", "true"),
                              const SizedBox(height: 60),
                            ],
                          ),
                        );
                      } else {
                        return Center(
                          child: Text(
                            "No meal plans available for the selected date",
                            style: TextStyle(
                              color: darkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        );
                      }
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
                          if (isCurrentDay)
                            Padding(
                              padding: const EdgeInsets.only(right: 15, top: 15),
                              child: Row(
                                children: [
                                  const Spacer(),
                                  buildMealsPlanGenerateButton("Update", "false")
                                ],
                              ),
                            ),
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
                      return Center(
                        child: Text(
                          "Error parsing meal plan",
                          style: TextStyle(
                            color: darkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
