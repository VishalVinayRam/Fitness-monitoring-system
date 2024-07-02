import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class CaptureScreen extends StatefulWidget {
  @override
  _CaptureScreenState createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _noteController = TextEditingController();
  File? _image;

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
    final List<Map<String, dynamic>> photos = photosString != null
        ? List<Map<String, dynamic>>.from(json.decode(photosString))
        : [];
    final photo = {
      'image': base64Encode(_image!.readAsBytesSync()),
      'note': _noteController.text,
    };
    photos.add(photo);
    await prefs.setString('photos', json.encode(photos));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Capture Photo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _image == null
                ? Text('No image selected.')
                : Image.file(_image!),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(labelText: 'Note'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Take Photo'),
            ),
            ElevatedButton(
              onPressed: _savePhoto,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
