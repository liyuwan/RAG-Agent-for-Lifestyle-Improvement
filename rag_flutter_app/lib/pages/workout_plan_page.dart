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
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            "Welcome back!\n$username", // Display the username here
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
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
                      borderRadius: BorderRadius.circular(22), // Increased border radius
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
                            color: isSelected ? Colors.teal : (isToday ? Colors.teal : Colors.black),
                          ),
                        ),
                        Text( 
                          DateFormat.E().format(date), // Short day name
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.teal : (isToday ? Colors.teal : Colors.black),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.teal,
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
                  style: const TextStyle(
                    color: Colors.orangeAccent, // Set only the workout level text to orange
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
      final docId =
          data['id']; // Assuming Firestore doc ID is stored in the data

      return StatefulBuilder(
        builder: (context, setState) {
          bool isCompleted = data['completed'] ?? false; // Default to false

          return Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isCompleted
                  ? Colors.green.withOpacity(0.3)
                  : Colors.teal[50],
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 30, top: 10, right: 10, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Workout Plan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008989), // Header color changed to teal
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isCompleted ? Colors.green : Colors.grey,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            isCompleted = !isCompleted;
                          });
                          // Update Firestore when toggled
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('plans')
                              .doc(docId)
                              .update({'completed': isCompleted});
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: _buildWorkoutSection(content),
                  ),
                ],
              ),
            ),
          );
        },
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
                    'assets/workout.png', // Image path
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
