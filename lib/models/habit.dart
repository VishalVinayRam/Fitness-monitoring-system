import 'package:flutter/material.dart';

enum HabitFrequency { daily, weekly }

const List<String> kHabitColors = [
  '#2E7D32', '#1565C0', '#AD1457', '#E65100',
  '#6A1B9A', '#00838F', '#F9A825', '#4E342E',
];

class Habit {
  final String id;
  final String name;
  final String emoji;
  final HabitFrequency frequency;
  final int weeklyTarget;
  final String color;
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.frequency,
    this.weeklyTarget = 1,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'frequency': frequency.name,
        'weeklyTarget': weeklyTarget,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String? ?? '✅',
        frequency: HabitFrequency.values
            .firstWhere((f) => f.name == j['frequency'], orElse: () => HabitFrequency.daily),
        weeklyTarget: j['weeklyTarget'] as int? ?? 1,
        color: j['color'] as String? ?? '#2E7D32',
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Habit copyWith({
    String? name,
    String? emoji,
    HabitFrequency? frequency,
    int? weeklyTarget,
    String? color,
  }) =>
      Habit(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        frequency: frequency ?? this.frequency,
        weeklyTarget: weeklyTarget ?? this.weeklyTarget,
        color: color ?? this.color,
        createdAt: createdAt,
      );

  Color get flutterColor {
    final h = color.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

class HabitLog {
  final String habitId;
  final String dateKey; // YYYY-MM-DD local time
  final int completedCount;

  const HabitLog({
    required this.habitId,
    required this.dateKey,
    required this.completedCount,
  });

  Map<String, dynamic> toJson() => {
        'habitId': habitId,
        'dateKey': dateKey,
        'completedCount': completedCount,
      };

  factory HabitLog.fromJson(Map<String, dynamic> j) => HabitLog(
        habitId: j['habitId'] as String,
        dateKey: j['dateKey'] as String,
        completedCount: j['completedCount'] as int? ?? 0,
      );

  HabitLog copyWith({int? completedCount}) => HabitLog(
        habitId: habitId,
        dateKey: dateKey,
        completedCount: completedCount ?? this.completedCount,
      );
}

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
