import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF2E7D32); // deep green

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: false),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: false),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
        ),
      );

  // Type colors
  static Color typeColor(EntryTypeColor t) {
    switch (t) {
      case EntryTypeColor.pastEvent:
        return const Color(0xFF1565C0); // blue
      case EntryTypeColor.futurePlan:
        return const Color(0xFF2E7D32); // green
      case EntryTypeColor.note:
        return const Color(0xFFE65100); // orange
    }
  }
}

enum EntryTypeColor { pastEvent, futurePlan, note }
