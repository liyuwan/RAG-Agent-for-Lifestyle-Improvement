import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'profile_page.dart';

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
       actions: [
        PopupMenuButton<String>(
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
              Color iconColor = const Color(0xFF008080);
              switch (choice) {
                case 'Profile':
                  icon = Icons.account_circle;
                  iconColor = iconColor;
                  break;
                case 'Settings':
                  icon = Icons.settings;
                  iconColor = iconColor;
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
                padding: EdgeInsets.zero, // Remove any padding to prevent spacing
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Wrapping CircleAvatar with a Container for the shadow effect
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3), // Shadow color
                            blurRadius: 10.0, // Blurry effect
                            spreadRadius: 1.0, // Spread of the shadow
                            offset: Offset(3, 3), // Position of the shadow
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey[200], // Set a color if needed
                        radius: 20,
                        child: Icon(icon, color: iconColor),
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          color: Colors.transparent, // Make the background of the popup transparent
          elevation: 0, // Remove the shadow effect of the menu
          offset: const Offset(30, 30),
        ),
      ],
      ),
      
    );
  }
}
