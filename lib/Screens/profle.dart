import 'package:flutter/material.dart';
import 'package:management/models/Userdate.dart';
import 'package:management/Screens/profile_edit.dart';



class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  GlobalData GlobalDatas = GlobalData();

  @override
  void initState() {
    super.initState();
    GlobalDatas.init(); // Initialize global data
  }

  void _openEditModal(String title, String field, dynamic value) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProfileEditModal(title: title, field: field, value: value);
      },
    );

    if (result != null) {
      setState(() {
        switch (field) {
          case 'name':
            GlobalDatas.name = result;
            break;
          case 'age':
            GlobalDatas.age = result;
            break;
          case 'calorieLimit':
            GlobalDatas.calorieGoal = result;
            break;
          case 'waterLimit':
            GlobalDatas.waterGoal = result;
            break;
          case 'height':
            GlobalDatas.height = result;
            break;
          case 'phoneNumber':
            GlobalDatas.number = result;
            break;
        }
      });
    }
  }

  Widget _buildProfileItem(String title, String field, dynamic value) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value.toString()),
      onTap: () => _openEditModal(title, field, value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: ListView(
        children: <Widget>[
          _buildProfileItem('Name', 'name', GlobalDatas.name),
          _buildProfileItem('Age', 'age', GlobalDatas.age),
          _buildProfileItem('Calorie Limit', 'calorieLimit', GlobalDatas.calorieGoal),
          _buildProfileItem('Water Limit (ml)', 'waterLimit', GlobalDatas.waterGoal),
          _buildProfileItem('Height (cm)', 'height', GlobalDatas.height),
          _buildProfileItem('Phone Number', 'phoneNumber', GlobalDatas.number),
        ],
      ),
    );
  }
}
