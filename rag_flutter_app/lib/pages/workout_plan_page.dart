import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:convert'; // For decoding JSON

class WorkoutPlanPage extends StatelessWidget {
  const WorkoutPlanPage({super.key});

<<<<<<< HEAD
  @override
  _WorkoutPlanPageState createState() => _WorkoutPlanPageState();
}

class _WorkoutPlanPageState extends State<WorkoutPlanPage> {
  DateTime selectedDate = DateTime.now();
  String username = '';

  @override
  void initState() {
    super.initState();
    _fetchUsername(); // Fetch the username when the page loads
  }

  // Fetch the username from Firestore
  Future<void> _fetchUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            username =
                userDoc['username'] ?? 'User'; // Default to 'User' if not found
          });
        }
      } catch (e) {
        print('Error fetching username: $e');
      }
    }
  }

  /// Fetch workout plans for the selected date
  Stream<QuerySnapshot> getWorkoutPlansForDate(DateTime selectedDate) {
=======
  /// Get the current user ID with null safety.
  String get userId {
>>>>>>> parent of 420eafe (Workout page)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    return user.uid;
  }

  /// Fetch only the latest workout plans from Firestore.
  Stream<QuerySnapshot> getLatestWorkoutPlans() {
    if (userId.isEmpty) {
      return Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('plans')
        .where('type', isEqualTo: 'workout') // Filter for workout plans only
        .orderBy('date', descending: true)
        .limit(1)
        .snapshots();
  }

<<<<<<< HEAD
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
          IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () {}, // TODO: Add menu functionality
          ),
        ],
      ),
    );
  }

  /// Build horizontal scrollable calendar
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
                color: isSelected ? Colors.teal : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E().format(date), // Short day name
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    "${date.day}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
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

  /// Build workout plan card
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
              border: Border.all(color: Colors.teal, width: 2),
              borderRadius: BorderRadius.circular(8),
              color: isCompleted
                  ? Colors.green.withOpacity(0.3)
                  : Colors.teal.withOpacity(0.1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
=======
  /// Build the workout plan card.
  Widget buildWorkoutPlanCard(Map<String, dynamic> data) {
    try {
      final rawContent = data['content'];
      final content = rawContent is String ? jsonDecode(rawContent) : rawContent;
      final date = (data['date'] as Timestamp).toDate();

      return Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF008080), width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Color(0xFF008080).withOpacity(0.1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and date
              Row(
>>>>>>> parent of 420eafe (Workout page)
                children: [
                  Row(
                    children: [
                      const Text(
                        "WORKOUT PLAN",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                  const Divider(),
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

  /// Build the workout section showing a list of exercises.
  Widget _buildWorkoutSection(List<dynamic> exercises) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: exercises.map((exercise) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(exercise['exercise']),
            subtitle: Text("${exercise['duration']} mins • ${exercise['intensity']}"),
          ),
        );
      }).toList(),
    );
  }

  /// Build an error card if something goes wrong.
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
<<<<<<< HEAD
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
                    fit: BoxFit.fitWidth, // Ensures full width without cropping
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
          const SizedBox(height: 16),
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
                  padding: const EdgeInsets.all(10),
                  children: snapshot.data!.docs.map((doc) {
                    return buildWorkoutPlanCard(
                        doc.data() as Map<String, dynamic>);
                  }).toList(),
                );
              },
            ),
          ),
        ],
=======
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getLatestWorkoutPlans(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No workout plans found"));
          }

          // Build workout plan cards for each document
          final planCards = snapshot.data!.docs.map((doc) {
            return buildWorkoutPlanCard(doc.data() as Map<String, dynamic>);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(10),
            children: planCards,
          );
        },
>>>>>>> parent of 420eafe (Workout page)
      ),
    );
  }
}
