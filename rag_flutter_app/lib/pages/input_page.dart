import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rag_flutter_app/pages/input2_page.dart';
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
      });
    }
  }

  // Function to upload the image to Firebase Storage
  Future<String?> _uploadImage(File image) async{
    try{
      String fileName = 'profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch(e) {
      print("Image upload failed: $e");
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

        //Upload image if selected 
        String? imageUrl;
        if (_image != null) {
          imageUrl = await _uploadImage(_image!);
        }

        //Store data in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
          'weight': double.parse(_weightController.text.trim()),
          'height': double.parse(_heightController.text.trim()),
          'profileImage': imageUrl, // Firebase Storage URL or null
          'last_updated': FieldValue.serverTimestamp(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Input_2Page()),
        );

      } catch(e) {
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
                  child: Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
