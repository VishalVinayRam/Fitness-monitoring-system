import 'package:flutter/material.dart';
import 'package:management/Screens/homescreen.dart';
import 'package:management/Screens/main_screen.dart';
import 'package:management/models/Userdate.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final prefs = await SharedPreferences.getInstance();
      final storedNumber = int.tryParse(prefs.getString('number') ?? '') ?? 0;
      final storedPassword = prefs.getString('password') ?? '';

      if (storedNumber == int.parse(_numberController.text) &&
          storedPassword == _passwordController.text) {
        // Login successful, navigate to the home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()), // Replace with your home screen
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid phone number or password')),
        );
      }
    }
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
