import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entry_card.dart';
import 'add_edit_screen.dart';
import 'calendar_screen.dart';
import 'camera_screen.dart';
import 'detail_screen.dart';
import 'more_screen.dart';
import 'settings_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shell — owns entry list state, bottom nav, shared FAB
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Entry> _entries = [];
  bool _loading = true;
  int _navIndex = 0; // 0 = list, 1 = calendar, 2 = camera
  final GlobalKey<_CameraScreenWrapperState> _cameraKey = GlobalKey();
  bool _fabOpen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await StorageService.instance.loadEntries();
    setState(() {
      _entries
        ..clear()
        ..addAll(data);
      _loading = false;
    });
    await WidgetService.instance.updateWidgets(_entries);
  }

  Future<void> _refresh() async {
    final data = await StorageService.instance.loadEntries();
    setState(() {
      _entries
        ..clear()
        ..addAll(data);
    });
    await WidgetService.instance.updateWidgets(_entries);
  }

  Future<void> _openAdd(EntryType type) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddEditScreen(entries: _entries, defaultType: type),
      ),
    );
    if (changed == true) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceVariant.withOpacity(0.3),
      appBar: AppBar(
        backgroundColor: scheme.surface,
        title: Row(
          children: [
            Icon(Icons.auto_stories,
                color: scheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Life Tracker',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      SettingsScreen(entries: _entries)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _navIndex,
              children: [
                _ListView(entries: _entries, onRefresh: _refresh),
                CalendarScreen(entries: _entries, onRefresh: _refresh),
                _CameraScreenWrapper(key: _cameraKey),
                const MoreScreen(),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) =>
            setState(() { _navIndex = i; _fabOpen = false; }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Entries',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Photos',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'More',
          ),
        ],
      ),
      floatingActionButton: _navIndex == 2
          ? FloatingActionButton(
              heroTag: 'camera_fab',
              onPressed: () => _cameraKey.currentState?.showSourcePicker(),
              child: const Icon(Icons.add_a_photo_outlined),
            )
          : _navIndex == 3
              ? null
              : _buildFab(scheme),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Dim background when FAB menu is open
      extendBody: true,
    );
  }

  void _closeFab() => setState(() => _fabOpen = false);

  Widget _buildFab(ColorScheme scheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded mini-buttons — only visible when open
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.bottomRight,
          child: _fabOpen
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MiniButton(
                      icon: Icons.sticky_note_2_outlined,
                      label: 'Note',
                      color: AppTheme.typeColor(EntryTypeColor.note),
                      onTap: () {
                        _closeFab();
                        _openAdd(EntryType.note);
                      },
                    ),
                    const SizedBox(height: 8),
                    _MiniButton(
                      icon: Icons.event_outlined,
                      label: 'Plan',
                      color: AppTheme.typeColor(EntryTypeColor.futurePlan),
                      onTap: () {
                        _closeFab();
                        _openAdd(EntryType.futurePlan);
                      },
                    ),
                    const SizedBox(height: 8),
                    _MiniButton(
                      icon: Icons.history,
                      label: 'Past Event',
                      color: AppTheme.typeColor(EntryTypeColor.pastEvent),
                      onTap: () {
                        _closeFab();
                        _openAdd(EntryType.pastEvent);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: () => setState(() => _fabOpen = !_fabOpen),
          child: AnimatedRotation(
            turns: _fabOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List view (was previously the whole HomeScreen body)
// ─────────────────────────────────────────────────────────────────────────────

class _ListView extends StatefulWidget {
  final List<Entry> entries;
  final Future<void> Function() onRefresh;

  const _ListView({required this.entries, required this.onRefresh});

  @override
  State<_ListView> createState() => _ListViewState();
}

class _ListViewState extends State<_ListView>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _search = '';

  static const _tabs = ['All', 'Past', 'Plans', 'Notes'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<Entry> _filtered(int tabIndex) {
    List<Entry> source;
    switch (tabIndex) {
      case 1:
        source = widget.entries
            .where((e) => e.type == EntryType.pastEvent)
            .toList();
        break;
      case 2:
        source = widget.entries
            .where((e) => e.type == EntryType.futurePlan)
            .toList();
        break;
      case 3:
        source = widget.entries
            .where((e) => e.type == EntryType.note)
            .toList();
        break;
      default:
        source = List.from(widget.entries);
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      source = source
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.content.toLowerCase().contains(q) ||
              (e.category?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    source.sort((a, b) {
      if (tabIndex == 2) {
        final da = a.eventDate ?? a.createdAt;
        final db = b.eventDate ?? b.createdAt;
        return da.compareTo(db);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return source;
  }

  Future<void> _openAdd(EntryType type) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScreen(
            entries: widget.entries, defaultType: type),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search + tabs
        Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 1,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: SearchBar(
                  hintText: 'Search entries...',
                  leading: const Icon(Icons.search),
                  trailing: _search.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _search = ''),
                          )
                        ]
                      : null,
                  onChanged: (v) => setState(() => _search = v),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                      Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.5)),
                  constraints: const BoxConstraints(
                      maxHeight: 44, minHeight: 44),
                  padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 12)),
                ),
              ),
              TabBar(
                controller: _tab,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
                dividerColor: Colors.transparent,
                onTap: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: List.generate(_tabs.length, _buildTab),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int idx) {
    final items = _filtered(idx);
    if (items.isEmpty) {
      return _EmptyState(
        tabIndex: idx,
        onAdd: () => _openAdd(
          idx == 1
              ? EntryType.pastEvent
              : idx == 2
                  ? EntryType.futurePlan
                  : EntryType.note,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 120),
        itemCount: (idx == 2 ? 1 : 0) + items.length,
        itemBuilder: (ctx, i) {
          if (idx == 2 && i == 0) return _UpcomingSummary(entries: items);
          final entry = items[idx == 2 ? i - 1 : i];
          return EntryCard(
            entry: entry,
            onTap: () => _openDetail(entry),
            onDelete: () => _delete(entry),
            onToggleComplete: (v) => _toggleComplete(entry, v),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _UpcomingSummary extends StatelessWidget {
  final List<Entry> entries;
  const _UpcomingSummary({required this.entries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final pending = entries.where(
        (e) => !e.isCompleted && (e.eventDate?.isAfter(now) ?? false));
    final overdue = entries.where(
        (e) => !e.isCompleted && (e.eventDate?.isBefore(now) ?? false));
    final done = entries.where((e) => e.isCompleted);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem('Upcoming', '${pending.length}',
                  Icons.upcoming_outlined, Colors.green),
              _SummaryItem('Overdue', '${overdue.length}',
                  Icons.warning_amber_outlined, Colors.orange),
              _SummaryItem('Done', '${done.length}',
                  Icons.check_circle_outline, Colors.blueGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;
  final Color color;
  const _SummaryItem(this.label, this.count, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(count,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withOpacity(0.7))),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: label,
          backgroundColor: color,
          foregroundColor: Colors.white,
          onPressed: onTap,
          child: Icon(icon, size: 18),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final int tabIndex;
  final VoidCallback onAdd;
  const _EmptyState({required this.tabIndex, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final msgs = [
      ('No entries yet', 'Start recording your life!', Icons.auto_stories),
      ('No past events', "Log what you've done", Icons.history),
      ('No plans yet', 'Add something to look forward to',
          Icons.event_outlined),
      ('No notes yet', 'Write anything down',
          Icons.sticky_note_2_outlined),
    ];
    final (title, sub, icon) = msgs[tabIndex];

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5))),
          const SizedBox(height: 4),
          Text(sub,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.35))),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add now'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thin wrapper so HomeScreen can call showSourcePicker via GlobalKey
// ─────────────────────────────────────────────────────────────────────────────

class _CameraScreenWrapper extends StatefulWidget {
  const _CameraScreenWrapper({super.key});

  @override
  State<_CameraScreenWrapper> createState() => _CameraScreenWrapperState();
}

class _CameraScreenWrapperState extends State<_CameraScreenWrapper> {
  final GlobalKey<CameraScreenState> _innerKey = GlobalKey();

  void showSourcePicker() => _innerKey.currentState?.showSourcePicker();

  @override
  Widget build(BuildContext context) =>
      CameraScreen(key: _innerKey);
}
