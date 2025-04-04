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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, darkMode, child) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.only(
              bottom: screenHeight * 0.02, // 2% of screen height
              left: screenWidth * 0.1, // 10% of screen width
              right: screenWidth * 0.1, // 10% of screen width
            ),
            decoration: BoxDecoration(
              color: darkMode ? Colors.grey[800] : const Color(0xFF008080),
              borderRadius: BorderRadius.circular(screenWidth * 0.1), // 10% of screen width
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: screenWidth * 0.03, // 3% of screen width
                  spreadRadius: screenWidth * 0.005, // 0.5% of screen width
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.015, // 2% of screen width
                vertical: screenHeight * 0.01, // 1.5% of screen height
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.restaurant, 0, darkMode, screenWidth, screenHeight),
                  _buildNavItemWithImage('assets/dumbell.png', 1, darkMode, screenWidth, screenHeight),
                  _buildNavItem(Icons.bar_chart, 2, darkMode, screenWidth, screenHeight),
                  _buildNavItem(Icons.chat_bubble_outline_rounded, 3, darkMode, screenWidth, screenHeight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, int index, bool darkMode, double screenWidth, double screenHeight) {
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
        radius: screenWidth * 0.07, // 7% of screen width
        backgroundColor: _selectedIndex == index
            ? Colors.white
            : (darkMode ? Colors.grey[700] : const Color(0xFF81C0C0)),
        child: Icon(
          icon,
          size: screenWidth * 0.08, // 8% of screen width
          color: _selectedIndex == index
              ? (darkMode ? Colors.black : const Color(0xFF008080))
              : (darkMode ? Colors.white70 : const Color(0xFF008080)),
        ),
      ),
    );
  }

  Widget _buildNavItemWithImage(String imagePath, int index, bool darkMode, double screenWidth, double screenHeight) {
    return GestureDetector(
      onTap: () {
        _onItemTapped(index);
      },
      child: CircleAvatar(
        radius: screenWidth * 0.07, // 7% of screen width
        backgroundColor: _selectedIndex == index
            ? Colors.white
            : (darkMode ? Colors.grey[700] : const Color(0xFF81C0C0)),
        child: Transform.rotate(
          angle: 3.14 / 2, // Rotate 90 degrees (π/2 radians)
          child: Image.asset(
            imagePath,
            width: screenWidth * 0.08, // 8% of screen width
            height: screenWidth * 0.08, // 8% of screen width
            color: _selectedIndex == index
                ? (darkMode ? Colors.black : const Color(0xFF008080))
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
