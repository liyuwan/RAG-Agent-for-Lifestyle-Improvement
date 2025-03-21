import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String? _profileImageUrl; // Stores the selected profile image path
  String? _selectedGender; // Stores the selected gender
  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          _nameController.text = userDoc['name'] ?? '';
          _ageController.text = userDoc['age']?.toString() ?? '';
          _weightController.text = userDoc['weight']?.toString() ?? '';
          _heightController.text = userDoc['height']?.toString() ?? '';
          _profileImageUrl = userDoc['profileImage'];
          _selectedGender = userDoc['gender']; // Fetch gender from Firestore
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  // Update Firestore with new data
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Update Firestore document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'weight': double.parse(_weightController.text.trim()),
        'height': double.parse(_heightController.text.trim()),
        'gender': _selectedGender, // Save gender to Firestore
        'profileImage': _profileImageUrl, // Save the selected profile image path
        'last_updated': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile Updated Successfully!')),
      );

      setState(() {
        _isSubmitting = false;
      });
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() => _isSubmitting = false);
    }
  }

  // Show a dialog for selecting profile images
  Future<void> _chooseProfileImage() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Profile Image'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(6, (index) {
                String imagePath = 'assets/profile_pic${index + 1}.png';
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _profileImageUrl = imagePath; // Set the selected image path
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(imagePath),
                  ),
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel', style: TextStyle(color: Colors.teal)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading spinner
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Profile Image Section
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 80,
                              backgroundImage: _profileImageUrl != null
                                  ? AssetImage(_profileImageUrl!)
                                  : AssetImage("assets/default_profile.png"),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _chooseProfileImage, // Open the dialog to choose an image
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.teal,
                                  child: Icon(Icons.edit, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 60),

                      // Name Field
                      _buildTextField(_nameController, 'Name', Icons.person),
                      SizedBox(height: 20),

                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          labelStyle: TextStyle(fontSize: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: ['Male', 'Female', 'Other']
                            .map((gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        validator: (value) => value == null ? 'Please select your gender' : null,
                      ),
                      SizedBox(height: 20),

                      // Age Field
                      _buildTextField(_ageController, 'Age', Icons.calendar_today, isNumber: true),
                      SizedBox(height: 20),

                      // Weight & Height Fields
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_weightController, 'Weight (kg)', Icons.monitor_weight, isNumber: true)),
                          SizedBox(width: 10),
                          Expanded(child: _buildTextField(_heightController, 'Height (cm)', Icons.height, isNumber: true)),
                        ],
                      ),
                      
                      SizedBox(height: 100),

                      // Save Button
                      _isSubmitting
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _updateProfile,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, backgroundColor: Color(0xFF008080),
                                fixedSize: Size(314, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Helper method for text fields
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
        prefixIcon: Icon(icon),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (value) => value!.isEmpty ? 'Please enter your $label' : null,
    );
  }
}