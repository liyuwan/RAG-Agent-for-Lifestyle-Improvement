import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/pages/login_page.dart';
import '/pages/profile_page.dart';

class MenuBarIcon extends StatelessWidget {
  const MenuBarIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Allows the menu to float outside the container
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white, // White background
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                spreadRadius: 1,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.black),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            constraints: const BoxConstraints(
              minWidth: 142,
              maxWidth: 142,
              minHeight: 185,
              maxHeight: 185,
            ), // Sets the menu size
            offset: const Offset(5 , -5),
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
              return [
                const PopupMenuItem<String>(
                  enabled: false,
                  height: 30,
                  child: Center(
                    child: Text(
                      "Menu",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                  ),
                ),
                const PopupMenuDivider(), // Adds a separator
                _buildMenuItem("Profile", Icons.account_circle, Colors.black87),
                _buildMenuItem("Settings", Icons.settings_outlined, Colors.black87),
                _buildMenuItem("Logout", Icons.logout_outlined, Colors.red),
              ];
            },
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(String title, IconData icon, Color color) {
    return PopupMenuItem<String>(
      value: title,
      height: 40,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 20),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
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


