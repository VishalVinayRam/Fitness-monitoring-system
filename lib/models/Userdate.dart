import 'package:shared_preferences/shared_preferences.dart';

class GlobalData {
  String _name = "";
  double _height = 0.0; // in cm
  double _weight = 0.0; // in kg
  int _calorieGoal = 0; // calories per day
  int _waterGoal = 0; // ml per day
  String? _photoUrl = ""; // optional photo URL
  int _number = 0;
  String _password = '';
  int _age = 18;
  double _totalCaloriesConsumed = 0.0;
  double _bmi = 0.0;
  double _fat = 0.0;
  String _lastDate = "";

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
  int get number => _number;
  String get password => _password;
  int get age => _age;
  double get totalCaloriesConsumed => _totalCaloriesConsumed;
  double get bmi => _bmi;
  double get fat => _fat;
  String get lastDate => _lastDate;

  // Setters
  set name(String value) {
    _name = value;
    saveToPrefs('name', value);
  }

  set lastDate(String value) {
    _lastDate = value;
    saveToPrefs('lastDate', value);
  }

  set height(double value) {
    _height = value;
    saveToPrefs('height', value.toString());
  }

  set bmi(double value) {
    _bmi = value;
    saveToPrefs('bmi', value.toString());
  }

  set fat(double value) {
    _fat = value;
    saveToPrefs('fat', value.toString());
  }

  set number(int value) {
    _number = value;
    saveToPrefs('number', value.toString());
  }

  set age(int value) {
    _age = value;
    saveToPrefs('age', value.toString());
  }

  set password(String value) {
    _password = value;
    saveToPrefs('password', value);
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

  set totalCaloriesConsumed(double value) {
    _totalCaloriesConsumed = value;
    saveToPrefs('totalCaloriesConsumed', value.toString());
  }

  // Method to initialize global data from shared preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('name') ?? '';
    _height = double.tryParse(prefs.getString('height') ?? '') ?? 0.0;
    _weight = double.tryParse(prefs.getString('weight') ?? '') ?? 0.0;
    _calorieGoal = int.tryParse(prefs.getString('calorieGoal') ?? '') ?? 0;
    _waterGoal = int.tryParse(prefs.getString('waterGoal') ?? '') ?? 0;
    _photoUrl = prefs.getString('photoUrl');
    _number = int.tryParse(prefs.getString('number') ?? '') ?? 0;
    _password = prefs.getString('password') ?? '';
    _age = int.tryParse(prefs.getString('age') ?? '') ?? 0;
    _bmi = double.tryParse(prefs.getString('bmi') ?? '') ?? 0.0;
    _fat = double.tryParse(prefs.getString('fat') ?? '') ?? 0.0;
    _lastDate = prefs.getString('lastDate') ?? '';
    _totalCaloriesConsumed = double.tryParse(prefs.getString('totalCaloriesConsumed') ?? '') ?? 0.0;

    String? lastResetDate = prefs.getString('lastResetDate');
    String currentDate = DateTime.now().toIso8601String().split('T')[0];

    if (lastResetDate == null || lastResetDate != currentDate) {
      _totalCaloriesConsumed = 0.0;
      await prefs.setString('lastResetDate', currentDate);
    }
  }

  // Private method to save a single value to shared preferences
  Future<void> saveToPrefs(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
