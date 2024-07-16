import 'package:firebase_core/firebase_core.dart';
import 'package:management/Screens/LoginScreen.dart';
import 'package:management/Screens/Reminder.dart';
import 'package:management/Screens/Registerpage.dart';
import 'package:management/Screens/VideoScreen.dart';
import 'package:management/Screens/profle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter/material.dart';
import 'Screens/homescreen.dart';
import 'Screens/capture_screen.dart';

Future<void> main() async {
   WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
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
      home: SplashScreen(), // Check first-time login here
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/capture': (context) => CaptureScreen(),
        '/reminder': (context) => ReminderScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isFirstTimeLogin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Loading indicator
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}'); // Error handling
        } else {
          final isFirstTime = snapshot.data ?? true;
          return isFirstTime ? RegisterScreen() : LoginScreen();
        }
      },
    );
  }

  Future<bool> isFirstTimeLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('first_time') ?? true;
    return isFirstTime;
  }
}
