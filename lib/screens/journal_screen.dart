import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/journal_entry.dart';
import '../models/habit.dart' show dateKey;
import '../services/health_service.dart';
import '../services/storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Journal Screen
// ─────────────────────────────────────────────────────────────────────────────

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<JournalEntry> _entries = [];
  bool _loading = true;
  HealthData _health = HealthData.empty;

  final TextEditingController _contentCtrl = TextEditingController();
  int _todayMood = 3;
  Timer? _debounce;

  static final _todayFmt = DateFormat('EEEE, MMM d');

  String get _todayKey => dateKey(DateTime.now());

  JournalEntry? get _todayEntry {
    try {
      return _entries.firstWhere((e) => e.dateKey == _todayKey);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      StorageService.instance.loadJournal(),
      if (HealthService.instance.isAuthorized)
        HealthService.instance.fetchTodayData()
      else
        Future.value(HealthData.empty),
    ]);

    final entries = results[0] as List<JournalEntry>;
    final health = results[1] as HealthData;
    entries.sort((a, b) => b.dateKey.compareTo(a.dateKey));

    if (!mounted) return;
    setState(() {
      _entries = entries;
      _health = health;
      _loading = false;
      final today = _todayEntry;
      if (today != null) {
        _todayMood = today.mood;
        _contentCtrl.text = today.content;
      }
    });
  }

  void _onContentChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _autoSave);
  }

  void _onMoodChanged(int mood) {
    setState(() => _todayMood = mood);
    _autoSave();
  }

  Future<void> _autoSave() async {
    if (!mounted) return;
    final now = DateTime.now();
    final existing = _todayEntry;
    final JournalEntry updated;

    if (existing != null) {
      updated = existing.copyWith(
        mood: _todayMood,
        content: _contentCtrl.text,
        updatedAt: now,
        steps: _health.steps ?? existing.steps,
        heartRate: _health.heartRate ?? existing.heartRate,
        sleepHours: _health.sleepHours ?? existing.sleepHours,
        calories: _health.calories ?? existing.calories,
        spo2: _health.spo2 ?? existing.spo2,
      );
      final idx = _entries.indexWhere((e) => e.dateKey == _todayKey);
      if (idx >= 0) _entries[idx] = updated;
    } else {
      updated = JournalEntry(
        id: const Uuid().v4(),
        dateKey: _todayKey,
        mood: _todayMood,
        content: _contentCtrl.text,
        createdAt: now,
        updatedAt: now,
        steps: _health.steps,
        heartRate: _health.heartRate,
        sleepHours: _health.sleepHours,
        calories: _health.calories,
        spo2: _health.spo2,
      );
      _entries.insert(0, updated);
    }

    if (mounted) setState(() {});
    await StorageService.instance.saveJournal(_entries);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final past = _entries.where((e) => e.dateKey != _todayKey).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
        children: [
          _TodayCard(
            dateLabel: _todayFmt.format(DateTime.now()),
            mood: _todayMood,
            contentCtrl: _contentCtrl,
            onMoodChanged: _onMoodChanged,
            onContentChanged: _onContentChanged,
            health: _health,
          ),
          const SizedBox(height: 16),
          if (past.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Past entries',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6))),
            ),
            ...past.map((e) => _PastEntryTile(
                  entry: e,
                  onEdit: (updated) async {
                    final idx = _entries.indexWhere((x) => x.id == e.id);
                    if (idx >= 0) {
                      _entries[idx] = updated;
                      setState(() {});
                      await StorageService.instance.saveJournal(_entries);
                    }
                  },
                )),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text('No past entries yet',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4))),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today's entry card
// ─────────────────────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final String dateLabel;
  final int mood;
  final TextEditingController contentCtrl;
  final void Function(int) onMoodChanged;
  final void Function(String) onContentChanged;
  final HealthData health;

  const _TodayCard({
    required this.dateLabel,
    required this.mood,
    required this.contentCtrl,
    required this.onMoodChanged,
    required this.onContentChanged,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Text('Today · $dateLabel',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: scheme.primary)),
              ],
            ),
            const SizedBox(height: 14),

            // Mood picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: kMoodEmojis.entries.map((e) {
                final selected = mood == e.key;
                return GestureDetector(
                  onTap: () => onMoodChanged(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primaryContainer
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(fontSize: selected ? 32 : 24),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Health snapshot (only shown if any data is available)
            if (health.steps != null || health.heartRate != null ||
                health.sleepHours != null || health.calories != null)
              _HealthChips(
                steps: health.steps,
                heartRate: health.heartRate,
                sleepHours: health.sleepHours,
                calories: health.calories,
              ),

            // Content field
            TextField(
              controller: contentCtrl,
              onChanged: onContentChanged,
              maxLines: null,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: 'How was your day?',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Past entry tile (expandable)
// ─────────────────────────────────────────────────────────────────────────────

class _PastEntryTile extends StatefulWidget {
  final JournalEntry entry;
  final Future<void> Function(JournalEntry) onEdit;

  const _PastEntryTile({required this.entry, required this.onEdit});

  @override
  State<_PastEntryTile> createState() => _PastEntryTileState();
}

class _PastEntryTileState extends State<_PastEntryTile> {
  bool _expanded = false;

  static final _dateFmt = DateFormat('EEEE, MMM d, yyyy');

  Future<void> _showEdit() async {
    final ctrl = TextEditingController(text: widget.entry.content);
    int mood = widget.entry.mood;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_dateFmt.format(DateTime.parse(widget.entry.dateKey
                  .replaceAll('-', ' ')
                  .split(' ')
                  .reduce((a, b) => '$a-$b'))),
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: kMoodEmojis.entries.map((e) {
                  final sel = mood == e.key;
                  return GestureDetector(
                    onTap: () => setInner(() => mood = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sel
                            ? Theme.of(ctx).colorScheme.primaryContainer
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(e.value,
                          style: TextStyle(fontSize: sel ? 32 : 24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: null,
                minLines: 3,
                decoration: const InputDecoration(hintText: 'Entry...'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final updated = widget.entry.copyWith(
                      mood: mood,
                      content: ctrl.text,
                      updatedAt: DateTime.now(),
                    );
                    Navigator.pop(ctx);
                    await widget.onEdit(updated);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = widget.entry;

    // Parse dateKey safely
    final parts = e.dateKey.split('-');
    final entryDate = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        scheme.primaryContainer.withValues(alpha: 0.6),
                    radius: 20,
                    child: Text(e.moodEmoji,
                        style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEE, MMM d, yyyy').format(entryDate),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (!_expanded && e.content.isNotEmpty)
                          Text(
                            e.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.6)),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (e.hasHealthData) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            _HealthChips(
                              steps: e.steps,
                              heartRate: e.heartRate,
                              sleepHours: e.sleepHours,
                              calories: e.calories,
                            ),
                          ],
                          if (e.content.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            if (!e.hasHealthData) const Divider(height: 1),
                            const SizedBox(height: 10),
                            Text(e.content,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _showEdit,
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Edit'),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact health chip row
// ─────────────────────────────────────────────────────────────────────────────

class _HealthChips extends StatelessWidget {
  final int? steps;
  final double? heartRate;
  final double? sleepHours;
  final double? calories;

  const _HealthChips({
    this.steps,
    this.heartRate,
    this.sleepHours,
    this.calories,
  });

  static String _sleep(double h) {
    final hrs = h.floor();
    final mins = ((h - hrs) * 60).round();
    return mins > 0 ? '${hrs}h ${mins}m' : '${hrs}h';
  }

  @override
  Widget build(BuildContext context) {
    final chips = <({IconData icon, String label, Color color})>[
      if (steps != null)
        (icon: Icons.directions_walk, label: NumberFormat('#,###').format(steps), color: Colors.green),
      if (heartRate != null)
        (icon: Icons.favorite_outline, label: '${heartRate!.toStringAsFixed(0)} bpm', color: Colors.red),
      if (sleepHours != null)
        (icon: Icons.bedtime_outlined, label: _sleep(sleepHours!), color: Colors.indigo),
      if (calories != null)
        (icon: Icons.local_fire_department_outlined, label: '${calories!.toStringAsFixed(0)} kcal', color: Colors.orange),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips.map((c) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: c.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(c.icon, size: 13, color: c.color),
              const SizedBox(width: 4),
              Text(c.label,
                  style: TextStyle(
                      fontSize: 12,
                      color: c.color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
