import 'package:flutter/material.dart';
import 'package:rag_flutter_app/pages/chat_page.dart';
import 'package:rag_flutter_app/pages/meals_plan_page.dart';
import 'package:rag_flutter_app/pages/progress_page.dart';
import 'package:rag_flutter_app/pages/workout_plan_page.dart';
import '/services/globals.dart'; // Import the shared isDarkMode variable

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
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, darkMode, child) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10, left: 45, right: 45),
            decoration: BoxDecoration(
              color: darkMode ? Colors.grey[800] : const Color(0xFF008080),
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
                  _buildNavItem(Icons.restaurant, 0, darkMode),
                  _buildNavItemWithImage('assets/dumbell.png', 1, darkMode),
                  _buildNavItem(Icons.bar_chart, 2, darkMode),
                  _buildNavItem(Icons.chat_bubble_outline_rounded, 3, darkMode),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, int index, bool darkMode) {
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
        backgroundColor: _selectedIndex == index
            ? (darkMode ? Colors.white : const Color(0xFF81C0C0))
            : (darkMode ? Colors.grey[700] : const Color(0xFF81C0C0)),
        child: Icon(
          icon,
          size: 30,
          color: _selectedIndex == index
              ? (darkMode ? Colors.black : Colors.white)
              : (darkMode ? Colors.white70 : const Color(0xFF008080)),
        ),
      ),
    );
  }

  Widget _buildNavItemWithImage(String imagePath, int index, bool darkMode) {
    return GestureDetector(
      onTap: () {
        _onItemTapped(index);
      },
      child: CircleAvatar(
        radius: 28,
        backgroundColor: _selectedIndex == index
            ? (darkMode ? Colors.white : const Color(0xFF81C0C0))
            : (darkMode ? Colors.grey[700] : const Color(0xFF81C0C0)),
        child: Transform.rotate(
          angle: 3.14 / 2, // Rotate 90 degrees (π/2 radians)
          child: Image.asset(
            imagePath,
            width: 30,
            height: 30,
            color: _selectedIndex == index
                ? (darkMode ? Colors.black : Colors.white)
                : (darkMode ? Colors.white70 : const Color(0xFF008080)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, darkMode, child) {
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
          // Set a background color that adapts to dark mode.
          backgroundColor: darkMode ? Colors.black : Colors.grey[200],
        );
      },
    );
  }
}
