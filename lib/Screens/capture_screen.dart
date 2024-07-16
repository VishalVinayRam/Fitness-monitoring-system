import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/photo.dart';

class CaptureScreen extends StatefulWidget {
  @override
  _CaptureScreenState createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _noteController = TextEditingController();
  final _foodNameController = TextEditingController();
  final _foodTimeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _caloriesController = TextEditingController(); // New controller for calories
  final _exerciseNameController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  File? _image;
  String _category = 'Food';
  String _foodType = 'solid';
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _savePhoto() async {
    if (_image == null || _noteController.text.isEmpty) return;
    final photo = Photo(
      image: base64Encode(_image!.readAsBytesSync()),
      note: _noteController.text,
      category: _category,
      date: _selectedDate,
      calories: int.tryParse(_caloriesController.text) ?? 0, // Save calories
      foodName: _category == 'Food' ? _foodNameController.text : null,
      foodTime: _category == 'Food' ? _foodTimeController.text : null,
      quantity: _category == 'Food' ? int.tryParse(_quantityController.text) : null,
      foodType: _category == 'Food' ? _foodType : null,
      exerciseName: _category == 'Exercise' ? _exerciseNameController.text : null,
      reps: _category == 'Exercise' ? int.tryParse(_repsController.text) : null,
      weight: _category == 'Exercise' ? int.tryParse(_weightController.text) : null,
    );

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) {
      // Handle error: user ID not found
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(userId);
    final photoRef = userRef.collection('photos').doc();

    await photoRef.set({
      'image': photo.image,
      'note': photo.note,
      'category': photo.category,
      'date': photo.date,
      'calories': photo.calories,
      'foodName': photo.foodName,
      'foodTime': photo.foodTime,
      'quantity': photo.quantity,
      'foodType': photo.foodType,
      'exerciseName': photo.exerciseName,
      'reps': photo.reps,
      'weight': photo.weight,
    });

    Navigator.pop(context); // Go back to the previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Capture Photo'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              _image == null
                  ? Text('No image selected.')
                  : Image.file(_image!),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.camera),
                child: Text('Take Photo'),
              ),
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                child: Text('Choose from Gallery'),
              ),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(labelText: 'Note'),
              ),
              DropdownButton<String>(
                value: _category,
                onChanged: (String? newValue) {
                  setState(() {
                    _category = newValue!;
                  });
                },
                items: <String>['Food', 'Exercise']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              _category == 'Food'
                  ? Column(
                      children: <Widget>[
                        TextField(
                          controller: _foodNameController,
                          decoration: InputDecoration(labelText: 'Food Name'),
                        ),
                        TextField(
                          controller: _foodTimeController,
                          decoration: InputDecoration(labelText: 'Food Time'),
                        ),
                        TextField(
                          controller: _quantityController,
                          decoration: InputDecoration(labelText: 'Quantity'),
                          keyboardType: TextInputType.number,
                        ),
                        DropdownButton<String>(
                          value: _foodType,
                          onChanged: (String? newValue) {
                            setState(() {
                              _foodType = newValue!;
                            });
                          },
                          items: <String>['solid', 'liquid']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        TextField(
                          controller: _caloriesController,
                          decoration: InputDecoration(labelText: 'Calories'),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        TextField(
                          controller: _exerciseNameController,
                          decoration: InputDecoration(labelText: 'Exercise Name'),
                        ),
                        TextField(
                          controller: _repsController,
                          decoration: InputDecoration(labelText: 'Reps'),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: _weightController,
                          decoration: InputDecoration(labelText: 'Weight'),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePhoto,
                child: Text('Save Photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
