import 'package:flutter/material.dart';
import 'package:management/models/Userdate.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalData globalData = GlobalData();

  @override
  void initState() {
    super.initState();
    globalData.init(); // Initialize global data from shared preferences
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Name: ${globalData.name}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to edit profile screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfileScreen()),
                );
              },
              child: Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalData globalData = GlobalData();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: globalData.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (value) {
                globalData.name = value; // Update name in global data
              },
            ),
            SizedBox(height: 20),
             TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (value) {
                globalData.name = value; // Update name in global data
              },
            ),
             TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (value) {
                globalData.name = value; // Update name in global data
              },
            ),
             TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (value) {
                globalData.name = value; // Update name in global data
              },
            ),
             TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (value) {
                globalData.name = value; // Update name in global data
              },
            ),
             TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (value) {
                globalData.name = value; // Update name in global data
              },
            ),
             TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (value) {
                globalData.name = value; // Update name in global data
              },
            ),
             TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (value) {
                globalData.name = value; // Update name in global data
              },
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Navigate back to profile screen
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
