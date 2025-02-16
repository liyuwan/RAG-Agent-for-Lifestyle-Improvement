import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'login_page.dart';
import 'dart:io';

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}


class _InputPageState extends State<InputPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  File? _image;  // To store the selected image
  bool _isSubmitting = false;


  // Function to pick an image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        print("Image selected: ${_image!.path}");
      });
    } else {
      print("No image selected.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected')),
      );
    }

  }

  // Function to upload the image to Firebase Storage
  Future<String?> _uploadImage(File image) async{
    try{
      String fileName = 'profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(image);

      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();

      print("Image uploaded successfully: $downloadURL");

      return downloadURL;
    } catch(e) {
      print("Image upload failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
      return null;
    }
  }

  // Function to submit from data to Firestore
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

      try{
        //Get the current user
        User? user = FirebaseAuth.instance.currentUser;
        if(user == null) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()),
          );
          return;
        }

        if (_image == null) {
          print("No image selected for upload.");
        } else {
          print("Uploading image: ${_image!.path}");
        }

        //Upload image if selected 
        String? imageUrl;
        if (_image != null) {
          imageUrl = await _uploadImage(_image!);
          if (imageUrl == null) {
            print("Failed to upload image, skipping profileImage field.");
          }
        }

        //Store data in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
          'weight': double.parse(_weightController.text.trim()),
          'height': double.parse(_heightController.text.trim()),
          'profileImage': imageUrl ?? "", // Firebase Storage URL or null
          'last_updated': FieldValue.serverTimestamp(),
          'heart_rate': 92,
          'steps': 1423,
        });

        print("User profile saved successfully!"); // Debugging log

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Input_2Page()),
        );

      } catch(e) {
        print("Error saving profile: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }

      setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Profile')),
      body: Padding(
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
                        backgroundImage: _image != null
                            ? FileImage(_image!) as ImageProvider
                            : AssetImage("assets/default_profile.png"),
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
                 Container(
                  width: 332,
                  height: 48,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter your name' : null,
                  ),
                ),
                SizedBox(height: 27),
                Container(
                  width: 332,
                  height: 48,
                  child: TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'Age',
                      labelStyle: TextStyle(fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter your age' : null,
                  ),
                ),
                SizedBox(height: 27),
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 20), // Add left padding to the weight field
                      child: Flexible(
                        flex: 1,
                        child: Container(
                          width: 160,
                          height: 48,
                          child: TextFormField(
                            controller: _weightController,
                            decoration: InputDecoration(
                              labelText: 'Weight (kg)',
                              labelStyle: TextStyle(fontSize: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                              prefixIcon: Icon(Icons.monitor_weight_sharp),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value!.isEmpty ? 'Enter weight' : null,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      flex: 1,
                      child: Container(
                        width: 160,
                        height: 48,
                        child: TextFormField(
                          controller: _heightController,
                          decoration: InputDecoration(
                            labelText: 'Height (cm)',
                            labelStyle: TextStyle(fontSize: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                            prefixIcon: Icon(Icons.height),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value!.isEmpty ? 'Enter height' : null,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 227),
                _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _submitForm,
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
}

class Input_2Page extends StatefulWidget {
  @override
  _Input_2PageState createState() => _Input_2PageState();
}

class _Input_2PageState extends State<Input_2Page > {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController foodController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController preferencesController = TextEditingController();

  bool option1 = false;
  bool option2 = false;
  bool option3 = false;
  bool option4 = false;
  bool _isSubmitting = false;
  double workoutLevel = 0;

  // Function to convert numeric workout levels to string descriptions
  String _convertWorkoutLevelToString(double level) {
    switch (level.toInt()) {
      case 0: return "very mild";
      case 1: return "mild";
      case 2: return "moderate";
      case 3: return "intense";
      default: return "very intense";
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        return;
      }

    // Convert workout level to a descriptive string
    String workoutLevelString = _convertWorkoutLevelToString(workoutLevel);


      // Store data in Firestore
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
        'workoutLevelString': workoutLevelString,
        'last_updated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile Updated Successfully!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
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
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 60),
              Text("Preference Food", textAlign: TextAlign.start),
              SizedBox(height: 5),
              Container(
                width: 332,
                height: 90,
                child: TextFormField(
                  controller: foodController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(fontSize: 12),
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(18))),
                ),
              ),
              SizedBox(height: 15),
              Text("Food Allergies"),
              
              SizedBox(height: 5),
              Container(
                width: 332,
                height: 90,
                child: TextFormField(
                  controller: allergiesController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(fontSize: 12),
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(18))),
                ),
              ),
              SizedBox(height: 15),
              Text("Health conditions"),
              SizedBox(height: 5),
              Container(
                width: 332,
                height: 90,
                child: TextFormField(
                  controller: preferencesController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(fontSize: 12),
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(18))),
                ),
              ),
              SizedBox(height: 30),
              Text("Fitness Goal"),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        CheckboxListTile(                 
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4), // Reduces spacing inside checkbox
                          contentPadding: EdgeInsets.only(right: 25, left: 25, top: 0),
                          title: Text("Weight Loss", style: TextStyle(fontSize: 12)),
                          value: option1,          
                          onChanged: (bool? value) {
                            setState(() {
                              option1 = value!;
                            });
                          },
                          activeColor: Color(0xFF008080), // Change checkbox color when checked
                        ),
                        CheckboxListTile(
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4), // Reduces spacing inside checkbox
                          contentPadding: EdgeInsets.only(right: 25, left: 25, top: 0),
                          title: Text("Muscle Gain", style: TextStyle(fontSize: 12)),
                          value: option2,
                          onChanged: (bool? value) {
                            setState(() {
                              option2 = value!;
                            });
                          },
                          activeColor: Color(0xFF008080), // Change checkbox color when checked
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        CheckboxListTile(
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4), // Reduces spacing inside checkbox
                          contentPadding: EdgeInsets.only(right: 25, left: 15, top: 0),
                          title: Text("Strength", style: TextStyle(fontSize: 12)),
                          value: option3,
                          onChanged: (bool? value) {
                            setState(() {
                              option3 = value!;
                            });
                          },
                          activeColor: Color(0xFF008080), // Change checkbox color when checked
                        ),
                        CheckboxListTile(
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4), // Reduces spacing inside checkbox
                          contentPadding: EdgeInsets.only(right: 25, left: 15, top: 0),
                          title: Text("Endurance", style: TextStyle(fontSize: 12)),
                          value: option4,
                          onChanged: (bool? value) {
                            setState(() {
                              option4 = value!;
                            });
                          },
                          activeColor: Color(0xFF008080), // Change checkbox color when checked
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              Text("Workout Level"),
              SizedBox(height: 25),
              SizedBox(
                width: 325,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Mild", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    Expanded(
                      child: Slider(
                        value: workoutLevel,
                        min: 0,
                        max: 4,
                        divisions: 4,
                        label: workoutLevel.toStringAsFixed(0),
                        onChanged: (value) {
                          setState(() {
                            workoutLevel = value;
                          });
                        },
                        activeColor: Color(0xFF008080),
                        inactiveColor: Colors.grey[300],
                      ),
                    ),
                    Text("Intense", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              SizedBox(height: 45),
              _isSubmitting
                ? const CircularProgressIndicator()
                :ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Color(0xFF008080),
                    fixedSize: Size(314, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
