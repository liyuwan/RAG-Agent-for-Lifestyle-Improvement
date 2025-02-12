import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // For decoding JSON content

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

  Widget buildMealPlanCard(Map<String, dynamic> content, DateTime date) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.green[50],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan type and date header
            Row(
              children: [
                const Text(
                  "MEAL PLAN",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  "${date.day}/${date.month}/${date.year}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const Divider(),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            "Items: ${(data['food_items'] as List).join(', ')}",
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            "Calories: ${data['calories']}",
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meal Plans"),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getLatestMealPlans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error: ${snapshot.error}"); // Log the error
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
            print("Error parsing meal plan: $e"); // Log the parsing error
            return const Center(child: Text("Error parsing meal plan"));
          }
        },
      ),
    );
  }
}