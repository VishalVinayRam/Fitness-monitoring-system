import 'package:shared_preferences/shared_preferences.dart';

class GlobalData {
   String _name = "";
   double _height = 0.0; // in cm
   double _weight  = 0.0; // in kg
   int _calorieGoal=  0; // calories per day
   int _waterGoal = 0; // ml per day
  String? _photoUrl = ""; // optional photo URL
  int _number= 0;
  String _password= '';
  int _age = 18;

  // Singleton pattern for global state management

  double bmi = 0.0;

  double fat = 0.0;

  var email;


  // Getters
  String get name => _name;
  double get height => _height;
  double get weight => _weight;
  int get calorieGoal => _calorieGoal;
  int get waterGoal => _waterGoal;
  String? get photoUrl => _photoUrl;
  int get number => _number;
  String get password => password;
    int get age => _age;

  set email(String email) {}


  // Setters
  set name(String value) {
    _name = value;
    saveToPrefs('name', value);
  }

  set height(double value) {
    _height = value;
    saveToPrefs('height', value.toString());
  }
  set number(int value)
  {
    _number = value;
    saveToPrefs('number', number.toString());
  }

  set age(int value)
  {
    _number = value;
    saveToPrefs('age',value.toString());
  }
  set password(String value)
  {
    password = value;
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

  // Method to initialize global data from shared preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('name') ?? '';
    _height = prefs.getDouble('height') ?? 0.0;
    _weight = prefs.getDouble('weight') ?? 0.0;
    _calorieGoal = prefs.getInt('calorieGoal') ?? 0;
    _waterGoal = prefs.getInt('waterGoal') ?? 0;
    _photoUrl = prefs.getString('photoUrl');
    _number = prefs.getInt('number')??0;
    _password = prefs.getString('password')??'';
        _age = prefs.getInt('age')??0;

  }

  // Private method to save a single value to shared preferences
  Future<void> saveToPrefs(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
