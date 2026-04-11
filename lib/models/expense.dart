import 'package:flutter/material.dart';

const List<String> kExpenseCategories = [
  'Food',
  'Transport',
  'Health',
  'Shopping',
  'Entertainment',
  'Bills',
  'Other',
];

const Map<String, IconData> kCategoryIcons = {
  'Food': Icons.restaurant_outlined,
  'Transport': Icons.directions_car_outlined,
  'Health': Icons.favorite_outline,
  'Shopping': Icons.shopping_bag_outlined,
  'Entertainment': Icons.movie_outlined,
  'Bills': Icons.receipt_long_outlined,
  'Other': Icons.category_outlined,
};

class Expense {
  final String id;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    this.note = '',
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        category: j['category'] as String? ?? 'Other',
        note: j['note'] as String? ?? '',
        date: DateTime.parse(j['date'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Expense copyWith({
    double? amount,
    String? category,
    String? note,
    DateTime? date,
  }) =>
      Expense(
        id: id,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        note: note ?? this.note,
        date: date ?? this.date,
        createdAt: createdAt,
      );
}

class Budget {
  final String category;
  final double monthlyLimit; // 0 = not set

  const Budget({required this.category, required this.monthlyLimit});

  Map<String, dynamic> toJson() => {
        'category': category,
        'monthlyLimit': monthlyLimit,
      };

  factory Budget.fromJson(Map<String, dynamic> j) => Budget(
        category: j['category'] as String,
        monthlyLimit: (j['monthlyLimit'] as num).toDouble(),
      );

  Budget copyWith({double? monthlyLimit}) =>
      Budget(category: category, monthlyLimit: monthlyLimit ?? this.monthlyLimit);
}
