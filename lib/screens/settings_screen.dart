import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/entry.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';

class SettingsScreen extends StatefulWidget {
  final List<Entry> entries;
  const SettingsScreen({super.key, required this.entries});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _storagePath = 'Loading...';
  TimeOfDay? _photoReminderTime;

  @override
  void initState() {
    super.initState();
    _loadPath();
    _loadPhotoReminderTime();
  }

  Future<void> _loadPath() async {
    final path = await StorageService.instance.storagePath;
    setState(() => _storagePath = path);
  }

  Future<void> _loadPhotoReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('photo_reminder_time');
    if (saved != null) {
      final parts = saved.split(':');
      setState(() => _photoReminderTime =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
    }
  }

  Future<void> _setPhotoReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _photoReminderTime ?? const TimeOfDay(hour: 20, minute: 0),
      helpText: 'Set daily photo reminder time',
    );
    if (picked == null) return;
    setState(() => _photoReminderTime = picked);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('photo_reminder_time',
        '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}');
    await NotificationService.instance
        .scheduleDailyPhotoReminder(picked.hour, picked.minute);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Photo reminder set for ${picked.format(context)}')));
    }
  }

  Future<void> _cancelPhotoReminder() async {
    await NotificationService.instance.cancelPhotoReminder();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('photo_reminder_time');
    setState(() => _photoReminderTime = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo reminder cancelled')));
    }
  }

  Future<void> _requestPermission() async {
    final granted =
        await StorageService.instance.requestStoragePermission();
    await _loadPath();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(granted
            ? 'Storage permission granted! Data saved to public folder.'
            : 'Permission denied — using app folder (data may be lost on uninstall).'),
      ));
    }
  }

  Future<void> _requestNotificationPermission() async {
    final granted =
        await NotificationService.instance.requestPermission();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(granted
            ? 'Notifications enabled!'
            : 'Notification permission denied.'),
      ));
    }
  }

  Future<void> _refreshWidgets() async {
    await WidgetService.instance.updateWidgets(widget.entries);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Home screen widgets updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Storage section
          _SectionHeader('Storage'),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Data folder'),
            subtitle: Text(_storagePath,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: scheme.onSurface.withOpacity(0.6))),
          ),
          ListTile(
            leading: const Icon(Icons.lock_open_outlined),
            title: const Text('Grant "All Files Access"'),
            subtitle: const Text(
                'Required to store data in a public folder that survives app reinstall'),
            trailing: FilledButton.tonal(
              onPressed: _requestPermission,
              child: const Text('Grant'),
            ),
          ),

          const Divider(),
          _SectionHeader('Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Enable notifications'),
            subtitle: const Text('Needed for plan reminders'),
            trailing: FilledButton.tonal(
              onPressed: _requestNotificationPermission,
              child: const Text('Enable'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_a_photo_outlined),
            title: const Text('Daily photo reminder'),
            subtitle: Text(_photoReminderTime != null
                ? 'Every day at ${_photoReminderTime!.format(context)}'
                : 'Not set'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.tonal(
                  onPressed: _setPhotoReminder,
                  child: Text(_photoReminderTime != null ? 'Change' : 'Set'),
                ),
                if (_photoReminderTime != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    onPressed: _cancelPhotoReminder,
                    tooltip: 'Cancel reminder',
                  ),
                ],
              ],
            ),
          ),

          const Divider(),
          _SectionHeader('Home Screen Widgets'),
          ListTile(
            leading: const Icon(Icons.widgets_outlined),
            title: const Text('Refresh widgets'),
            subtitle:
                const Text('Force-update home screen widget content'),
            trailing: IconButton.outlined(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshWidgets,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Add widget to home screen'),
            subtitle: const Text(
                'Long-press your home screen → Widgets → search "LifeTracker"'),
          ),

          const Divider(),
          _SectionHeader('Data'),
          ListTile(
            leading: Icon(Icons.bar_chart_outlined,
                color: scheme.primary),
            title: const Text('Statistics'),
            subtitle: Text(
              '${widget.entries.length} total entries  •  '
              '${widget.entries.where((e) => e.type == EntryType.pastEvent).length} past events  •  '
              '${widget.entries.where((e) => e.type == EntryType.futurePlan).length} plans  •  '
              '${widget.entries.where((e) => e.type == EntryType.note).length} notes',
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'LifeTracker v1.0  •  Data stored at: $_storagePath',
              style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurface.withOpacity(0.35)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color:
              Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
