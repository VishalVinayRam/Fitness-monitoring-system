import 'package:flutter/material.dart';
import 'package:management/Screens/Reminder.dart';
import 'package:management/widgets/pedometer.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/photo.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Photo> _photos = [];
  DateTime _selectedDate = DateTime.now();
  int _totalCaloriesConsumed = 0;
  int _totalCaloriesReduced = 0;
  late TabController _tabController;


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
                    IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),

          IconButton(onPressed:(){ Navigator.push(context,MaterialPageRoute(builder: (context)=>ReminderScreen()));}, icon: Icon(Icons.lock_clock)),
        ],
        leading:                      IconButton(onPressed: (){Navigator.pop(context);}, icon:Icon(Icons.arrow_back)),

        title: Text('Gallery'),
         bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Food'),
            Tab(text: 'Exercise'),
            Tab(text: "Steps",)
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children:[
          filteredPhotos.isEmpty
          ? Center(child: Text('No photos for selected date')):
          _buildCategoryView('Food'),
          _buildCategoryView('Exercise'),
          StepsCounting(),
        ],
      ),
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
