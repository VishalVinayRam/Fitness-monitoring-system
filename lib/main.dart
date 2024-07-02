import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'homescreen.dart';
import 'capture_screen.dart';

void main() {
  runApp(PhotoNotesApp());
}

class PhotoNotesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Notes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/capture': (context) => CaptureScreen(),
      },
    );
  }
}
