import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/habit.dart';
import '../services/storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habits Screen
// ─────────────────────────────────────────────────────────────────────────────

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Habit> _habits = [];
  List<HabitLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await StorageService.instance.loadHabits();
    setState(() {
      _habits = data.habits;
      _logs = data.logs;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await StorageService.instance.saveHabits(_habits, _logs);
  }

  // ── Streak helpers ──────────────────────────────────────────────────────────

  int _dailyStreak(String habitId) {
    final today = dateKey(DateTime.now());
    // Walk backwards from yesterday (today contributes if checked)
    final todayChecked =
        _logs.any((l) => l.habitId == habitId && l.dateKey == today && l.completedCount > 0);
    int streak = todayChecked ? 1 : 0;
    final base = DateTime.now().subtract(const Duration(days: 1));
    for (int i = 0; i < 365; i++) {
      final d = base.subtract(Duration(days: i));
      final k = dateKey(d);
      final checked =
          _logs.any((l) => l.habitId == habitId && l.dateKey == k && l.completedCount > 0);
      if (!checked) break;
      streak++;
    }
    return streak;
  }

  int _weeklyStreak(String habitId, int target) {
    int streak = 0;
    final now = DateTime.now();
    for (int w = 0; w < 52; w++) {
      final weekStart = _startOfWeek(now.subtract(Duration(days: w * 7)));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final total = _logs
          .where((l) =>
              l.habitId == habitId &&
              _parseDate(l.dateKey).isAfter(weekStart.subtract(const Duration(days: 1))) &&
              _parseDate(l.dateKey).isBefore(weekEnd.add(const Duration(days: 1))))
          .fold(0, (sum, l) => sum + l.completedCount);
      if (total >= target) {
        streak++;
      } else if (w > 0) {
        // Current week (w==0) may be in progress — don't break on it
        break;
      }
    }
    return streak;
  }

  DateTime _startOfWeek(DateTime d) {
    // Monday as start
    final diff = d.weekday - 1;
    return DateTime(d.year, d.month, d.day - diff);
  }

  DateTime _parseDate(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  int _getStreak(Habit h) {
    return h.frequency == HabitFrequency.daily
        ? _dailyStreak(h.id)
        : _weeklyStreak(h.id, h.weeklyTarget);
  }

  // ── Log helpers ─────────────────────────────────────────────────────────────

  HabitLog? _todayLog(String habitId) {
    final k = dateKey(DateTime.now());
    try {
      return _logs.firstWhere((l) => l.habitId == habitId && l.dateKey == k);
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggleDaily(Habit h) async {
    final k = dateKey(DateTime.now());
    final existing = _todayLog(h.id);
    if (existing != null) {
      _logs.remove(existing);
      _logs.add(existing.copyWith(completedCount: existing.completedCount > 0 ? 0 : 1));
    } else {
      _logs.add(HabitLog(habitId: h.id, dateKey: k, completedCount: 1));
    }
    setState(() {});
    await _save();
  }

  Future<void> _incrementWeekly(Habit h) async {
    final k = dateKey(DateTime.now());
    final existing = _todayLog(h.id);
    if (existing != null) {
      final next = existing.completedCount >= h.weeklyTarget ? 0 : existing.completedCount + 1;
      _logs.remove(existing);
      _logs.add(existing.copyWith(completedCount: next));
    } else {
      _logs.add(HabitLog(habitId: h.id, dateKey: k, completedCount: 1));
    }
    setState(() {});
    await _save();
  }

  int _weeklyDoneCount(Habit h) {
    final now = DateTime.now();
    final weekStart = _startOfWeek(now);
    final weekEnd = weekStart.add(const Duration(days: 6));
    return _logs
        .where((l) =>
            l.habitId == h.id &&
            _parseDate(l.dateKey).isAfter(weekStart.subtract(const Duration(days: 1))) &&
            _parseDate(l.dateKey).isBefore(weekEnd.add(const Duration(days: 1))))
        .fold(0, (sum, l) => sum + l.completedCount);
  }

  // ── Add / Edit ──────────────────────────────────────────────────────────────

  Future<void> _showAddEdit([Habit? existing]) async {
    final result = await showModalBottomSheet<Habit>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _HabitForm(habit: existing),
    );
    if (result == null) return;
    if (existing != null) {
      final idx = _habits.indexWhere((h) => h.id == existing.id);
      if (idx >= 0) _habits[idx] = result;
    } else {
      _habits.add(result);
    }
    setState(() {});
    await _save();
  }

  Future<void> _delete(Habit h) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${h.name}"?'),
        content: const Text('All logs for this habit will also be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    _habits.removeWhere((x) => x.id == h.id);
    _logs.removeWhere((l) => l.habitId == h.id);
    setState(() {});
    await _save();
  }

  void _showOptions(Habit h) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () { Navigator.pop(ctx); _showAddEdit(h); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () { Navigator.pop(ctx); _delete(h); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'habits_fab',
        onPressed: _showAddEdit,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? _EmptyHabits(onAdd: _showAddEdit)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                  itemCount: _habits.length,
                  itemBuilder: (_, i) {
                    final h = _habits[i];
                    return _HabitTile(
                      habit: h,
                      streak: _getStreak(h),
                      todayLog: _todayLog(h.id),
                      weeklyDone: h.frequency == HabitFrequency.weekly
                          ? _weeklyDoneCount(h)
                          : 0,
                      onToggle: () => h.frequency == HabitFrequency.daily
                          ? _toggleDaily(h)
                          : _incrementWeekly(h),
                      onLongPress: () => _showOptions(h),
                    );
                  },
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit tile
// ─────────────────────────────────────────────────────────────────────────────

class _HabitTile extends StatelessWidget {
  final Habit habit;
  final int streak;
  final HabitLog? todayLog;
  final int weeklyDone;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  const _HabitTile({
    required this.habit,
    required this.streak,
    required this.todayLog,
    required this.weeklyDone,
    required this.onToggle,
    required this.onLongPress,
  });

  bool get _dailyDone => todayLog != null && todayLog!.completedCount > 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accentColor = habit.flutterColor;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Accent stripe
              Container(width: 5, color: accentColor),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: accentColor.withValues(alpha: 0.12),
                        child: Text(habit.emoji, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(habit.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              habit.frequency == HabitFrequency.daily
                                  ? 'Daily'
                                  : 'Weekly · ${habit.weeklyTarget}×/week',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface.withValues(alpha: 0.55)),
                            ),
                          ],
                        ),
                      ),
                      // Streak badge
                      if (streak > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('🔥 $streak',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      // Toggle
                      if (habit.frequency == HabitFrequency.daily)
                        IconButton(
                          onPressed: onToggle,
                          icon: Icon(
                            _dailyDone ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: _dailyDone ? accentColor : scheme.outline,
                            size: 28,
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: onToggle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: weeklyDone >= habit.weeklyTarget
                                  ? accentColor.withValues(alpha: 0.15)
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: weeklyDone >= habit.weeklyTarget
                                      ? accentColor
                                      : scheme.outline.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '$weeklyDone / ${habit.weeklyTarget}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: weeklyDone >= habit.weeklyTarget
                                    ? accentColor
                                    : scheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit form
// ─────────────────────────────────────────────────────────────────────────────

const _kEmojis = [
  '✅', '💪', '🏃', '🥗', '💧', '📚', '🧘', '😴',
  '🚭', '🍎', '💊', '🧹', '📝', '🎯', '🏋', '🚴',
  '🧠', '❤️', '🌞', '🎵',
];

class _HabitForm extends StatefulWidget {
  final Habit? habit;
  const _HabitForm({this.habit});

  @override
  State<_HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends State<_HabitForm> {
  late TextEditingController _name;
  late String _emoji;
  late HabitFrequency _freq;
  late int _weeklyTarget;
  late String _color;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _name = TextEditingController(text: h?.name ?? '');
    _emoji = h?.emoji ?? '✅';
    _freq = h?.frequency ?? HabitFrequency.daily;
    _weeklyTarget = h?.weeklyTarget ?? 3;
    _color = h?.color ?? kHabitColors.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    final h = widget.habit;
    final result = Habit(
      id: h?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      emoji: _emoji,
      frequency: _freq,
      weeklyTarget: _weeklyTarget,
      color: _color,
      createdAt: h?.createdAt ?? DateTime.now(),
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.habit == null ? 'New Habit' : 'Edit Habit',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _name,
              autofocus: widget.habit == null,
              decoration: const InputDecoration(labelText: 'Habit name'),
            ),
            const SizedBox(height: 16),

            // Emoji picker
            Text('Icon', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kEmojis.map((e) {
                final selected = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: selected
                          ? Border.all(color: scheme.primary, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Frequency
            Text('Frequency', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<HabitFrequency>(
              segments: const [
                ButtonSegment(value: HabitFrequency.daily, label: Text('Daily')),
                ButtonSegment(value: HabitFrequency.weekly, label: Text('Weekly')),
              ],
              selected: {_freq},
              onSelectionChanged: (s) => setState(() => _freq = s.first),
            ),

            // Weekly target (only when weekly)
            if (_freq == HabitFrequency.weekly) ...[
              const SizedBox(height: 16),
              Text('Times per week', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.outlined(
                    icon: const Icon(Icons.remove),
                    onPressed: _weeklyTarget > 1
                        ? () => setState(() => _weeklyTarget--)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$_weeklyTarget',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.add),
                    onPressed: _weeklyTarget < 7
                        ? () => setState(() => _weeklyTarget++)
                        : null,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Color picker
            Text('Color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: kHabitColors.map((hex) {
                final c = Habit(
                        id: '', name: '', emoji: '',
                        frequency: HabitFrequency.daily,
                        color: hex, createdAt: DateTime.now())
                    .flutterColor;
                final selected = hex == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: scheme.onSurface, width: 3)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(widget.habit == null ? 'Add Habit' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyHabits extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyHabits({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.repeat_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No habits yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5))),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add habit'),
          ),
        ],
      ),
    );
  }
}
