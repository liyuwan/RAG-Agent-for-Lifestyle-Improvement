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
        .collection('plans')
        .where('type', isEqualTo: 'workout')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          MenuBarIcon(),
        ],
      ),
    );
  }

  Widget buildCalendar() {
    DateTime firstDayOfMonth =
        DateTime(selectedDate.year, selectedDate.month, 1);
    DateTime lastDayOfMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0);
    int todayIndex = selectedDate.day - 1;

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: lastDayOfMonth.day,
        controller: ScrollController(
          initialScrollOffset: (todayIndex * 50).toDouble(),
        ),
        itemBuilder: (context, index) {
          DateTime date = firstDayOfMonth.add(Duration(days: index));
          bool isSelected = date.day == selectedDate.day;

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(16), // Increased border radius
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${date.day}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.teal : Colors.black,
                    ),
                  ),
                  Text(
                    DateFormat.E().format(date), // Short day name
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.teal : Colors.black,
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
    );
  }

  // Build the workout level sentence
  Widget buildWorkoutLevel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Dumbbell icon
          Image.asset(
            'assets/dumbell.png', // Ensure the image exists in assets folder
            width: 24, // Adjust size as needed
            height: 24,
          ),
          const SizedBox(width: 8), // Spacing between icon and text
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black, // Default text color
              ),
              children: [
                const TextSpan(text: "Workout level : "), // Normal text
                TextSpan(
                  text: workoutLevel, // The variable part (e.g., "Moderate")
                  style: const TextStyle(
                    color: Colors
                        .orange, // Set only the workout level text to orange
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
              borderRadius: BorderRadius.circular(8),
              color: isCompleted
                  ? Colors.green.withOpacity(0.3)
                  : Colors.teal.withOpacity(0.1),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 20, top: 10, right: 10, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "WORKOUT PLAN",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal, // Header color changed to teal
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
                  // Removed Divider here
                  _buildWorkoutSection(content),
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
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            height: screenHeight * 0.25, // Ensuring full 25% height
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image (Positioned to align from top)
                Positioned.fill(
                  child: Image.asset(
                    'assets/workout.png', // Replace with your image path
                    fit: BoxFit.none, // Ensures full width without cropping
                    alignment:
                        Alignment.topCenter, // Aligns the image from the top
                  ),
                ),

                // Foreground content: Profile + Calendar, ensuring they fill the space
                Column(
                  children: [
                    const SizedBox(height: 40), // Adjust for status bar
                    Expanded(
                        child: buildProfileSection()), // Make it take up space
                    const SizedBox(height: 8),
                    Expanded(
                        child: buildCalendar()), // Ensure calendar fills space
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
                  children: snapshot.data!.docs.map((doc) {
                    return buildWorkoutPlanCard(
                        doc.data() as Map<String, dynamic>);
                  }).toList(),
                );
              },
            ),
          ),
          SizedBox(
            height: 100,
          )
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
