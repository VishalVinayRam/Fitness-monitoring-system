import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:management/Screens/LoginScreen.dart';
import 'package:management/models/Userdate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalData globalData = GlobalData();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _calorieGoalController = TextEditingController();
  final TextEditingController _waterGoalController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Register with Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _numberController.text + '@example.com',
          password: _passwordController.text,
        );

        // Save data to GlobalData and SharedPreferences
        globalData.name = _nameController.text;
        globalData.height = double.parse(_heightController.text);
        globalData.weight = double.parse(_weightController.text);
        globalData.calorieGoal = int.parse(_calorieGoalController.text);
        globalData.waterGoal = int.parse(_waterGoalController.text);
        globalData.number = int.parse(_numberController.text);
        globalData.password = _passwordController.text;
        globalData.age = int.parse(_ageController.text);
        globalData.bmi = double.parse(_bmiController.text);
        globalData.fat = double.parse(_fatController.text);

        await globalData.init(); // Refresh data from shared preferences

        // Navigate to the next screen or show a success message
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          _showError('The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          _showError('The account already exists for that phone number.');
        }
      } catch (e) {
        _showError('An error occurred. Please try again.');
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                ),
                TextFormField(
                  controller: _heightController,
                  decoration: InputDecoration(labelText: 'Height (cm) in double'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter your height' : null,
                ),
                TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(labelText: 'Weight (kg) in double'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter your weight' : null,
                ),
                TextFormField(
                  controller: _calorieGoalController,
                  decoration: InputDecoration(labelText: 'Calorie Goal in double'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter your calorie goal' : null,
                ),
                TextFormField(
                  controller: _waterGoalController,
                  decoration: InputDecoration(labelText: 'Water Goal (ml) in double'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter your water goal' : null,
                ),
                TextFormField(
                  controller: _numberController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                                    keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
                ),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter your age' : null,
                ),
                TextFormField(
                  controller: _bmiController,
                  decoration: InputDecoration(labelText: 'BMI in double'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter your BMI' : null,
                ),
                TextFormField(
                  controller: _fatController,
                  decoration: InputDecoration(labelText: 'Fat Percentage in double '),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter your fat percentage' : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _register,
                  child: Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
