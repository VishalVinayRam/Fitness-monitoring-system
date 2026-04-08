import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';
import '../screens/add_edit_screen.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class DetailScreen extends StatefulWidget {
  final List<Entry> entries;
  final String entryId;

  const DetailScreen({
    super.key,
    required this.entries,
    required this.entryId,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Entry _entry;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _entry =
        widget.entries.firstWhere((e) => e.id == widget.entryId);
  }

  Color get _typeColor {
    switch (_entry.type) {
      case EntryType.pastEvent:
        return AppTheme.typeColor(EntryTypeColor.pastEvent);
      case EntryType.futurePlan:
        return AppTheme.typeColor(EntryTypeColor.futurePlan);
      case EntryType.note:
        return AppTheme.typeColor(EntryTypeColor.note);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await NotificationService.instance.cancelForEntry(_entry.id);
    await StorageService.instance.deleteEntry(widget.entries, _entry.id);
    if (mounted) Navigator.pop(context, 'deleted');
  }

  Future<void> _toggleComplete() async {
    final updated =
        _entry.copyWith(isCompleted: !_entry.isCompleted);
    await StorageService.instance.updateEntry(widget.entries, updated);
    setState(() => _entry = updated);
  }

  Future<void> _openEdit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScreen(
          entries: widget.entries,
          existing: _entry,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() {
        _entry = widget.entries.firstWhere((e) => e.id == _entry.id);
      });
      Navigator.pop(context, 'updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('EEEE, d MMMM yyyy  HH:mm');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _typeColor.withOpacity(0.1),
        title: Text(_entry.typeLabel,
            style: TextStyle(color: _typeColor, fontWeight: FontWeight.w600)),
        actions: [
          if (_entry.type == EntryType.futurePlan)
            IconButton(
              icon: Icon(
                _entry.isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: _entry.isCompleted ? Colors.green : scheme.outline,
              ),
              tooltip: _entry.isCompleted ? 'Mark incomplete' : 'Mark done',
              onPressed: _toggleComplete,
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _openEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              _entry.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: _entry.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
            ),
            const SizedBox(height: 10),

            // Meta chips
            Wrap(
              spacing: 8,
              children: [
                if (_entry.category != null)
                  Chip(
                    label: Text(_entry.category!,
                        style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: _typeColor.withOpacity(0.1),
                    side: BorderSide(color: _typeColor.withOpacity(0.3)),
                  ),
                if (_entry.isCompleted)
                  Chip(
                    label: const Text('Completed',
                        style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.green.withOpacity(0.1),
                    side: const BorderSide(color: Colors.green),
                    avatar: const Icon(Icons.check, size: 14,
                        color: Colors.green),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),

            const Divider(height: 24),

            // Dates
            _InfoRow(
              icon: Icons.access_time,
              label: 'Created',
              value: fmt.format(_entry.createdAt),
            ),
            if (_entry.eventDate != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: _entry.type == EntryType.pastEvent
                    ? Icons.history
                    : Icons.event_outlined,
                label: _entry.type == EntryType.pastEvent
                    ? 'Event date'
                    : 'Planned date',
                value: fmt.format(_entry.eventDate!),
                color: _typeColor,
              ),
            ],
            if (_entry.notificationTime != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.notifications_active_outlined,
                label: 'Reminder',
                value: fmt.format(_entry.notificationTime!),
                color: scheme.primary,
              ),
            ],

            // Content
            if (_entry.content.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                _entry.content,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.55),
              ),
            ],

            // Photos
            if (_entry.photoPaths.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Photos',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              _buildPhotoGallery(scheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery(ColorScheme scheme) {
    if (_entry.photoPaths.length == 1) {
      return _photoTile(_entry.photoPaths.first, double.infinity, 220);
    }
    return Column(
      children: [
        // Main photo
        _photoTile(_entry.photoPaths[_photoIndex], double.infinity, 220),
        const SizedBox(height: 8),
        // Thumbnail row
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _entry.photoPaths.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, idx) => GestureDetector(
              onTap: () => setState(() => _photoIndex = idx),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: idx == _photoIndex
                        ? scheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    File(_entry.photoPaths[idx]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoTile(String path, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(path),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined, size: 40),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color ?? scheme.outline),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(
                fontSize: 13, color: scheme.onSurface.withOpacity(0.6))),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
