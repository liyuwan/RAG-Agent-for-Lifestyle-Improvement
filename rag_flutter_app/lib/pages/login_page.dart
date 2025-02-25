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
  bool _isRegistering = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
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

      String name = _emailController.text.trim().split('@')[0];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C9A7), Color(0xFF008080)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_circle,  // You can change this to any icon you like
                      size: 100,  // Adjust the size as needed
                      color: Color(0xFF008080),  // You can change the color
                    ),
                    const SizedBox(height: 20),  // Add some spacing
                    Text(
                      _isRegistering ? 'Create an Account' : 'Welcome Back!',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_emailController, 'Email', Icons.email, false),
                    const SizedBox(height: 15),
                    _buildTextField(_passwordController, 'Password', Icons.lock, true, isConfirm: false),
                    if (_isRegistering) const SizedBox(height: 15),
                    if (_isRegistering) _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock, true, isConfirm: true),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF008080))
                        : Column(
                            children: [
                              ElevatedButton(
                                onPressed: _isRegistering ? _register : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF008080),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),  // Same as Google Sign In
                                  minimumSize: const Size(double.infinity, 50), // Make the button's width take the full space and fixed height
                                  elevation: 3, // Optional: to match the "Sign in with Google" button elevation
                                ),
                                child: Text(
                                  _isRegistering ? 'Register' : 'Login',
                                  style: const TextStyle(fontSize: 18, color: Colors.white),
                                ),
                              ),

                              const SizedBox(height: 15),

                              // "Or Log in with" section
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.black54, 
                                      thickness: 1,
                                      indent: 20,
                                      endIndent: 10,
                                    ),
                                  ),
                                  const Text(
                                    'or log in with',
                                    style: TextStyle(color: Colors.black54, fontSize: 16),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.black54, 
                                      thickness: 1,
                                      indent: 10,
                                      endIndent: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),


                              ElevatedButton.icon(
                                onPressed: () {
                                  AuthService().signInWithGoogle();
                                },
                                icon: Image.asset('assets/google_logo.png', height: 24),
                                label: const Text('Sign in with Google', style: TextStyle(color: Colors.black87)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),  // Same padding as Login/Register
                                  minimumSize: const Size(double.infinity, 50), // Fixed width and height
                                  elevation: 3,
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
                                  _isRegistering ? 'Already have an account? Login' : 'Don’t have an account? Register',
                                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isPassword, {bool isConfirm = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF008080)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isConfirm ? (_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off) : (_obscurePassword ? Icons.visibility : Icons.visibility_off)),
                onPressed: () {
                  setState(() {
                    if (isConfirm) {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    } else {
                      _obscurePassword = !_obscurePassword;
                    }
                  });
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      obscureText: isPassword ? (isConfirm ? _obscureConfirmPassword : _obscurePassword) : false,
    );
  }
}