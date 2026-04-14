import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';
import '../models/expense.dart';
import '../models/focus_session.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import '../services/storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Review Screen — Weekly & Monthly summary
// ─────────────────────────────────────────────────────────────────────────────

enum _PeriodType { week, month }

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  _PeriodType _period = _PeriodType.week;
  int _offset = 0; // 0 = current, -1 = previous, etc.

  List<Entry> _entries = [];
  List<Habit> _habits = [];
  List<HabitLog> _logs = [];
  List<Expense> _expenses = [];
  List<Budget> _budgets = [];
  List<JournalEntry> _journal = [];
  List<FocusSession> _focus = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        setState(() {
          _period = _tab.index == 0 ? _PeriodType.week : _PeriodType.month;
          _offset = 0;
        });
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      StorageService.instance.loadEntries(),
      StorageService.instance.loadHabits(),
      StorageService.instance.loadExpenses(),
      StorageService.instance.loadJournal(),
      StorageService.instance.loadFocusSessions(),
    ]);

    if (!mounted) return;
    final habitData = results[1] as ({List<Habit> habits, List<HabitLog> logs});
    final expenseData = results[2] as ({List<Expense> expenses, List<Budget> budgets});

    setState(() {
      _entries = results[0] as List<Entry>;
      _habits = habitData.habits;
      _logs = habitData.logs;
      _expenses = expenseData.expenses;
      _budgets = expenseData.budgets;
      _journal = results[3] as List<JournalEntry>;
      _focus = results[4] as List<FocusSession>;
      _loading = false;
    });
  }

  // ── Date range ────────────────────────────────────────────────────────────────

  DateTimeRange get _range {
    final now = DateTime.now();
    if (_period == _PeriodType.week) {
      final weekStart = _startOfWeek(now).add(Duration(days: _offset * 7));
      final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      return DateTimeRange(start: weekStart, end: weekEnd);
    } else {
      final base = DateTime(now.year, now.month + _offset);
      final start = DateTime(base.year, base.month, 1);
      final end = DateTime(base.year, base.month + 1, 0, 23, 59, 59);
      return DateTimeRange(start: start, end: end);
    }
  }

  String get _rangeLabel {
    final r = _range;
    if (_period == _PeriodType.week) {
      return '${DateFormat('MMM d').format(r.start)} – ${DateFormat('MMM d, yyyy').format(r.end)}';
    }
    return DateFormat('MMMM yyyy').format(r.start);
  }

  DateTime _startOfWeek(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  bool _inRange(DateTime d) {
    final r = _range;
    return !d.isBefore(r.start) && !d.isAfter(r.end);
  }

  // ── Computed stats ────────────────────────────────────────────────────────────

  List<JournalEntry> get _journalInRange {
    return _journal.where((e) {
      final parts = e.dateKey.split('-');
      final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return _inRange(d);
    }).toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
  }

  double get _moodAverage {
    final j = _journalInRange;
    if (j.isEmpty) return 0;
    return j.map((e) => e.mood).reduce((a, b) => a + b) / j.length;
  }

  double get _habitHitRate {
    if (_habits.isEmpty) return 0;
    final r = _range;
    final days = r.end.difference(r.start).inDays + 1;
    int expected = 0, completed = 0;

    for (final h in _habits) {
      if (h.frequency == HabitFrequency.daily) {
        for (int i = 0; i < days; i++) {
          final d = r.start.add(Duration(days: i));
          if (d.isAfter(DateTime.now())) break;
          expected++;
          final k = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          if (_logs.any((l) => l.habitId == h.id && l.dateKey == k && l.completedCount > 0)) {
            completed++;
          }
        }
      } else {
        expected += h.weeklyTarget * ((days / 7).ceil());
        for (final l in _logs) {
          if (l.habitId != h.id) continue;
          final parts = l.dateKey.split('-');
          final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          if (_inRange(d)) completed += l.completedCount;
        }
      }
    }
    return expected == 0 ? 0 : (completed / expected).clamp(0.0, 1.0);
  }

  Map<Habit, double> get _habitRates {
    final r = _range;
    final days = r.end.difference(r.start).inDays + 1;
    final result = <Habit, double>{};

    for (final h in _habits) {
      int expected = 0, completed = 0;
      if (h.frequency == HabitFrequency.daily) {
        for (int i = 0; i < days; i++) {
          final d = r.start.add(Duration(days: i));
          if (d.isAfter(DateTime.now())) break;
          expected++;
          final k = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          if (_logs.any((l) => l.habitId == h.id && l.dateKey == k && l.completedCount > 0)) {
            completed++;
          }
        }
      } else {
        expected = h.weeklyTarget * ((days / 7).ceil());
        for (final l in _logs) {
          if (l.habitId != h.id) continue;
          final parts = l.dateKey.split('-');
          final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          if (_inRange(d)) completed += l.completedCount;
        }
      }
      result[h] = expected == 0 ? 0 : (completed / expected).clamp(0.0, 1.0);
    }
    return result;
  }

  List<Expense> get _expensesInRange =>
      _expenses.where((e) => _inRange(e.date)).toList();

  double get _totalSpend =>
      _expensesInRange.fold(0.0, (sum, e) => sum + e.amount);

  Map<String, double> get _spendByCategory {
    final result = <String, double>{};
    for (final e in _expensesInRange) {
      result[e.category] = (result[e.category] ?? 0) + e.amount;
    }
    return Map.fromEntries(
        result.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  int get _focusMinutesInRange =>
      _focus.where((s) => _inRange(s.completedAt)).fold(0, (sum, s) => sum + s.durationMinutes);

  List<Entry> get _entriesInRange =>
      _entries.where((e) => _inRange(e.createdAt)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Week'), Tab(text: 'Month')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _PeriodNavigator(
                  label: _rangeLabel,
                  canGoForward: _offset < 0,
                  onBack: () => setState(() => _offset--),
                  onForward: () => setState(() => _offset++),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildContent() {
    final hasData = _habits.isNotEmpty ||
        _expensesInRange.isNotEmpty ||
        _journalInRange.isNotEmpty ||
        _entriesInRange.isNotEmpty ||
        _focus.any((s) => _inRange(s.completedAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        _OverviewRow(
          habitRate: _habitHitRate,
          moodAvg: _moodAverage,
          focusMinutes: _focusMinutesInRange,
          totalSpend: _totalSpend,
        ),
        const SizedBox(height: 20),

        if (_habits.isNotEmpty) ...[
          _SectionHeader(title: 'Habits', icon: Icons.repeat_rounded, color: Colors.teal),
          const SizedBox(height: 8),
          ..._habitRates.entries.map((e) => _HabitRateRow(habit: e.key, rate: e.value)),
          const SizedBox(height: 20),
        ],

        if (_expensesInRange.isNotEmpty) ...[
          _SectionHeader(
            title: 'Expenses',
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.indigo,
            trailing: Text(
              NumberFormat('#,##0.##').format(_totalSpend),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
          ),
          const SizedBox(height: 8),
          _ExpenseBreakdown(
            byCategory: _spendByCategory,
            total: _totalSpend,
            budgets: _budgets,
            period: _period,
          ),
          const SizedBox(height: 20),
        ],

        if (_journalInRange.isNotEmpty) ...[
          _SectionHeader(
            title: 'Journal',
            icon: Icons.menu_book_outlined,
            color: Colors.deepPurple,
            trailing: _moodAverage > 0
                ? Text(
                    'avg ${_moodAverage.toStringAsFixed(1)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          _MoodRow(entries: _journalInRange),
          const SizedBox(height: 20),
        ],

        if (_focus.any((s) => _inRange(s.completedAt))) ...[
          _SectionHeader(
            title: 'Focus Sessions',
            icon: Icons.timer_outlined,
            color: Colors.orange,
            trailing: Text(
              _formatMinutes(_focusMinutesInRange),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ),
          const SizedBox(height: 8),
          _FocusBreakdown(
              sessions: _focus.where((s) => _inRange(s.completedAt)).toList()),
          const SizedBox(height: 20),
        ],

        if (_entriesInRange.isNotEmpty) ...[
          _SectionHeader(
              title: 'Notable Entries',
              icon: Icons.auto_stories,
              color: Colors.blueGrey),
          const SizedBox(height: 8),
          ..._entriesInRange.take(8).map((e) => _EntryRow(entry: e)),
        ],

        if (!hasData) _EmptyReview(period: _period),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period navigator
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodNavigator extends StatelessWidget {
  final String label;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;

  const _PeriodNavigator({
    required this.label,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onBack),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: canGoForward ? onForward : null,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview row
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewRow extends StatelessWidget {
  final double habitRate;
  final double moodAvg;
  final int focusMinutes;
  final double totalSpend;

  const _OverviewRow({
    required this.habitRate,
    required this.moodAvg,
    required this.focusMinutes,
    required this.totalSpend,
  });

  @override
  Widget build(BuildContext context) {
    final moodEmoji = moodAvg == 0
        ? '—'
        : kMoodEmojis[moodAvg.round().clamp(1, 5)] ?? '😐';

    return Row(
      children: [
        _OverviewCard(
          value: habitRate > 0 ? '${(habitRate * 100).round()}%' : '—',
          label: 'Habits',
          icon: Icons.repeat_rounded,
          color: Colors.teal,
        ),
        const SizedBox(width: 8),
        _OverviewCard(
          value: moodAvg > 0 ? moodEmoji : '—',
          label: 'Mood avg',
          icon: Icons.mood,
          color: Colors.deepPurple,
        ),
        const SizedBox(width: 8),
        _OverviewCard(
          value: focusMinutes > 0 ? _formatMinutes(focusMinutes) : '—',
          label: 'Focus',
          icon: Icons.timer_outlined,
          color: Colors.orange,
        ),
        const SizedBox(width: 8),
        _OverviewCard(
          value: totalSpend > 0 ? NumberFormat.compact().format(totalSpend) : '—',
          label: 'Spend',
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.indigo,
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _OverviewCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habit hit-rate row
// ─────────────────────────────────────────────────────────────────────────────

class _HabitRateRow extends StatelessWidget {
  final Habit habit;
  final double rate;
  const _HabitRateRow({required this.habit, required this.rate});

  @override
  Widget build(BuildContext context) {
    final color = habit.flutterColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(habit.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Text('${(rate * 100).round()}%',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expense breakdown
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseBreakdown extends StatelessWidget {
  final Map<String, double> byCategory;
  final double total;
  final List<Budget> budgets;
  final _PeriodType period;

  const _ExpenseBreakdown({
    required this.byCategory,
    required this.total,
    required this.budgets,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: byCategory.entries.map((e) {
            final fraction = total > 0 ? e.value / total : 0.0;
            final budget = budgets
                .where((b) => b.category == e.key && b.monthlyLimit > 0)
                .map((b) => period == _PeriodType.week ? b.monthlyLimit / 4 : b.monthlyLimit)
                .firstOrNull;
            final overBudget = budget != null && e.value > budget;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13))),
                      Text(
                        budget != null
                            ? '${_fmt(e.value)} / ${_fmt(budget)}'
                            : _fmt(e.value),
                        style: TextStyle(
                          fontSize: 12,
                          color: overBudget
                              ? Colors.red
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(
                          overBudget ? Colors.red : Colors.indigo),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _fmt(double v) => NumberFormat('#,##0.##').format(v);
}

// ─────────────────────────────────────────────────────────────────────────────
// Mood row
// ─────────────────────────────────────────────────────────────────────────────

class _MoodRow extends StatelessWidget {
  final List<JournalEntry> entries;
  const _MoodRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: entries.map((e) {
            final parts = e.dateKey.split('-');
            final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.moodEmoji, style: const TextStyle(fontSize: 22)),
                Text(DateFormat('E').format(d),
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Focus breakdown
// ─────────────────────────────────────────────────────────────────────────────

class _FocusBreakdown extends StatelessWidget {
  final List<FocusSession> sessions;
  const _FocusBreakdown({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = sessions.fold(0, (sum, s) => sum + s.durationMinutes);
    final count = sessions.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _FocusStat(_formatMinutes(total), 'total focus'),
            Container(width: 1, height: 36, color: scheme.outline.withValues(alpha: 0.2)),
            _FocusStat('$count', count == 1 ? 'session' : 'sessions'),
            Container(width: 1, height: 36, color: scheme.outline.withValues(alpha: 0.2)),
            _FocusStat(
                count > 0 ? _formatMinutes(total ~/ count) : '—', 'avg session'),
          ],
        ),
      ),
    );
  }
}

class _FocusStat extends StatelessWidget {
  final String value;
  final String label;
  const _FocusStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry row
// ─────────────────────────────────────────────────────────────────────────────

class _EntryRow extends StatelessWidget {
  final Entry entry;
  const _EntryRow({required this.entry});

  Color _typeColor(EntryType t) {
    switch (t) {
      case EntryType.pastEvent: return Colors.blue;
      case EntryType.futurePlan: return Colors.green;
      case EntryType.note: return Colors.amber;
    }
  }

  IconData _typeIcon(EntryType t) {
    switch (t) {
      case EntryType.pastEvent: return Icons.history;
      case EntryType.futurePlan: return Icons.event_outlined;
      case EntryType.note: return Icons.sticky_note_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(entry.type);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          radius: 18,
          child: Icon(_typeIcon(entry.type), color: color, size: 16),
        ),
        title: Text(entry.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text(DateFormat('MMM d').format(entry.createdAt),
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
        trailing: entry.category != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(entry.category!,
                    style: TextStyle(fontSize: 11, color: color)),
              )
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyReview extends StatelessWidget {
  final _PeriodType period;
  const _EmptyReview({required this.period});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart,
                size: 64,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No data for this ${period == _PeriodType.week ? 'week' : 'month'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _formatMinutes(int m) {
  if (m < 60) return '${m}m';
  final h = m ~/ 60;
  final rem = m % 60;
  return rem > 0 ? '${h}h ${rem}m' : '${h}h';
}
