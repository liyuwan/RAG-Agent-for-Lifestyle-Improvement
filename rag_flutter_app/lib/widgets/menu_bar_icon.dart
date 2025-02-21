import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/pages/login_page.dart';
import '/pages/profile_page.dart';

// Define the new MenuBarIcon widget
class MenuBarIcon extends StatelessWidget {
  const MenuBarIcon ({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert), // Vertical three dots icon
      onSelected: (value) {
        switch (value) {
          case 'Profile':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
            break;
          case 'Settings':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
            break;
          case 'Logout':
            FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return {'Profile', 'Settings', 'Logout'}.map((String choice) {
          IconData icon;
          Color iconColor = const Color(0xFF008080); // Teal color
          switch (choice) {
            case 'Profile':
              icon = Icons.account_circle;
              break;
            case 'Settings':
              icon = Icons.settings;
              break;
            case 'Logout':
              icon = Icons.exit_to_app;
              iconColor = Colors.red;
              break;
            default:
              icon = Icons.help;
          }

          return PopupMenuItem<String>(
            value: choice,
            padding: EdgeInsets.zero, // Remove padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10.0,
                        spreadRadius: 1.0,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    radius: 20,
                    child: Icon(icon, color: iconColor),
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      color: Colors.transparent, // Transparent background
      elevation: 0, // No shadow
      offset: const Offset(30, 30), // Position adjustment
    );
  }
}

// SettingsPage (unchanged)
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Page (Dummy)')),
    );
  }
}

// ProgressPage (updated to use MenuBarIcon)
