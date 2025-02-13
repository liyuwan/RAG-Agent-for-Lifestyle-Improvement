import 'package:flutter/material.dart';
import 'package:rag_flutter_app/pages/chat_page.dart';
import 'package:rag_flutter_app/pages/meals_plan_page.dart';
import 'package:rag_flutter_app/pages/workout_plan_page.dart';


// Dummy page for Progress

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Progress Content"));
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // List of pages for the tabs.
  final List<Widget> _pages = const [
    MealsPlanPage(),
    WorkoutPlanPage(),
    ProgressPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // This builds a custom "floating" bottom nav bar.
  Widget _buildFloatingNavBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 45, right: 45),
        decoration: BoxDecoration(
          color: const Color(0xFF008080),
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.restaurant, 0),
              _buildNavItem(Icons.fitness_center_outlined, 1),
              _buildNavItem(Icons.bar_chart, 2),
              _buildNavItem(Icons.chat_bubble_outline_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        if (index == 3) {
          // For Chat page, navigate to a separate route
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatPage()),
          );
        } else {
          _onItemTapped(index);
        }
      },
      child: CircleAvatar(
        radius: 28,
        backgroundColor: _selectedIndex == index ? Colors.white : const Color(0xFF81C0C0),
        child: Icon(
          icon,
          size: 30,
          color: _selectedIndex == index ? const Color(0xFF008080) : Colors.black54,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a Stack to allow the nav bar to "float" over the content.
      body: Stack(
        children: [
          // The main content area uses an IndexedStack to preserve state.
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          // The custom floating nav bar.
          _buildFloatingNavBar(),
        ],
      ),
      // Optional: Set a background color so the floating nav bar stands out.
      backgroundColor: Colors.grey[200],
    );
  }
}
