import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/entry.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class AddEditScreen extends StatefulWidget {
  final List<Entry> entries;
  final Entry? existing;
  final EntryType? defaultType;
  /// Pre-fills the event date (used when tapping a calendar day).
  final DateTime? presetDate;

  const AddEditScreen({
    super.key,
    required this.entries,
    this.existing,
    this.defaultType,
    this.presetDate,
  });

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  late EntryType _type;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  DateTime? _eventDate;
  DateTime? _notificationTime;
  String? _category;
  final List<String> _photoPaths = [];
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _type = e.type;
      _titleCtrl.text = e.title;
      _contentCtrl.text = e.content;
      _eventDate = e.eventDate;
      _notificationTime = e.notificationTime;
      _category = e.category;
      _photoPaths.addAll(e.photoPaths);
    } else {
      _type = widget.defaultType ?? EntryType.note;
      // Pre-fill date when coming from calendar
      if (widget.presetDate != null) _eventDate = widget.presetDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // ---------- helpers ----------

  Future<void> _pickDate(bool isNotification) async {
    final now = DateTime.now();
    final initial = isNotification
        ? (_notificationTime ?? now.add(const Duration(hours: 1)))
        : (_eventDate ?? now);

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isNotification ? now : DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final combined =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      if (isNotification) {
        _notificationTime = combined;
      } else {
        _eventDate = combined;
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    setState(() => _saving = true);
    for (final xf in picked) {
      final saved =
          await StorageService.instance.copyPhotoToAppFolder(xf.path);
      _photoPaths.add(saved);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _pickCamera() async {
    final picker = ImagePicker();
    final xf = await picker.pickImage(source: ImageSource.camera);
    if (xf == null) return;
    setState(() => _saving = true);
    final saved =
        await StorageService.instance.copyPhotoToAppFolder(xf.path);
    _photoPaths.add(saved);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    setState(() => _saving = true);

    try {
      if (_isEditing) {
        final updated = widget.existing!.copyWith(
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          eventDate: _eventDate,
          notificationTime: _notificationTime,
          photoPaths: List.from(_photoPaths),
          category: _category,
        );
        await StorageService.instance
            .updateEntry(widget.entries, updated);

        // Re-schedule notification
        await NotificationService.instance.cancelForEntry(updated.id);
        if (updated.type == EntryType.futurePlan &&
            updated.notificationTime != null) {
          await NotificationService.instance.scheduleForEntry(updated);
        }
      } else {
        final entry = Entry(
          id: const Uuid().v4(),
          type: _type,
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          createdAt: DateTime.now(),
          eventDate: _eventDate,
          notificationTime: _notificationTime,
          photoPaths: List.from(_photoPaths),
          category: _category,
        );
        await StorageService.instance.addEntry(widget.entries, entry);

        if (entry.type == EntryType.futurePlan &&
            entry.notificationTime != null) {
          await NotificationService.instance.scheduleForEntry(entry);
        }
      }

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : 'New Entry'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type selector (only when creating)
                  if (!_isEditing) _buildTypeSelector(scheme),
                  const SizedBox(height: 16),

                  // Title
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'What happened or what are you planning?',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),

                  // Content
                  TextFormField(
                    controller: _contentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Details / Notes',
                      hintText: 'Add more details here...',
                      alignLabelWithHint: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 5,
                    minLines: 3,
                  ),
                  const SizedBox(height: 12),

                  // Category
                  _buildCategoryChips(scheme),
                  const SizedBox(height: 12),

                  // Date row
                  if (_type == EntryType.pastEvent ||
                      _type == EntryType.futurePlan)
                    _buildDateTile(
                      icon: Icons.calendar_today_outlined,
                      label: _type == EntryType.pastEvent
                          ? 'Event Date'
                          : 'Planned Date',
                      value: _eventDate,
                      onTap: () => _pickDate(false),
                      onClear: () => setState(() => _eventDate = null),
                    ),

                  // Notification row (only for future plans)
                  if (_type == EntryType.futurePlan) ...[
                    const SizedBox(height: 8),
                    _buildDateTile(
                      icon: Icons.notifications_outlined,
                      label: 'Remind me at',
                      value: _notificationTime,
                      onTap: () => _pickDate(true),
                      onClear: () =>
                          setState(() => _notificationTime = null),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Photos section
                  _buildPhotosSection(scheme),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeSelector(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: scheme.onSurface.withOpacity(0.7))),
        const SizedBox(height: 8),
        Row(
          children: EntryType.values.map((t) {
            final selected = _type == t;
            final color = AppTheme.typeColor(
              t == EntryType.pastEvent
                  ? EntryTypeColor.pastEvent
                  : t == EntryType.futurePlan
                      ? EntryTypeColor.futurePlan
                      : EntryTypeColor.note,
            );
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withOpacity(0.15)
                          : scheme.surfaceVariant,
                      border: Border.all(
                        color: selected ? color : Colors.transparent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          t == EntryType.pastEvent
                              ? Icons.history
                              : t == EntryType.futurePlan
                                  ? Icons.event_outlined
                                  : Icons.sticky_note_2_outlined,
                          color: selected
                              ? color
                              : scheme.onSurface.withOpacity(0.5),
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t == EntryType.pastEvent
                              ? 'Past'
                              : t == EntryType.futurePlan
                                  ? 'Plan'
                                  : 'Note',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: selected
                                ? color
                                : scheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(ColorScheme scheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text('Category:',
              style: TextStyle(
                  fontSize: 13, color: scheme.onSurface.withOpacity(0.7))),
        ),
        ...categoryOptions.map((cat) {
          final selected = _category == cat;
          return FilterChip(
            label: Text(cat, style: const TextStyle(fontSize: 12)),
            selected: selected,
            onSelected: (v) =>
                setState(() => _category = v ? cat : null),
            visualDensity: VisualDensity.compact,
          );
        }),
      ],
    );
  }

  Widget _buildDateTile({
    required IconData icon,
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final fmt = DateFormat('EEE, d MMM yyyy  HH:mm');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: value != null
          ? Text(fmt.format(value),
              style: const TextStyle(fontWeight: FontWeight.w500))
          : const Text('Tap to set'),
      trailing: value != null
          ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildPhotosSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Photos',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            IconButton.outlined(
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              onPressed: _pickCamera,
              tooltip: 'Camera',
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(6),
            ),
            const SizedBox(width: 6),
            IconButton.outlined(
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              onPressed: () => _pickImage(ImageSource.gallery),
              tooltip: 'Gallery',
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(6),
            ),
          ],
        ),
        if (_photoPaths.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photoPaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, idx) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_photoPaths[idx]),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _photoPaths.removeAt(idx)),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
