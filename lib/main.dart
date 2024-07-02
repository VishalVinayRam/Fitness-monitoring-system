// import 'package:flutter/material.dart';
// import 'package:pedometer/pedometer.dart';
// import './homescreen.dart'; // Import the photo tab screen

// void main() {
//   runApp(MyApp());
// }
import 'package:management/Reminder.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MainScreen(),
        '/home': (context) => HomeScreen(),
        '/capture': (context) => CaptureScreen(),
        '/reminder':(contect) => ReminderScreen(),
      },
    );
  }
}


// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   late Stream<StepCount> _stepCountStream;
//   late Stream<PedestrianStatus> _pedestrianStatusStream;
//   String _status = '?', _steps = '?';
//   int _selectedIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     initPlatformState();
//   }

//   void onStepCount(StepCount event) {
//     print(event);
//     setState(() {
//       _steps = event.steps.toString();
//     });
//   }

//   void onPedestrianStatusChanged(PedestrianStatus event) {
//     print(event);
//     setState(() {
//       _status = event.status;
//     });
//   }

//   void onPedestrianStatusError(error) {
//     print('onPedestrianStatusError: $error');
//     setState(() {
//       _status = 'Pedestrian Status not available';
//     });
//     print(_status);
//   }

//   void onStepCountError(error) {
//     print('onStepCountError: $error');
//     setState(() {
//       _steps = 'Step Count not available';
//     });
//   }

//   void initPlatformState() {
//     _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
//     _pedestrianStatusStream
//         .listen(onPedestrianStatusChanged)
//         .onError(onPedestrianStatusError);

//     _stepCountStream = Pedometer.stepCountStream;
//     _stepCountStream.listen(onStepCount).onError(onStepCountError);

//     if (!mounted) return;
//   }

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         body: IndexedStack(
//           index: _selectedIndex,
//           children: [
//             _buildPedometerScreen(),
//             HomeScreen(), // Add the photo tab screen here
//           ],
//         ),
//         bottomNavigationBar: BottomNavigationBar(
//           items: const <BottomNavigationBarItem>[
//             BottomNavigationBarItem(
//               icon: Icon(Icons.directions_walk),
//               label: 'Pedometer',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.photo_album),
//               label: 'Photos',
//             ),
//           ],
//           currentIndex: _selectedIndex,
//           selectedItemColor: Colors.blue,
//           onTap: _onItemTapped,
//         ),
//       ),
//     );
//   }

//   Widget _buildPedometerScreen() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: <Widget>[
//           Text(
//             'Steps Taken',
//             style: TextStyle(fontSize: 30),
//           ),
//           Text(
//             _steps,
//             style: TextStyle(fontSize: 60),
//           ),
//           Divider(
//             height: 100,
//             thickness: 0,
//             color: Colors.white,
//           ),
//           Text(
//             'Pedestrian Status',
//             style: TextStyle(fontSize: 30),
//           ),
//           Icon(
//             _status == 'walking'
//                 ? Icons.directions_walk
//                 : _status == 'stopped'
//                     ? Icons.accessibility_new
//                     : Icons.error,
//             size: 100,
//           ),
//           Center(
//             child: Text(
//               _status,
//               style: _status == 'walking' || _status == 'stopped'
//                   ? TextStyle(fontSize: 30)
//                   : TextStyle(fontSize: 20, color: Colors.red),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
