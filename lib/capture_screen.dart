import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/photo.dart';

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _savePhoto() async {
    if (_image == null || _noteController.text.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final photosString = prefs.getString('photos');
    final List<Photo> photos = photosString != null
        ? photosFromJson(photosString)
        : [];
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
    photos.add(photo);
    await prefs.setString('photos', photosToJson(photos));
    Navigator.pop(context);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2015, 8),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Capture Photo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _image == null ? Text('No image selected.') : Image.file(_image!),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(labelText: 'Note'),
            ),
            DropdownButton<String>(
              value: _category,
              items: ['Food', 'Exercise'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _category = newValue!;
                });
              },
            ),
            if (_category == 'Food') ...[
              TextField(
                controller: _foodNameController,
                decoration: InputDecoration(labelText: 'Food Name'),
              ),
              TextField(
                controller: _foodTimeController,
                decoration: InputDecoration(labelText: 'Time'),
              ),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              DropdownButton<String>(
                value: _foodType,
                items: ['solid', 'drinks'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _foodType = newValue!;
                  });
                },
              ),
              TextField(
                controller: _caloriesController,
                decoration: InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
              ),
            ],
            if (_category == 'Exercise') ...[
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
                decoration: InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _caloriesController,
                decoration: InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Selected Date: ${_selectedDate.toString().split(' ')[0]}'),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            ElevatedButton(
              onPressed: _savePhoto,
              child: Text('Save Photo'),
            ),
          ],
        ),
      ),
    );
  }
}
