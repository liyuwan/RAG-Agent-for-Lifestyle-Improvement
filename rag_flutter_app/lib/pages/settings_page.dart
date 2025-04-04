import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/pages/login_page.dart';
import '/pages/preferences_page.dart';
import '/pages/profile_page.dart';
import '/services/globals.dart';

Widget _buildProfileSection(BuildContext context, double screenWidth, double screenHeight) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()), // Navigate to ProfilePage
      );
    },
    child: Container(
      height: screenHeight * 0.1, // 10% of screen height
      padding: EdgeInsets.all(screenWidth * 0.045), // 4.5% of screen width
      decoration: BoxDecoration(
        color: isDarkMode.value ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.05), // 5% of screen width
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: screenWidth * 0.02, // 2% of screen width
            offset: const Offset(0, 0), // Shadow appears below the container
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircleAvatar(
                  radius: screenWidth * 0.05, // 5% of screen width
                  backgroundColor: Colors.teal[50],
                  child: CircularProgressIndicator(color: Colors.teal),
                );
              }
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return CircleAvatar(
                  radius: screenWidth * 0.05, // 5% of screen width
                  backgroundColor: Colors.teal[50],
                  backgroundImage: AssetImage("assets/default_profile.png"),
                );
              }
              String? profileImageUrl = snapshot.data!['profileImage'];
              return CircleAvatar(
                radius: screenWidth * 0.05, // 5% of screen width
                backgroundColor: Colors.teal[50],
                backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                    ? AssetImage(profileImageUrl)
                    : AssetImage("assets/default_profile.png"),
              );
            },
          ),
          SizedBox(width: screenWidth * 0.05), // 5% of screen width
          Text(
            'Profile',
            style: TextStyle(
              color: isDarkMode.value ? Colors.white : Colors.black,
              fontSize: screenWidth * 0.035, // 4.5% of screen width
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Icon(Icons.arrow_forward_ios, color: Colors.grey, size: screenWidth * 0.05), // 5% of screen width
        ],
      ),
    ),
  );
}

Widget _buildDarkModeSection(BuildContext context, double screenWidth, double screenHeight) {
  final double size = screenWidth * 0.4; // 40% of screen width (used for both width and height)

  return GestureDetector(
    onTap: () {
      isDarkMode.value = !isDarkMode.value; // Toggle dark mode
    },
    child: ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, darkMode, child) {
        return Container(
          width: size, // Set width to the calculated size
          height: size, // Set height equal to width to make it square
          padding: EdgeInsets.all(size * 0.1), // 10% of the size for padding
          decoration: BoxDecoration(
            color: darkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(size * 0.1), // 10% of the size for border radius
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: size * 0.05, // 5% of the size for blur radius
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                darkMode ? Icons.dark_mode : Icons.light_mode,
                color: darkMode ? Colors.white : Colors.grey,
                size: size * 0.15, // 20% of the size for the icon
              ),
              SizedBox(height: size * 0.05), // 5% of the size for spacing
              Text(
                'Dark Mode',
                style: TextStyle(
                  color: darkMode ? Colors.white : Colors.black,
                  fontSize: size * 0.09, // 12% of the size for font size
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: size * 0.02), // 2% of the size for spacing
              Text(
                darkMode ? 'On' : 'Off',
                style: TextStyle(
                  color: darkMode ? Colors.white70 : Colors.grey,
                  fontSize: size * 0.075, // 10% of the size for font size
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildPreferencesSection(BuildContext context, double screenWidth, double screenHeight) {
  final double size = screenWidth * 0.4; // 40% of screen width (used for both width and height)

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PreferencesPage()),
      );
    },
    child: Container(
      width: size, // Set width to the calculated size
      height: size, // Set height equal to width to make it square
      padding: EdgeInsets.all(size * 0.1), // 10% of the size for padding
      decoration: BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.circular(size * 0.1), // 10% of the size for border radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: size * 0.05, // 5% of the size for blur radius
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.favorite_rounded,
            color: Colors.teal[100],
            size: size * 0.15, // 20% of the size for the icon
          ),
          SizedBox(height: size * 0.05), // 5% of the size for spacing
          Text(
            'Preferences',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.09, // 12% of the size for font size
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: size * 0.02), // 2% of the size for spacing
          Text(
            'Edit',
            style: TextStyle(
              color: Colors.teal[50],
              fontSize: size * 0.075, // 10% of the size for font size
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildFeedbackSection(BuildContext context, double screenWidth, double screenHeight) {
  return Container(
    height: screenHeight * 0.15, // 15% of screen height
    padding: EdgeInsets.all(screenWidth * 0.045), // 4.5% of screen width
    decoration: BoxDecoration(
      color: isDarkMode.value ? Colors.grey[800] : Colors.teal[50],
      borderRadius: BorderRadius.circular(screenWidth * 0.05), // 5% of screen width
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          spreadRadius: 0,
          blurRadius: screenWidth * 0.02, // 2% of screen width
          offset: const Offset(0, 0), // Shadow appears below the container
        ),
      ],
    ),
    child: Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback & Support',
              style: TextStyle(
                color: isDarkMode.value ? Colors.white : Colors.black,
                fontSize: screenWidth * 0.035, // 4.5% of screen width
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenHeight * 0.01), // 1% of screen height
            Text(
              '123@lamduan.mfu.ac.th',
              style: TextStyle(
                color: Colors.teal,
                fontSize: screenWidth * 0.025, // 3.5% of screen width
              ),
            ),
          ],
        ),
        Spacer(),
        Icon(Icons.mail_outline_rounded, color: Colors.teal, size: screenWidth * 0.07), // 7% of screen width
        SizedBox(width: screenWidth * 0.02), // 2% of screen width
      ],
    ),
  );
}

Widget _buildTermsAndPolicySection(BuildContext context, double screenWidth, double screenHeight) {
  return GestureDetector(
    onTap: () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.05), // 5% of screen width
            ),
            title: Text(
              'Terms & Privacy Policy',
              style: TextStyle(
                fontSize: screenWidth * 0.045, // 4.5% of screen width
                fontWeight: FontWeight.w600,
              ),
            ),
            contentPadding: EdgeInsets.all(screenWidth * 0.05), // 5% of screen width
            content: SingleChildScrollView(
              child: Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
                'nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in '
                'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
                style: TextStyle(fontSize: screenWidth * 0.03), // 3.5% of screen width
                textAlign: TextAlign.justify,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Close', style: TextStyle(color: Colors.teal)),
              ),
            ],
          );
        },
      );
    },
    child: Container(
      height: screenHeight * 0.15, // 15% of screen height
      padding: EdgeInsets.all(screenWidth * 0.045), // 4.5% of screen width
      decoration: BoxDecoration(
        color: isDarkMode.value ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.05), // 5% of screen width
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: screenWidth * 0.02, // 2% of screen width
            offset: const Offset(0, 0), // Shadow appears below the container
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms & Privacy Policy',
                style: TextStyle(
                  color: isDarkMode.value ? Colors.white : Colors.black,
                  fontSize: screenWidth * 0.035, // 4.5% of screen width
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: screenHeight * 0.01), // 1% of screen height
              Text(
                'Read our terms and privacy policy',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: screenWidth * 0.025, // 3.5% of screen width
                ),
              ),
            ],
          ),
          Spacer(),
          Icon(Icons.privacy_tip_outlined, color: Colors.teal, size: screenWidth * 0.07), // 7% of screen width
          SizedBox(width: screenWidth * 0.02), // 2% of screen width
        ],
      ),
    ),
  );
}

Widget _buildLogOutButton(BuildContext context, double screenWidth, double screenHeight) {
  return GestureDetector(
    onTap: () {
      FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    },
    child: Container(
      height: screenHeight * 0.08, // 8% of screen height
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01), // 2% of screen height
      decoration: BoxDecoration(
        color: isDarkMode.value ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.1), // 5% of screen width
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: screenWidth * 0.02, // 2% of screen width
            offset: const Offset(0, 0), // Shadow appears below the container
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: screenWidth * 0.1), // 10% of screen width
          Text(
            'Log Out',
            style: TextStyle(
              color: isDarkMode.value ? Colors.redAccent : Colors.red[800],
              fontSize: screenWidth * 0.035, // 4.5% of screen width
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          CircleAvatar(
            radius: screenWidth * 0.06, // 5% of screen width
            backgroundColor: isDarkMode.value ? Colors.grey[700] : Colors.red[50],
            child: Icon(Icons.logout, color: isDarkMode.value ? Colors.redAccent : Colors.red, size: screenWidth * 0.05), // 5% of screen width
          ),
          SizedBox(width: screenWidth * 0.02), // 2% of screen width
        ],
      ),
    ),
  );
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, darkMode, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Scaffold(
          backgroundColor: darkMode ? Colors.grey[900] : Colors.white,
          appBar: AppBar(
            title: Text('Settings'),
            titleTextStyle: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.055, // 5% of screen width
            ),
            automaticallyImplyLeading: true,
            centerTitle: false,
            iconTheme: IconThemeData(color: isDarkMode.value ? Colors.grey : Colors.black),
            backgroundColor: darkMode ? Colors.grey[900] : Colors.white,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  _buildProfileSection(context, screenWidth, screenHeight),
                  SizedBox(height: 13),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDarkModeSection(context, screenWidth, screenHeight),
                      _buildPreferencesSection(context, screenWidth, screenHeight),
                    ],
                  ),
                  SizedBox(height: 13),
                  _buildFeedbackSection(context, screenWidth, screenHeight),
                  SizedBox(height: 13),
                  _buildTermsAndPolicySection(context, screenWidth, screenHeight),
                  SizedBox(height: 13),
                  _buildLogOutButton(context, screenWidth, screenHeight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
