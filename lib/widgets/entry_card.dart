import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';
import '../theme/app_theme.dart';

class EntryCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleComplete;

  const EntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
    required this.onToggleComplete,
  });

  Color get _typeColor {
    switch (entry.type) {
      case EntryType.pastEvent:
        return AppTheme.typeColor(EntryTypeColor.pastEvent);
      case EntryType.futurePlan:
        return AppTheme.typeColor(EntryTypeColor.futurePlan);
      case EntryType.note:
        return AppTheme.typeColor(EntryTypeColor.note);
    }
  }

  IconData get _typeIcon {
    switch (entry.type) {
      case EntryType.pastEvent:
        return Icons.history;
      case EntryType.futurePlan:
        return Icons.event_outlined;
      case EntryType.note:
        return Icons.sticky_note_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: 'Delete',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color accent + icon
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _typeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_typeIcon, size: 14, color: _typeColor),
                            const SizedBox(width: 4),
                            Text(
                              entry.typeLabel.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _typeColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            if (entry.category != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.category!,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: scheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (entry.photoPaths.isNotEmpty)
                              Icon(Icons.photo_library_outlined,
                                  size: 14, color: scheme.outline),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: entry.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: entry.isCompleted
                                ? scheme.onSurface.withOpacity(0.45)
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (entry.content.isNotEmpty)
                          Text(
                            entry.content,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurface.withOpacity(0.65),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 12, color: scheme.outline),
                            const SizedBox(width: 3),
                            Text(
                              _dateLabel,
                              style: TextStyle(
                                  fontSize: 11, color: scheme.outline),
                            ),
                            if (entry.type == EntryType.futurePlan &&
                                entry.notificationTime != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.notifications_active_outlined,
                                  size: 12, color: scheme.primary),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Thumbnail or checkmark
                  const SizedBox(width: 8),
                  if (entry.photoPaths.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(entry.photoPaths.first),
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    )
                  else if (entry.type == EntryType.futurePlan)
                    Checkbox(
                      value: entry.isCompleted,
                      onChanged: (v) => onToggleComplete(v ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _dateLabel {
    final fmt = DateFormat('d MMM yyyy');
    final date = entry.eventDate ?? entry.createdAt;
    return fmt.format(date);
  }
}
