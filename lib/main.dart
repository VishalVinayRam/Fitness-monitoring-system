import 'package:management/Screens/LoginScreen.dart';
import 'package:management/Screens/Reminder.dart';
import 'package:management/Screens/Registerpage.dart';
import 'package:management/Screens/VideoScreen.dart';
import 'package:management/Screens/profle.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter/material.dart';
import 'Screens/homescreen.dart';
import 'Screens/capture_screen.dart';

void main() {
   WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  runApp(PhotoNotesApp());
}

class PhotoNotesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Notes',
      showSemanticsDebugger: false,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/login': (context) => LoginScreen(),//routing to mainScreen in login.dart
        '/register':(context) => RegisterScreen(),
        '/': (context) => RegisterScreen(),//routing to mainScreen in login.dart
        '/home': (context) => HomeScreen(), //routing to homeScreen in homescreen.dart
        '/capture': (context) => CaptureScreen(), //routng to image adddition in capture.dart
        '/reminder':(contect) => ReminderScreen(), //routing to the reminder to where you can find the routing
        '/pr':(context) => VideoStorageScreen(), //to capture the video in videoscreen.dart
        '/profile':(context)=> ProfileScreen(),
      },
    );
  }
}