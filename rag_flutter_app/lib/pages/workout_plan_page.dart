import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/settings_button.dart';
import '/services/globals.dart'; // Import the globals file for isDarkMode
import 'dart:convert';

class WorkoutPlanPage extends StatefulWidget {
  const WorkoutPlanPage({super.key});

  @override
  _WorkoutPlanPageState createState() => _WorkoutPlanPageState();
}

class _WorkoutPlanPageState extends State<WorkoutPlanPage> {
  DateTime selectedDate = DateTime.now();
  String username = '';
  String workoutLevel = ''; // Store the workout level
  Map<String, bool> _completedExercises = {};

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

        final exercisesDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('exercise_completions')
            .doc(DateFormat('yyyy-MM-dd').format(selectedDate))
            .get();

        if (exercisesDoc.exists) {
          setState(() {
            _completedExercises = Map<String, bool>.from(exercisesDoc['completed_exercises'] ?? {});
          });
        } else {
          setState(() {
            _completedExercises = {}; // Reset if no data exists for the selected date
          });
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
      _completedExercises = {}; // Reset the completed exercises map
    });
    _fetchUserData(); // Fetch the completed exercises for the selected date
  }

  // Build user profile and menu section
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode.value ? Colors.white : Colors.black,
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

  Future<void> _saveCompletedExercises(String userId, DateTime targetDate, Map<String, bool> completedExercises, List<Map<String, dynamic>> allExercises) async {
    try {
      // Ensure all exercises are included
      for (var exercise in allExercises) {
        completedExercises.putIfAbsent(exercise['exercise'], () => false);
      }

      bool allCompleted = completedExercises.values.every((v) => v);

      // Fetch user data
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final data = userDoc.data() ?? {};
      
      int currentStreak = data['consistencyStreak'] ?? 0;
      int highestStreak = data['highestStreak'] ?? 0;
      DateTime? lastStreakDate = (data['lastStreakDate'] as Timestamp?)?.toDate();
      DateTime? highestStreakDate = (data['highestStreakDate'] as Timestamp?)?.toDate();

      // Helper function for date comparison
      bool isSameDay(DateTime? a, DateTime? b) {
        if (a == null || b == null) return false;
        return a.year == b.year && a.month == b.month && a.day == b.day;
      }

      // Calculate new values
      int newStreak = currentStreak;
      int newHighestStreak = highestStreak;
      DateTime? newLastStreakDate = lastStreakDate;
      DateTime? newHighestStreakDate = highestStreakDate;

      if (allCompleted) {
        // Handle exercise completion
        final isConsecutive = lastStreakDate != null && 
            targetDate.difference(lastStreakDate).inDays == 1;
        
        newStreak = isConsecutive ? currentStreak + 1 : 1;
        newLastStreakDate = targetDate;

        // Update highest streak only if new streak exceeds previous record
        if (newStreak > highestStreak) {
          newHighestStreak = newStreak;
          newHighestStreakDate = targetDate;
        }
      } else {
        // Handle exercise unchecking
        if (isSameDay(lastStreakDate, targetDate)) {
          // Only modify if unchecking the last streak day
          newStreak = currentStreak > 0 ? currentStreak - 1 : 0;
          newLastStreakDate = lastStreakDate?.subtract(Duration(days: 1));

          // Roll back highest streak only if it was set on the uncheck date
          if (isSameDay(highestStreakDate, targetDate)) {
            newHighestStreak = newStreak;
            newHighestStreakDate = newLastStreakDate;
          }
        }
      }

      // Update Firestore documents
      final completionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('exercise_completions')
          .doc(DateFormat('yyyy-MM-dd').format(targetDate));

      await completionsRef.set({
        'date': targetDate,
        'completed_exercises': completedExercises,
      });

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'consistencyStreak': newStreak,
        'lastStreakDate': newLastStreakDate != null 
            ? Timestamp.fromDate(newLastStreakDate)
            : null,
        'highestStreak': newHighestStreak,
        'highestStreakDate': newHighestStreakDate != null 
            ? Timestamp.fromDate(newHighestStreakDate)
            : null,
      });
    } catch (e) {
      print('Error saving exercises: $e');
    }
  }
  
  /// Build workout plan card with a toggleable checkmark
  Widget buildWorkoutPlanCard(Map<String, dynamic> data) {
    try {
      final rawContent = data['content'];
      final content =
          rawContent is String ? jsonDecode(rawContent) : rawContent;

      return ValueListenableBuilder<bool>(
        valueListenable: isDarkMode,
        builder: (context, darkMode, child) {
          return Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: darkMode ? Colors.grey[800] : Colors.teal[50],
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 30, top: 30, right: 10, bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      "Workout Plan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: darkMode ? Colors.white : Colors.black,
                      ),
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
        },
      );
    } catch (e) {
      return _buildErrorCard('Failed to load plan: ${e.toString()}');
    }
  }

  Widget _buildWorkoutSection(List<dynamic> exercises) {
    final List<Map<String, dynamic>> exercisesList = exercises.cast<Map<String, dynamic>>();
    bool isCurrentDay = selectedDate.day == DateTime.now().day &&
                        selectedDate.month == DateTime.now().month &&
                        selectedDate.year == DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: exercisesList.map((exercise) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10), // Adjust spacing
          child: Row(
            children: [
              if (isCurrentDay)
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    bool isCompleted = _completedExercises[exercise['exercise']] ?? false;
                    return Checkbox(
                      shape: CircleBorder(),
                      value: isCompleted,
                      activeColor: isDarkMode.value ? Colors.white : Colors.teal,
                      checkColor: isDarkMode.value ? Colors.teal : Colors.white,
                      side: BorderSide(
                        color: isDarkMode.value ? Colors.white24 : Colors.grey, // Border color for inactive state
                        width: 2, // Thickness of the border
                      ),
                      onChanged: (bool? value) {
                        setState(() {
                          _completedExercises[exercise['exercise']] = value ?? false;
                        });
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          _saveCompletedExercises(user.uid, selectedDate, _completedExercises, exercisesList);
                        }
                      },
                    );
                  },
                ),
              const SizedBox(width: 10), // Add some space between checkbox and text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['exercise'],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: isDarkMode.value ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      "${exercise['duration']} mins • ${exercise['intensity']}",
                      style: TextStyle(
                        color: isDarkMode.value ? Colors.white70 : Colors.grey[700], // Optional: Subtle color
                      ),
                    ),
                  ],
                ),
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

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, darkMode, child) {
        return Scaffold(
          backgroundColor: darkMode ? Colors.grey[900] : Colors.white,
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
                      child: Opacity(
                        opacity: 0.5,
                        child: SizedBox(
                          width: double.infinity,
                          child: Image.asset(
                            'assets/workoutplan-banner.png', // Image path
                            fit: BoxFit.none, // Ensures full width without cropping
                            alignment:
                                Alignment.topCenter, // Aligns the image from the top
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
                    // Foreground content: Profile + Calendar, ensuring they fill the space
                    Column(
                      children: [
                        const SizedBox(height: 55), // Adjust for status bar
                        buildProfileSection(), // Make it take up space
                        const SizedBox(height: 20), // Add some space between profile and calendar
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
                      return Center(
                        child: Text(
                          "No workout plans found",
                          style: TextStyle(
                            color: darkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      );
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
        );
      },
    );
  }
}
