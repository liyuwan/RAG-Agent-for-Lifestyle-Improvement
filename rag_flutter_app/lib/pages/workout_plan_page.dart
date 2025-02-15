import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:convert'; // For decoding JSON

class WorkoutPlanPage extends StatelessWidget {
  const WorkoutPlanPage({super.key});

  /// Get the current user ID with null safety.
  String get userId {
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
                children: [
                  const Text(
                    "WORKOUT PLAN",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat.yMMMd().add_jm().format(date),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const Divider(),
              _buildWorkoutSection(content),
            ],
          ),
        ),
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
      ),
    );
  }
}
