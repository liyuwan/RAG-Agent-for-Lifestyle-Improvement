import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/menu_bar_icon.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
         flexibleSpace: Stack(
          children: [
            Positioned(
              right: 25, // Move the icon to the right
              bottom: 5, // Move the icon a little bit down
              child: MenuBarIcon(), // Your custom icon
            ),
          ],
        ),
      ),
      // Add your body content here if needed
    );
  }
}
