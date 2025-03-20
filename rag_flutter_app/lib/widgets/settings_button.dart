import 'package:flutter/material.dart';
import 'package:rag_flutter_app/pages/settings_page.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1), // Changes position of shadow
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        child: IconButton(
          icon: const Icon(Icons.menu_outlined),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
          },
        ),
      ),
    );
  }
}
