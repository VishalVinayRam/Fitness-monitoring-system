import 'package:flutter/material.dart';
import 'package:management/Screens/LoginScreen.dart';
import 'package:management/models/Userdate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package

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

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      final userId = Uuid().v4();

      globalData.userId = userId;
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

      // Save user data to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      await prefs.setString('name', globalData.name);
      await prefs.setDouble('height', globalData.height);
      await prefs.setDouble('weight', globalData.weight);
      await prefs.setInt('calorieGoal', globalData.calorieGoal);
      await prefs.setInt('waterGoal', globalData.waterGoal);
      await prefs.setInt('number', globalData.number);
      await prefs.setString('password', globalData.password);
      await prefs.setInt('age', globalData.age);
      await prefs.setDouble('bmi', globalData.bmi);
      await prefs.setDouble('fat', globalData.fat);

      // Save user data to Firebase Firestore
      FirebaseFirestore.instance.collection('users').doc(userId).set({
        'name': globalData.name,
        'height': globalData.height,
        'weight': globalData.weight,
        'calorieGoal': globalData.calorieGoal,
        'waterGoal': globalData.waterGoal,
        'number': globalData.number,
        'password': globalData.password,
        'age': globalData.age,
        'bmi': globalData.bmi,
        'fat': globalData.fat,
      });

      // Navigate to the next screen or show a success message
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
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
                  decoration: InputDecoration(labelText: 'Height (cm)'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter your height' : null,
                ),
                TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(labelText: 'Weight (kg)'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter your weight' : null,
                ),
                TextFormField(
                  controller: _calorieGoalController,
                  decoration: InputDecoration(labelText: 'Calorie Goal'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter your calorie goal' : null,
                ),
                TextFormField(
                  controller: _waterGoalController,
                  decoration: InputDecoration(labelText: 'Water Goal (ml)'),
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
                  decoration: InputDecoration(labelText: 'BMI'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter your BMI' : null,
                ),
                TextFormField(
                  controller: _fatController,
                  decoration: InputDecoration(labelText: 'Fat Percentage'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Please enter your fat percentage' : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveData,
                  child: Text('Register'),
                ),
                 TextButton(onPressed: (){
                Navigator.popAndPushNamed(context, '/login');
              }, child: Text("Login"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
