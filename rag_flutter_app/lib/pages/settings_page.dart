import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/pages/login_page.dart';
import '/pages/preferences_page.dart';
import '/pages/profile_page.dart';
import '/services/globals.dart';

Widget _buildProfileSection(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()), // Navigate to ProfilePage
      );
    },
    child: Container(
      height: 78,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode.value ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 4,
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
                  radius: 20,
                  backgroundColor: Colors.teal[50],
                  child: CircularProgressIndicator(color: Colors.teal),
                );
              }
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                return CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.teal[50],
                  backgroundImage: AssetImage("assets/default_profile.png"),
                );
              }
              String? profileImageUrl = snapshot.data!['profileImage'];
              return CircleAvatar(
                radius: 20,
                backgroundColor: Colors.teal[50],
                backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                    ? AssetImage(profileImageUrl)
                    : AssetImage("assets/default_profile.png"),
              );
            },
          ),
          SizedBox(width: 20),
          Text(
            'Profile',
            style: TextStyle(
              color: isDarkMode.value ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Icon(Icons.arrow_forward_ios, color: Colors.grey),
        ],
      ),
    ),
  );
}

Widget _buildDarkModeSection(BuildContext context) {
  return GestureDetector(
    onTap: () {
      isDarkMode.value = !isDarkMode.value; // Toggle dark mode
    },
    child: ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, darkMode, child) {
        return Container(
          width: 160,
          height: 160,
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: darkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 0), // Shadow appears below the container
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
                size: 25,
              ),
              SizedBox(height: 25),
              Text(
                'Dark Mode',
                style: TextStyle(
                  color: darkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 5),
              Text(
                darkMode ? 'On' : 'Off',
                style: TextStyle(
                  color: darkMode ? Colors.white70 : Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildPreferencesSection(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PreferencesPage()),
      ); // Make sure to import ProfilePage
    },
    child: Container(
      width: 160,
      height: 160,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 0), // Shadow appears below the container
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_rounded, color: Colors.teal[100], size: 25,),
          SizedBox(height: 25,),
          Text('Preferences', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),),
          SizedBox(height: 5,),
          Text('Edit', style: TextStyle(color: Colors.teal[50], fontSize: 14),),
        ],
      ),
    ),
  );
}

Widget _buildFeedbackSection(BuildContext context) {
  return Container(
    height: 118,
    padding: EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: isDarkMode.value ? Colors.grey[800] : Colors.teal[50],
      borderRadius: BorderRadius.circular(13),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          spreadRadius: 0,
          blurRadius: 4,
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
            Text('Feedback & Support', style: TextStyle(color: isDarkMode.value ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w500),),
            SizedBox(height: 20,),
            Text('123@lamduan.mfu.ac.th', style: TextStyle(color: Colors.teal, fontSize: 14),),
          ],
        ),
        Spacer(),
        Icon(Icons.mail_outline_rounded, color: Colors.teal, size: 30,),
        SizedBox(width: 10,),
      ],
    ),
  );
}

Widget _buildTermsAndPolicySection(BuildContext context) {
  return GestureDetector(
    onTap: () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Terms & Privacy Policy', style: TextStyle(fontSize: 18 , fontWeight: FontWeight.w600),),
            contentPadding: EdgeInsets.all(25),
            content: SingleChildScrollView(
              child: Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
                'nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in '
                'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.'
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
                'nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in '
                'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
                style: TextStyle(fontSize: 14),
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
      height: 118,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode.value ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 4,
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
                style: TextStyle(color: isDarkMode.value ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 20),
              Text(
                'Read our terms and privacy policy',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 5),
              Icon(Icons.privacy_tip_outlined, color: Colors.teal, size: 30),
            ],
          ),
          SizedBox(width: 10),
        ],
      ),
    ),
  );
}

Widget _buildLogOutButton(BuildContext context) {
  return GestureDetector(
    onTap: () {
      FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    },
    child: Container(
      height: 62,
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode.value ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 0), // Shadow appears below the container
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 40,),
          Text('Log Out', style: TextStyle(color: isDarkMode.value ? Colors.redAccent : Colors.red[800], fontSize: 16, fontWeight: FontWeight.w500),),
          Spacer(),
          CircleAvatar(
            radius: 20,
            backgroundColor: isDarkMode.value ? Colors.grey[300] : Colors.red[50],
            child: Icon(Icons.logout, color: Colors.red,)
          ),
          SizedBox(width: 10,),
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
        return Scaffold(
          backgroundColor: darkMode ? Colors.grey[900] : Colors.white,
          appBar: AppBar(
            title: Text('Settings'),
            titleTextStyle: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.w500,
              fontSize: 22,
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
                  _buildProfileSection(context),
                  SizedBox(height: 13),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDarkModeSection(context),
                      _buildPreferencesSection(context),
                    ],
                  ),
                  SizedBox(height: 13),
                  _buildFeedbackSection(context),
                  SizedBox(height: 13),
                  _buildTermsAndPolicySection(context),
                  SizedBox(height: 13),
                  _buildLogOutButton(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
