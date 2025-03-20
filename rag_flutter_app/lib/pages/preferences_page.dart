import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PreferencesPage extends StatefulWidget {
  @override
  _PreferencesPageState createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
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
  String workoutLevelString = '';

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
          workoutLevelString = userDoc['workoutLevelString'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  String _convertWorkoutLevelToString(double level) {
    switch (level.toInt()) {
      case 0: return "very mild";
      case 1: return "mild";
      case 2: return "moderate";
      case 3: return "intense";
      default: return "very intense";
    }
  }

  Future<void> _updatePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String workoutLevelString = _convertWorkoutLevelToString(workoutLevel);

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
        'workoutLevelString': workoutLevelString,
        'last_updated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferences Updated Successfully!')),
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
                      SizedBox(height: 25),
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
                      SizedBox(height: 30),
                      _isSubmitting
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _updatePreferences,
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