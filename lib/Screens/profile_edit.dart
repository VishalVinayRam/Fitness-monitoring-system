import 'package:flutter/material.dart';

class ProfileEditModal extends StatefulWidget {
  final String title;
  final String field;
  final dynamic value;

  ProfileEditModal({required this.title, required this.field, required this.value});

  @override
  _ProfileEditModalState createState() => _ProfileEditModalState();
}

class _ProfileEditModalState extends State<ProfileEditModal> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  void _save() {
    dynamic newValue;
    switch (widget.field) {
      case 'age':
      case 'calorieLimit':
      case 'waterLimit':
        newValue = int.parse(_controller.text);
        break;
      case 'height':
        newValue = double.parse(_controller.text);
        break;
      default:
        newValue = _controller.text;
    }
    Navigator.of(context).pop(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.title}'),
      content: TextField(
        controller: _controller,
        keyboardType: widget.field == 'age' || widget.field == 'calorieLimit' || widget.field == 'waterLimit' || widget.field == 'height'
            ? TextInputType.number
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: widget.title,
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Save'),
          onPressed: _save,
        ),
      ],
    );
  }
}
