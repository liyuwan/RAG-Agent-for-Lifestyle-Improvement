import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../widgets/menu_bar_icon.dart';

class WorkoutPlanPage extends StatefulWidget {
  const WorkoutPlanPage({super.key});

  @override
  _WorkoutPlanPageState createState() => _WorkoutPlanPageState();
}

class _WorkoutPlanPageState extends State<WorkoutPlanPage> {
  DateTime selectedDate = DateTime.now();
  String username = '';
  String workoutLevel = ''; // Store the workout level

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch the username and workout level when the page loads
  }

  // Fetch the username and workout level from Firestore
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final fetchedWorkoutLevel =
              userDoc['workoutLevelString'] ?? 'Moderate';

          if (mounted) {
            setState(() {
              username = userDoc['name'] ?? 'User';
              workoutLevel = fetchedWorkoutLevel;
            });
          }
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  /// Fetch workout plans for the selected date
  Stream<QuerySnapshot> getWorkoutPlansForDate(DateTime selectedDate) {
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
        .collection('workout_plans')
        .where('type', isEqualTo: 'workout')
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

  // Build user profile and menu section
  Widget buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Row(
        children: [
          Text(
            "Welcome back,\n$username", // Display the username here
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey[200]),
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
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: SizedBox(
            height: 90,
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
                      color: isSelected ? Colors.white : Colors.transparent,
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
                            color: isSelected ? Colors.lightGreen : (isToday ? Colors.deepOrange[300] : Colors.black),
                          ),
                        ),
                        Text(
                          "${date.day}",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.lightGreen : (isToday ? Colors.deepOrange[400] : Colors.black),
                          ),
                        ),
                        Text( 
                          DateFormat.E().format(date), // Short day name
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.lightGreen : (isToday ? Colors.deepOrange[300] : Colors.black),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
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

  // Build the workout level sentence
  Widget buildWorkoutLevel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Dumbbell icon
          Image.asset(
            'assets/dumbell.png', // Ensure the image exists in assets folder
            width: 28, // Adjust size as needed
            height: 28,
            color: Colors.deepOrangeAccent,
          ),
          const SizedBox(width: 8), // Spacing between icon and text
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black, // Default text color
              ),
              children: [
                const TextSpan(text: "Workout level : "), // Normal text
                TextSpan(
                  text: workoutLevel, // The variable part (e.g., "Moderate")
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
    );
  }

  /// Build workout plan card with a toggleable checkmark
  Widget buildWorkoutPlanCard(Map<String, dynamic> data) {
    try {
      final rawContent = data['content'];
      final content =
          rawContent is String ? jsonDecode(rawContent) : rawContent;

      return Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.blueGrey[50],
        ),
        child: Padding(
          padding: const EdgeInsets.only(
              left: 30, top: 30, right: 10, bottom: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Workout Plan",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightGreen, // Header color changed to teal
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30, top: 10),
                child: _buildWorkoutSection(content),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return _buildErrorCard('Failed to load plan: ${e.toString()}');
    }
  }

  Widget _buildWorkoutSection(List<dynamic> exercises) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: exercises.map((exercise) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10), // Adjust spacing
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise['exercise'],
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              Text(
                "${exercise['duration']} mins • ${exercise['intensity']}",
                style: TextStyle(
                    color: Colors.grey[700]), // Optional: Subtle color
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build an error card
  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(error, style: const TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // Section covering 30% of the screen with a background image
          SizedBox(
            height: screenHeight * 0.25, 
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image (Positioned to align from top)
                Positioned.fill(
                  child: Image.asset(
                    'assets/workoutplan-banner.png', // Image path
                    fit: BoxFit.none, // Ensures full width without cropping
                    alignment:
                        Alignment.topCenter, // Aligns the image from the top
                  ),
                ),

                // Foreground content: Profile + Calendar, ensuring they fill the space
                Column(
                  children: [
                    const SizedBox(height: 55), // Adjust for status bar
                    buildProfileSection(), // Make it take up space
                    const SizedBox(height: 22), // Add some space between profile and calendar
                    buildCalendar(), // Ensure calendar fills space
                  ],
                ),
              ],
            ),
          ),
          buildWorkoutLevel(), // Add workout level before workout cards
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getWorkoutPlansForDate(selectedDate),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No workout plans found for this date"));
                }

                return ListView(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  children: [
                    ...snapshot.data!.docs.map((doc) {
                      return buildWorkoutPlanCard(
                          doc.data() as Map<String, dynamic>);
                    }),
                    const SizedBox(height: 100), // Add some space at the end
                  ],
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
