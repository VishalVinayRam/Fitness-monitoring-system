import 'package:flutter/foundation.dart';

class WaterViewModel extends ChangeNotifier {
  double _totalCaloriesConsumed = 2100;
  String _cardTitle = "Card's Title 1";
  String _subtitle = "Sub title";
  String _lastDrinkTime = "8:26 AM";
  String _bottleStatus = "Your bottle is empty, refill it!";
  String _units = "ml";
  String _dailyGoal = "3.5L";

  double get totalCaloriesConsumed => _totalCaloriesConsumed;
  String get cardTitle => _cardTitle;
  String get subtitle => _subtitle;
  String get lastDrinkTime => _lastDrinkTime;
  String get bottleStatus => _bottleStatus;
  String get units => _units;
  String get dailyGoal => _dailyGoal;

  void updateCalories(double value) {
    _totalCaloriesConsumed += value;
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
