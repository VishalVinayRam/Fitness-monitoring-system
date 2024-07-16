import 'dart:convert';

class Photo {
  String image;
  String note;
  String category;
  String? foodName;
  String? foodTime;
  int? quantity;
  String? foodType;
  String? exerciseName;
  int? reps;
  int? weight;
  DateTime? date;
  int? calories;
  int? totalCalorie = 0;

  Photo({
    required this.image,
    required this.note,
    required this.category,
    this.foodName,
    this.foodTime,
    this.quantity,
    this.foodType,
    this.exerciseName,
    this.reps,
    this.weight,
    this.date,
    this.calories,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      image: json['image'],
      note: json['note'],
      category: json['category'] ?? "Food",
      foodName: json['foodName'],
      foodTime: json['foodTime'],
      quantity: json['quantity'],
      foodType: json['foodType'],
      exerciseName: json['exerciseName'],
      reps: json['reps'],
      weight: json['weight'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null, // Parse date
      calories: json['calories'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'note': note,
      'category': category,
      'foodName': foodName,
      'foodTime': foodTime,
      'quantity': quantity,
      'foodType': foodType,
      'exerciseName': exerciseName,
      'reps': reps,
      'weight': weight,
      'date': date?.toIso8601String(), // Convert date to ISO 8601 string
      'calories': calories,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'image': image,
      'note': note,
      'category': category,
      'date': date,
      'calories': calories,
      'foodName': foodName,
      'foodTime': foodTime,
      'quantity': quantity,
      'foodType': foodType,
      'exerciseName': exerciseName,
      'reps': reps,
      'weight': weight,
    };
  }
  static Photo fromMap(Map<String, dynamic> map) {
    return Photo(
      image: map['image'],
      note: map['note'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      calories: map['calories'],
      foodName: map['foodName'],
      foodTime: map['foodTime'],
      quantity: map['quantity'],
      foodType: map['foodType'],
      exerciseName: map['exerciseName'],
      reps: map['reps'],
      weight: map['weight'],
    );
  }
}
List<Photo> photosFromJson(String str) =>
    List<Photo>.from(json.decode(str).map((x) => Photo.fromJson(x)));

String photosToJson(List<Photo> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));