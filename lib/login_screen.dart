import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:management/Reminder.dart';
import 'package:management/capture_screen.dart';
import 'package:management/homescreen.dart';
import 'package:management/models/Userdate.dart';
import 'package:management/profle.dart';
import 'package:management/widgets/Body_measurement.dart';
import 'package:management/widgets/Hero_section.dart';
import 'package:management/widgets/Water.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/photo.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  List<Photo> _photos = [];
  DateTime _selectedDate = DateTime.now();
  int _totalCaloriesConsumed = 0;
  int _totalCaloriesReduced = 0;
  late TabController _tabController;
GlobalData global = GlobalData();

  @override
  void initState() {
    super.initState();
      _tabController = TabController(length: 3, vsync: this);

    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final photosString = prefs.getString('photos');
    if (photosString != null) {
      final List<Photo> photos = photosFromJson(photosString);
      setState(() {
        _photos = photos;
      });
      _updateCalorieCount();
    }
  }

  void _updateCalorieCount() {
    int consumed = 0;
    int reduced = 0;
    for (var photo in _photos) {
      if (photo.date.toString()==_selectedDate) {
        if (photo.category == 'Food') {
          consumed += photo.calories??0;
        } else if (photo.category == 'Exercise') {
          reduced += photo.calories??0;
        }
      }
    }
    setState(() {
      _totalCaloriesConsumed = consumed;
      _totalCaloriesReduced = reduced;
    });
  }

  List<Photo> getPhotosForDate(DateTime date) {
    return _photos.where((photo) => photo.date.toString()==_selectedDate).toList();
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
      _updateCalorieCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Photo> filteredPhotos = getPhotosForDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed:(){ Navigator.push(context,MaterialPageRoute(builder: (context)=>ReminderScreen()));}, icon: Icon(Icons.lock_clock))
        ],
        title: Text('Home'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(child: 
            Text(
              global.name
            )),
            SizedBox(
              height: MediaQuery.of(context).size.height*.12,
              child: Container(
            ),
            ),
             ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.lock_clock),
              title: Text('Reminder'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReminderScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('Capture'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CaptureScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.supervised_user_circle),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body:  SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            child: Column(
              children: [
              Container(
                margin: EdgeInsets.all(15),
                height: 200,
                child:MediterranesnDietView(eaten: _totalCaloriesConsumed,burned: _totalCaloriesReduced,),
              ),
              Container(
                margin:EdgeInsets.all(15),
                child: WaterView()),
              BodyMeasurementView(),
            ]),
          ),),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/capture');
        },
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
Widget _buildCategoryView(String category) {
    final categoryPhotos = _photos.where((p) => p.category == category).toList();
    return categoryPhotos.isEmpty
        ? Center(child: Text('No photos yet'))
        : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: categoryPhotos.length,
            itemBuilder: (context, index) {
              return _buildPhotoTile(categoryPhotos[index]);
            },
          );
}
  Widget _buildPhotoTile(Photo photo) {
    return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Image.memory(
                          base64Decode(photo.image),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      // 9538963355
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(photo.note, style: TextStyle(fontWeight: FontWeight.bold)),
                            if (photo.category == 'Food') ...[
                              Text('Food Name: ${photo.foodName}'),
                              Text('Time: ${photo.foodTime}'),
                              Text('Quantity: ${photo.quantity} ${photo.foodType == 'drinks' ? 'ml' : 'gm'}'),
                              Text('Calories: ${photo.calories}'),
                            ],
                            if (photo.category == 'Exercise') ...[
                              Text('Exercise: ${photo.exerciseName}'),
                              Text('Reps: ${photo.reps}'),
                              Text('Weight: ${photo.weight} kg'),
                              Text('Calories: ${photo.calories}'),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )

     
          );
  }
}
