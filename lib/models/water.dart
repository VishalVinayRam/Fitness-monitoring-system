import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:management/models/Userdate.dart';

class WaterViewModel extends ChangeNotifier {
  GlobalData data = GlobalData();
  double _totalWaterConsumed = 0.0;
  String _cardTitle = "Card's Title 1";
  String _subtitle = "Sub title";
  String _lastDrinkTime = "8:26 AM";
  String _bottleStatus = "Your bottle is empty, refill it!";
  String _units = "ml";
  String _dailyGoal = "3.5L";

  double get totalWaterConsumed => _totalWaterConsumed;
  String get cardTitle => _cardTitle;
  String get subtitle => _subtitle;
  String get lastDrinkTime => _lastDrinkTime;
  String get bottleStatus => _bottleStatus;
  String get units => _units;
  String get dailyGoal => _dailyGoal;

  WaterViewModel() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastResetDate = prefs.getString('lastResetDate');
    String currentDate = DateTime.now().toIso8601String().split('T')[0];

    if (lastResetDate == null || lastResetDate != currentDate) {
      _totalWaterConsumed = 0.0;
      await prefs.setString('lastResetDate', currentDate);
    } else {
      _totalWaterConsumed = prefs.getDouble('totalWaterConsumed') ?? 0.0;
    }

    notifyListeners();
  }

  void _saveTotalWaterConsumed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('totalWaterConsumed', _totalWaterConsumed);
  }

  void updateWater(double value) {
    _totalWaterConsumed += value;
    _saveTotalWaterConsumed();
    notifyListeners();
  }

  void updateLastDrinkTime(String time) {
    _lastDrinkTime = time;
    notifyListeners();
  }

  void updateBottleStatus(String status) {
    _bottleStatus = status;
    notifyListeners();
  }

  void updateTitle(String title) {
    _cardTitle = title;
    notifyListeners();
  }

  void updateSubtitle(String subtitle) {
    _subtitle = subtitle;
    notifyListeners();
  }

  void updateUnits(String units) {
    _units = units;
    notifyListeners();
  }

  void updateDailyGoal(String goal) {
    _dailyGoal = goal;
    notifyListeners();
  }
}
