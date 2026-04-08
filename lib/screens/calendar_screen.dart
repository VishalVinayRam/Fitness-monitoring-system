import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/entry.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entry_card.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  final List<Entry> entries;
  final Future<void> Function() onRefresh;

  const CalendarScreen({
    super.key,
    required this.entries,
    required this.onRefresh,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  // ---------- helpers ----------

  /// Normalise to midnight so map keys match.
  DateTime _toDay(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Returns the date that represents an entry on the calendar.
  DateTime? _entryCalendarDate(Entry e) {
    if (e.eventDate != null) return _toDay(e.eventDate!);
    // Notes without a date aren't shown on the calendar grid.
    return null;
  }

  Map<DateTime, List<Entry>> get _eventMap {
    final map = <DateTime, List<Entry>>{};
    for (final e in widget.entries) {
      final day = _entryCalendarDate(e);
      if (day == null) continue;
      map.putIfAbsent(day, () => []).add(e);
    }
    return map;
  }

  List<Entry> _entriesForDay(DateTime day) =>
      _eventMap[_toDay(day)] ?? [];

  // Count upcoming (future, not completed) plans
  int get _upcomingCount {
    final now = DateTime.now();
    return widget.entries
        .where((e) =>
            e.type == EntryType.futurePlan &&
            !e.isCompleted &&
            (e.eventDate?.isAfter(now) ?? false))
        .length;
  }

  // ---------- actions ----------

  Future<void> _openAdd(EntryType type) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScreen(
          entries: widget.entries,
          defaultType: type,
          presetDate: _selectedDay,
        ),
      ),
    );
    if (changed == true) await widget.onRefresh();
  }

  Future<void> _openDetail(Entry e) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetailScreen(entries: widget.entries, entryId: e.id),
      ),
    );
    if (result != null) await widget.onRefresh();
  }

  Future<void> _delete(Entry e) async {
    await NotificationService.instance.cancelForEntry(e.id);
    await StorageService.instance.deleteEntry(widget.entries, e.id);
    await widget.onRefresh();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Entry deleted')));
    }
  }

  Future<void> _toggleComplete(Entry e, bool val) async {
    final updated = e.copyWith(isCompleted: val);
    await StorageService.instance.updateEntry(widget.entries, updated);
    await widget.onRefresh();
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedEntries = _entriesForDay(_selectedDay);
    final isToday = isSameDay(_selectedDay, DateTime.now());

    return Scaffold(
      backgroundColor: scheme.surfaceVariant.withOpacity(0.3),
      body: Column(
        children: [
          // ── Calendar card ──
          Card(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Column(
              children: [
                // Upcoming summary strip
                _UpcomingStrip(count: _upcomingCount, scheme: scheme),
                TableCalendar<Entry>(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                  calendarFormat: _format,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                    CalendarFormat.twoWeeks: '2 Weeks',
                    CalendarFormat.week: 'Week',
                  },
                  eventLoader: _entriesForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  onFormatChanged: (f) => setState(() => _format = f),
                  onPageChanged: (focused) => _focusedDay = focused,
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (ctx, day, events) {
                      if (events.isEmpty) return null;
                      return _DotRow(events: events.cast<Entry>());
                    },
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle:
                        TextStyle(color: scheme.primary, fontWeight: FontWeight.bold),
                    selectedDecoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle:
                        TextStyle(color: scheme.onPrimary),
                    markersMaxCount: 3,
                    outsideDaysVisible: false,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonShowsNext: false,
                    titleCentered: true,
                  ),
                ),
              ],
            ),
          ),

          // ── Day header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  isToday
                      ? 'Today'
                      : DateFormat('EEEE, d MMM').format(_selectedDay),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // Quick-add buttons for selected day
                _QuickAddChip(
                  label: 'Past',
                  color: AppTheme.typeColor(EntryTypeColor.pastEvent),
                  onTap: () => _openAdd(EntryType.pastEvent),
                ),
                const SizedBox(width: 6),
                _QuickAddChip(
                  label: 'Plan',
                  color: AppTheme.typeColor(EntryTypeColor.futurePlan),
                  onTap: () => _openAdd(EntryType.futurePlan),
                ),
                const SizedBox(width: 6),
                _QuickAddChip(
                  label: 'Note',
                  color: AppTheme.typeColor(EntryTypeColor.note),
                  onTap: () => _openAdd(EntryType.note),
                ),
              ],
            ),
          ),

          // ── Entry list for selected day ──
          Expanded(
            child: selectedEntries.isEmpty
                ? _EmptyDay(
                    day: _selectedDay,
                    onAdd: () => _openAdd(EntryType.futurePlan),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 80),
                    itemCount: selectedEntries.length,
                    itemBuilder: (_, i) {
                      final e = selectedEntries[i];
                      return EntryCard(
                        entry: e,
                        onTap: () => _openDetail(e),
                        onDelete: () => _delete(e),
                        onToggleComplete: (v) => _toggleComplete(e, v),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------- sub-widgets ----------

class _UpcomingStrip extends StatelessWidget {
  final int count;
  final ColorScheme scheme;
  const _UpcomingStrip({required this.count, required this.scheme});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.typeColor(EntryTypeColor.futurePlan).withOpacity(0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.upcoming_outlined,
              size: 16,
              color: AppTheme.typeColor(EntryTypeColor.futurePlan)),
          const SizedBox(width: 6),
          Text(
            '$count upcoming plan${count == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.typeColor(EntryTypeColor.futurePlan),
            ),
          ),
        ],
      ),
    );
  }
}

/// Coloured dots under a calendar day cell — one dot per entry type present.
class _DotRow extends StatelessWidget {
  final List<Entry> events;
  const _DotRow({required this.events});

  @override
  Widget build(BuildContext context) {
    final types = events.map((e) => e.type).toSet();
    return Positioned(
      bottom: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: types.map((t) {
          final color = AppTheme.typeColor(
            t == EntryType.pastEvent
                ? EntryTypeColor.pastEvent
                : t == EntryType.futurePlan
                    ? EntryTypeColor.futurePlan
                    : EntryTypeColor.note,
          );
          return Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAddChip(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 13, color: color),
            const SizedBox(width: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final DateTime day;
  final VoidCallback onAdd;
  const _EmptyDay({required this.day, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isFuture = day.isAfter(DateTime.now());
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFuture ? Icons.event_available_outlined : Icons.event_busy_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.35),
          ),
          const SizedBox(height: 10),
          Text(
            isFuture ? 'Nothing planned' : 'Nothing recorded',
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.4)),
          ),
          if (isFuture) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add plan for this day'),
            ),
          ],
        ],
      ),
    );
  }
}

