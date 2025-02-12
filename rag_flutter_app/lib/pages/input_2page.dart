import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rag_flutter_app/pages/main_page.dart';

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
        'last_updated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile Updated Successfully!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
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
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))),
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
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))),
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
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))),
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
                          contentPadding: EdgeInsets.only(right: 25, left: 15, top: 0),
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
                          contentPadding: EdgeInsets.only(right: 25, left: 15, top: 0),
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
              SizedBox(height: 30),
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
