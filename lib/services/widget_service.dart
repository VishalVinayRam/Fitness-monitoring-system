import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';

class WidgetService {
  static const _appGroupId = 'com.lifetracker.app';
  static const _androidWidgetName = 'LifeTrackerWidget';

  static WidgetService? _instance;
  static WidgetService get instance => _instance ??= WidgetService._();
  WidgetService._();

  Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  Future<void> updateWidgets(List<Entry> allEntries) async {
    await _updateUpcomingWidget(allEntries);
    await _updateRecentWidget(allEntries);
    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }

  Future<void> _updateUpcomingWidget(List<Entry> entries) async {
    final now = DateTime.now();
    final upcoming = entries
        .where((e) =>
            e.type == EntryType.futurePlan &&
            !e.isCompleted &&
            (e.eventDate?.isAfter(now) ?? false))
        .toList()
      ..sort((a, b) => a.eventDate!.compareTo(b.eventDate!));

    if (upcoming.isEmpty) {
      await HomeWidget.saveWidgetData('upcoming_title', 'No upcoming plans');
      await HomeWidget.saveWidgetData('upcoming_date', '');
      await HomeWidget.saveWidgetData('upcoming_count', '0');
    } else {
      final next = upcoming.first;
      final fmt = DateFormat('MMM d, HH:mm');
      await HomeWidget.saveWidgetData('upcoming_title', next.title);
      await HomeWidget.saveWidgetData(
          'upcoming_date', fmt.format(next.eventDate!));
      await HomeWidget.saveWidgetData(
          'upcoming_count', '${upcoming.length}');
      await HomeWidget.saveWidgetData(
          'upcoming_category', next.category ?? '');
    }
  }

  Future<void> _updateRecentWidget(List<Entry> entries) async {
    final sorted = List<Entry>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent = sorted.take(3).toList();

    final items = recent
        .map((e) => {'title': e.title, 'type': e.typeLabel})
        .toList();
    await HomeWidget.saveWidgetData('recent_items', jsonEncode(items));
  }
}
