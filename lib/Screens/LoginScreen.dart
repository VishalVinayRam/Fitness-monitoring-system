import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:management/Screens/homescreen.dart';
import 'package:management/models/Userdate.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalData globalData = GlobalData();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _numberController.text + '@example.com',
          password: _passwordController.text,
        );

        // Load data from Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc('globalData').get();
        if (userDoc.exists) {
          final data = userDoc.data();
          globalData.name = data!['name'];
          globalData.height = double.parse(data['height']);
          globalData.weight = double.parse(data['weight']);
          globalData.calorieGoal = int.parse(data['calorieGoal']);
          globalData.waterGoal = int.parse(data['waterGoal']);
          globalData.number = int.parse(data['number']);
          globalData.password = data['password'];
          globalData.age = int.parse(data['age']);
          globalData.bmi = double.parse(data['bmi']);
          globalData.fat = double.parse(data['fat']);
          globalData.photoUrl = data['photoUrl'];

          await globalData.init(); // Refresh data from shared preferences

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          _showError('User data not found.');
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          _showError('No user found for that phone number.');
        } else if (e.code == 'wrong-password') {
          _showError('Wrong password provided.');
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
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
