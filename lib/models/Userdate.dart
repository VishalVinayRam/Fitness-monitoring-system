import 'package:shared_preferences/shared_preferences.dart';

class GlobalData {
   String _name = "";
   double _height = 0.0; // in cm
   double _weight  = 0.0; // in kg
   int _calorieGoal=  0; // calories per day
   int _waterGoal = 0; // ml per day
  String? _photoUrl = ""; // optional photo URL

  // Singleton pattern for global state management
  static final GlobalData _singleton = GlobalData._internal();

  factory GlobalData() {
    return _singleton;
  }

  GlobalData._internal();

  // Getters
  String get name => _name;
  double get height => _height;
  double get weight => _weight;
  int get calorieGoal => _calorieGoal;
  int get waterGoal => _waterGoal;
  String? get photoUrl => _photoUrl;

  // Setters
  set name(String value) {
    _name = value;
    saveToPrefs('name', value);
  }

  set height(double value) {
    _height = value;
    saveToPrefs('height', value.toString());
  }

  set weight(double value) {
    _weight = value;
    saveToPrefs('weight', value.toString());
  }

  set calorieGoal(int value) {
    _calorieGoal = value;
    saveToPrefs('calorieGoal', value.toString());
  }

  set waterGoal(int value) {
    _waterGoal = value;
    saveToPrefs('waterGoal', value.toString());
  }

  set photoUrl(String? value) {
    _photoUrl = value;
    saveToPrefs('photoUrl', value ?? '');
  }

  // Method to initialize global data from shared preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('name') ?? '';
    _height = prefs.getDouble('height') ?? 0.0;
    _weight = prefs.getDouble('weight') ?? 0.0;
    _calorieGoal = prefs.getInt('calorieGoal') ?? 0;
    _waterGoal = prefs.getInt('waterGoal') ?? 0;
    _photoUrl = prefs.getString('photoUrl');
  }

  // Private method to save a single value to shared preferences
  Future<void> saveToPrefs(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
