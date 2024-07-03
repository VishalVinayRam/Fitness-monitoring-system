// import 'package:flutter/material.dart';
// import 'package:pedometer/pedometer.dart';
// import './homescreen.dart'; // Import the photo tab screen

// void main() {
//   runApp(MyApp());
// }
import 'package:management/Reminder.dart';
import 'package:management/VideoScreen.dart';
import 'package:management/profle.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'homescreen.dart';
import 'capture_screen.dart';

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
        '/': (context) => ProfileScreen(),//routing to mainScreen in login.dart
        '/home': (context) => HomeScreen(), //routing to homeScreen in homescreen.dart
        '/capture': (context) => CaptureScreen(), //routng to image adddition in capture.dart
        '/reminder':(contect) => ReminderScreen(), //routing to the reminder to where you can find the routing
        '/pr':(context) => VideoStorageScreen(), //to capture the video in videoscreen.dart
        '/profile':(context)=> ProfileScreen(),
      },
    );
  }
}