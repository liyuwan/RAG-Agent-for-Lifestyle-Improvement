import 'package:flutter/material.dart';
import 'login_page.dart';

class IntroductionPage extends StatelessWidget {
  const IntroductionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF90FFFF), Color(0xFFCBFCFC), Color(0xFFFFFFFF)],
            stops: [0.20, 0.58, 0.88],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08, // 8% of screen width
            vertical: screenHeight * 0.05,  // 10% of screen height
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.05), // 6% of screen height
              Image.asset(
                'assets/logo.png',
                height: screenHeight * 0.25, // 25% of screen height
              ),
              SizedBox(height: screenHeight * 0.05), // 5% of screen height
              Text(
                'Welcome to your intelligent lifestyle assistant!',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: screenWidth * 0.06, // 7% of screen width
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              SizedBox(height: screenHeight * 0.05), // 5% of screen height
              Text(
                'Discover personalized advice, streamlined nutrition planning, and optimized workouts – all in one place',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: screenWidth * 0.04, // 4.5% of screen width
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF076060),
                ),
              ),
              Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF85D9D9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.05), // 5% of screen width
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: screenWidth * 0.1, // 10% of screen width
                  color: Color(0xFF004163),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
