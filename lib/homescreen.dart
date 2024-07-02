import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/photo.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Photo> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final photosString = prefs.getString('photos');
    if (photosString != null) {
      setState(() {
        _photos = photosFromJson(photosString);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: _photos.isEmpty
          ? Center(child: Text('No photos yet'))
          : ListView(
              children: [
                _buildCategorySection('Food'),
                _buildCategorySection('Exercise'),
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

  Widget _buildCategorySection(String category) {
    final categoryPhotos = _photos.where((p) => p.category == category).toList();
    return ExpansionTile(
      title: Text(category),
      children: categoryPhotos.map((photo) => _buildPhotoTile(photo)).toList(),
    );
  }

  Widget _buildPhotoTile(Photo photo) {
    return ListTile(
      leading: Image.memory(base64Decode(photo.image)),
      title: Text(photo.note),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if (photo.category == 'Food') ...[
            Text('Food Name: ${photo.foodName}'),
            Text('Time: ${photo.foodTime}'),
            Text('Quantity: ${photo.quantity} ${photo.foodType == 'drinks' ? 'ml' : 'gm'}'),
          ],
          if (photo.category == 'Exercise') ...[
            Text('Exercise: ${photo.exerciseName}'),
            Text('Reps: ${photo.reps}'),
            Text('Weight: ${photo.weight} kg'),
          ],
        ],
      ),
    );
  }
}
