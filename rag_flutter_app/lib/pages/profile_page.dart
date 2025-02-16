import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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

  File? _image;
  String? _profileImageUrl;
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
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  // Pick an image from gallery
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    } 
  }

  // Upload the image to Firebase Storage
  Future<String?> _uploadImage(File image) async {
    try {
      String fileName = 'profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Image upload failed: $e");
      return null;
    }
  }

  // Update Firestore with new data
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Upload new profile image if selected
      String? imageUrl = _profileImageUrl;
      if (_image != null) {
        imageUrl = await _uploadImage(_image!);
      }

      // Update Firestore document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'weight': double.parse(_weightController.text.trim()),
        'height': double.parse(_heightController.text.trim()),
        'profileImage': imageUrl,
        'last_updated': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => Profile_2Page()),
      );

      setState(() {
        _profileImageUrl = imageUrl;
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

                      // 🔹 Profile Image Section
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 80,
                              backgroundImage: _image != null
                                  ? FileImage(_image!) as ImageProvider
                                  : _profileImageUrl != null
                                      ? NetworkImage(_profileImageUrl!)
                                      : AssetImage("assets/default_profile.png") as ImageProvider,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _pickImage(ImageSource.gallery),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.teal,
                                  child: Icon(Icons.camera_alt, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 60),

                      // 🔹 Name Field
                      _buildTextField(_nameController, 'Name', Icons.person),
                      SizedBox(height: 20),

                      // 🔹 Age Field
                      _buildTextField(_ageController, 'Age', Icons.calendar_today, isNumber: true),
                      SizedBox(height: 20),

                      // 🔹 Weight & Height Fields
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_weightController, 'Weight (kg)', Icons.monitor_weight, isNumber: true)),
                          SizedBox(width: 10),
                          Expanded(child: _buildTextField(_heightController, 'Height (cm)', Icons.height, isNumber: true)),
                        ],
                      ),
                      
                      SizedBox(height: 100),

                      // 🔹 Save Button
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
                              child: Text('Next', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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

class Profile_2Page extends StatefulWidget {
  @override
  _Profile_2PageState createState() => _Profile_2PageState();
}

class _Profile_2PageState extends State<Profile_2Page> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController foodController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController preferencesController = TextEditingController();

  bool option1 = false;
  bool option2 = false;
  bool option3 = false;
  bool option4 = false;
  bool _isSubmitting = false;
  bool _isLoading = true;
  double workoutLevel = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          foodController.text = userDoc['preferenceFood'] ?? '';
          allergiesController.text = userDoc['foodAllergies'] ?? '';
          preferencesController.text = userDoc['healthConditions'] ?? '';
          option1 = userDoc['fitnessGoals']['weightLoss'] ?? false;
          option2 = userDoc['fitnessGoals']['muscleGain'] ?? false;
          option3 = userDoc['fitnessGoals']['strength'] ?? false;
          option4 = userDoc['fitnessGoals']['endurance'] ?? false;
          workoutLevel = (userDoc['workoutLevel'] ?? 0).toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'preferenceFood': foodController.text.trim(),
        'foodAllergies': allergiesController.text.trim(),
        'healthConditions': preferencesController.text.trim(),
        'fitnessGoals': {
          'weightLoss': option1,
          'muscleGain': option2,
          'strength': option3,
          'endurance': option4,
        },
        'workoutLevel': workoutLevel,
        'last_updated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile Updated Successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Preferences')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildTextField(foodController, 'Preference Food'),
                      SizedBox(height: 15),
                      _buildTextField(allergiesController, 'Food Allergies'),
                      SizedBox(height: 15),
                      _buildTextField(preferencesController, 'Health Conditions'),
                      SizedBox(height: 30),
                      Text("Fitness Goals"),
                      SizedBox(height: 10),
                      _buildCheckbox("Weight Loss", option1, (val) => setState(() => option1 = val)),
                      _buildCheckbox("Muscle Gain", option2, (val) => setState(() => option2 = val)),
                      _buildCheckbox("Strength", option3, (val) => setState(() => option3 = val)),
                      _buildCheckbox("Endurance", option4, (val) => setState(() => option4 = val)),
                      SizedBox(height: 30),
                      Text("Workout Level"),
                      Slider(
                        value: workoutLevel,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: workoutLevel.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            workoutLevel = value;
                          });
                        },
                        activeColor: Color(0xFF008080),
                      ),
                      SizedBox(height: 50),
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

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
      ),
      validator: (value) => value!.isEmpty ? 'Please enter your $label' : null,
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(label, style: TextStyle(fontSize: 14)),
      value: value,
      onChanged: (bool? newValue) => onChanged(newValue ?? false),
      activeColor: Color(0xFF008080),
    );
  }
}
