import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class MealsPlanPage extends StatelessWidget {
  const MealsPlanPage({super.key});

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

  /// Calculate total calories from breakfast, lunch, and dinner.
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

  Widget buildMealPlanCard(Map<String, dynamic> content, DateTime date) {
    final totalCalories = _calculateTotalCalories(content);

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
            // Header with Meal Plan title and total calories
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "MEAL PLAN",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  "Total Calories: $totalCalories kcal",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Meal sections
            _buildMealSection('Breakfast', content['breakfast']),
            _buildMealSection('Lunch', content['lunch']),
            _buildMealSection('Dinner', content['dinner']),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(String title, dynamic data) {
    if (data == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF008080),
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: (data['food_items'] as List).map<Widget>((item) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            "${data['calories']} kcal",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getLatestMealPlans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading meal plans"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No meal plans found"));
          }

          try {
            final mealPlan = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final rawContent = mealPlan['content'];
            final content = rawContent is String ? jsonDecode(rawContent) : rawContent;
            final date = (mealPlan['date'] as Timestamp).toDate();

            return ListView(
              padding: const EdgeInsets.all(10),
              children: [
                buildMealPlanCard(content, date),
              ],
            );
          } catch (e) {
            return const Center(child: Text("Error parsing meal plan"));
          }
        },
      ),
    );
  }
}
