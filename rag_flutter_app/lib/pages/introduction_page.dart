import 'package:flutter/material.dart';
import 'login_page.dart';

class IntroductionPage extends StatelessWidget {
  const IntroductionPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50,),
              Image.asset(
                'assets/logo.png', // Ensure the logo is placed in the `assets` directory
                height: 210,
              ),
              const SizedBox(height: 40),
              const Text(
                'Welcome to your intelligent lifestyle assistant!',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Discover personalized advice, streamlined nutrition planning, and optimized workouts – all in one place',
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF076060)),
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
                  padding: const EdgeInsets.all(20),
                ),
                child: Icon(Icons.arrow_forward_rounded, size: 40, color: Color(0xFF004163),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
