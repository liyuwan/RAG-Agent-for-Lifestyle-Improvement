import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/pages/input_page.dart';
import '/pages/main_page.dart';
import 'package:rag_flutter_app/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false; // Toggle between login and register

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Navigate to HomeScreen if login is successful
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // A custom logic to set username based on email
      String name = _emailController.text.trim().split('@')[0]; // Get the part before '@'

      // After registration, create the user data in Firestore with the `uid` as the document ID
      FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': name, 
        'age': 22,
        'calories_burned': 467,
        'heart_rate': 92,
        'steps': 1423,
        'weight': 114,
        'last_updated': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const InputPage()),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    // Sign in with Google
    UserCredential? userCredential = await AuthService().signInWithGoogle();

    setState(() {
      _isLoading = false;
    });

    if (userCredential != null) {
      // Check if the user already exists in Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      // If the user document doesn't exist, they are a new user, so navigate to InputPage
      if (!userDoc.exists) {
        // Navigate to InputPage for first-time users
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const InputPage()),
        );
      } else {
        // Otherwise, navigate to MainPage for existing users
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } else {
      // Show an error message if sign-in fails or is canceled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed or was canceled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isRegistering ? 'Create an Account' : 'Welcome Back!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF008080)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF008080)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 15),
              // Show "Confirm Password" only in Register mode
              if (_isRegistering)
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF008080)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                  ),
                  obscureText: true,
                ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator(
                  color: Color(0xFF008080),
                )
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _isRegistering ? _register : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008080),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50.0,
                          vertical: 15.0,
                        ),
                      ),
                      child: Text(
                        _isRegistering ? 'Register' : 'Login',
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isRegistering = !_isRegistering;
                          _emailController.clear();
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                        });
                      },
                      child: Text(
                        _isRegistering
                            ? 'Already have an account? Login'
                            : 'Don’t have an account? Register',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4F4F4F),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),
                // Google sign in button
                ElevatedButton(
                  onPressed: _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // White background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                    ),
                    padding: const EdgeInsets.all(16), // Padding for the button
                  ),
                  child: Image.asset(
                    'assets/google_logo.png', // Path to your image
                    height: 32, // Set the height of the image
                    width: 32, // Set the width of the image
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
