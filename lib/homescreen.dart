import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/photo.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Photo> _photos = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      appBar: AppBar(
        title: Text('Home'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Food'),
            Tab(text: 'Exercise'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryView('Food'),
          _buildCategoryView('Exercise'),
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
                ],
                if (photo.category == 'Exercise') ...[
                  Text('Exercise: ${photo.exerciseName}'),
                  Text('Reps: ${photo.reps}'),
                  Text('Weight: ${photo.weight} kg'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
