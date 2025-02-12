import 'package:flutter/material.dart';
import 'package:rag_flutter_app/pages/progress_page.dart';
import 'package:rag_flutter_app/pages/chat_page.dart';

class FloatingNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const FloatingNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 25,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Color(0xFF008080),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Prevents extra width
              children: [
                _buildNavItem(Icons.restaurant, 0, context),
                SizedBox(width: 20),
                _buildNavItem(Icons.fitness_center_outlined, 1, context),
                SizedBox(width: 20),
                _buildNavItem(Icons.bar_chart, 2, context),
                SizedBox(width: 20),
                _buildNavItem(Icons.chat_bubble_outline_rounded, 3, context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, int index, BuildContext context) {
    return GestureDetector(
      onTap: () {
        onItemTapped(index);
        _navigateToPage(index, context);
      },
      child: CircleAvatar(
        radius: 28,
        backgroundColor: selectedIndex == index ? Colors.white : Color(0xFF81C0C0),
        child: Icon(
          icon,
          size: 30,
          color: selectedIndex == index ? Color(0xFF008080) : Colors.black54,
        ),
      ),
    );
  }

  void _navigateToPage(int index, BuildContext context) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MealsPage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FitnessPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProgressPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatPage()),
        );
        break;
      default:
        break;
    }
  }
}

class MealsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Meals Page")),
      body: Center(child: Text("Welcome to the Meals Page")),
    );
  }
}

class FitnessPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fitness Page")),
      body: Center(child: Text("Welcome to the Fitness Page")),
    );
  }
}

class BarChartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bar Chart Page")),
      body: Center(child: Text("Welcome to the Bar Chart Page")),
    );
  }
}