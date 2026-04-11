import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Camera / Photo Gallery Screen
// ─────────────────────────────────────────────────────────────────────────────

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => CameraScreenState();
}

// State is public so HomeScreen can call showSourcePicker via GlobalKey.
class CameraScreenState extends State<CameraScreen> {
  final _picker = ImagePicker();

  List<String> _labels = [];
  String? _selectedLabel;
  List<String> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    final labels = await StorageService.instance.loadLabels();
    setState(() {
      _labels = labels;
      _selectedLabel = labels.isNotEmpty ? labels.first : null;
      _loading = false;
    });
    if (_selectedLabel != null) await _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    if (_selectedLabel == null) return;
    final photos =
        await StorageService.instance.getPhotosForLabel(_selectedLabel!);
    if (mounted) setState(() => _photos = photos);
  }

  Future<void> _selectLabel(String label) async {
    setState(() {
      _selectedLabel = label;
      _photos = [];
    });
    await _loadPhotos();
  }

  Future<void> _addLabel() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Label name'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Add')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final lower = name.toLowerCase();
    if (_labels.any((l) => l.toLowerCase() == lower)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"$name" already exists')));
      }
      return;
    }
    final updated = [..._labels, name];
    await StorageService.instance.saveLabels(updated);
    setState(() {
      _labels = updated;
      _selectedLabel = name;
      _photos = [];
    });
  }

  Future<void> _removeLabel(String label) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove "$label"?'),
        content: const Text(
            'The label will be removed. Photos inside are NOT deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final updated = _labels.where((l) => l != label).toList();
    await StorageService.instance.saveLabels(updated);
    setState(() {
      _labels = updated;
      _selectedLabel = updated.isNotEmpty ? updated.first : null;
      _photos = [];
    });
    if (_selectedLabel != null) await _loadPhotos();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedLabel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a label first')));
      return;
    }

    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera permission denied')));
        }
        return;
      }
    }

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (file == null) return;

    await StorageService.instance
        .copyPhotoToLabelFolder(file.path, _selectedLabel!);
    await _loadPhotos();
  }

  void showSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePhoto(String path) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
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
    await StorageService.instance.deletePhoto(path);
    await _loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // ── Label strip ──────────────────────────────────────────────────
        Material(
          color: scheme.surface,
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._labels.map((label) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _LabelChip(
                          label: label,
                          selected: label == _selectedLabel,
                          onTap: () => _selectLabel(label),
                          onLongPress: () => _removeLabel(label),
                        ),
                      )),
                  // Add label button
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    onPressed: _addLabel,
                    side: BorderSide(color: scheme.outline.withOpacity(0.4)),
                    backgroundColor: Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Photo grid ───────────────────────────────────────────────────
        Expanded(
          child: _selectedLabel == null
              ? _EmptyLabelState(onAdd: _addLabel)
              : _photos.isEmpty
                  ? _EmptyPhotoState(
                      label: _selectedLabel!,
                      onCapture: showSourcePicker,
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(4),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: _photos.length,
                      itemBuilder: (ctx, i) => _PhotoTile(
                        path: _photos[i],
                        onDelete: () => _deletePhoto(_photos[i]),
                        onTap: () => _openViewer(i),
                      ),
                    ),
        ),
      ],
    );
  }

  void _openViewer(int startIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(
          photos: _photos,
          initialIndex: startIndex,
          onDelete: (path) async {
            await _deletePhoto(path);
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Label chip
// ─────────────────────────────────────────────────────────────────────────────

class _LabelChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _LabelChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onLongPress: onLongPress,
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        labelStyle: TextStyle(
          color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo grid tile
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  final String path;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PhotoTile({
    required this.path,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen photo viewer
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final void Function(String path) onDelete;

  const _PhotoViewer({
    required this.photos,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late PageController _page;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _page = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.photos.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => widget.onDelete(widget.photos[_current]),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _page,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Image.file(
              File(widget.photos[i]),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined,
                      color: Colors.white54, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyLabelState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyLabelState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label_outline,
              size: 72,
              color:
                  Theme.of(context).colorScheme.outline.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No labels yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5))),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add a label'),
          ),
        ],
      ),
    );
  }
}

class _EmptyPhotoState extends StatelessWidget {
  final String label;
  final VoidCallback onCapture;
  const _EmptyPhotoState({required this.label, required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 72,
              color:
                  Theme.of(context).colorScheme.outline.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No photos in "$label"',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5))),
          const SizedBox(height: 4),
          Text('Long-press a label to remove it',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.35))),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCapture,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Add photo'),
          ),
        ],
      ),
    );
  }
}
