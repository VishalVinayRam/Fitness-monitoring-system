import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/entry.dart';

class StorageService {
  static const String _dataFileName = 'data.json';
  static const String _appFolderName = 'LifeTracker';
  static const String _photosFolderName = 'photos';

  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  Directory? _appDir;

  // Tries external public storage first so data survives reinstall.
  // Falls back to app external files dir if permission denied.
  Future<Directory> get appDir async {
    if (_appDir != null) return _appDir!;

    final hasManage = await Permission.manageExternalStorage.isGranted;
    if (hasManage) {
      final dir = Directory('/storage/emulated/0/$_appFolderName');
      await dir.create(recursive: true);
      _appDir = dir;
      return dir;
    }

    // Fallback: external app files dir (not deleted on uninstall on most ROMs)
    final external = await getExternalStorageDirectory();
    if (external != null) {
      final dir = Directory('${external.path}/$_appFolderName');
      await dir.create(recursive: true);
      _appDir = dir;
      return dir;
    }

    // Last resort: internal app documents dir
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_appFolderName');
    await dir.create(recursive: true);
    _appDir = dir;
    return dir;
  }

  Future<Directory> get photosDir async {
    final base = await appDir;
    final dir = Directory('${base.path}/$_photosFolderName');
    await dir.create(recursive: true);
    return dir;
  }

  Future<File> get _dataFile async {
    final dir = await appDir;
    return File('${dir.path}/$_dataFileName');
  }

  Future<String> get storagePath async {
    final dir = await appDir;
    return dir.path;
  }

  // ---------- Permissions ----------

  Future<bool> requestStoragePermission() async {
    // Android 11+ needs MANAGE_EXTERNAL_STORAGE for public folder access
    if (await Permission.manageExternalStorage.isDenied) {
      final result = await Permission.manageExternalStorage.request();
      if (result.isGranted) {
        _appDir = null; // reset so appDir re-evaluates
        return true;
      }
      return false;
    }
    return true;
  }

  // ---------- CRUD ----------

  Future<List<Entry>> loadEntries() async {
    try {
      final file = await _dataFile;
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List;
      return list.map((e) => Entry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEntries(List<Entry> entries) async {
    final file = await _dataFile;
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    await file.writeAsString(json);
  }

  Future<void> addEntry(List<Entry> entries, Entry entry) async {
    entries.add(entry);
    await saveEntries(entries);
  }

  Future<void> updateEntry(List<Entry> entries, Entry updated) async {
    final idx = entries.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      entries[idx] = updated;
      await saveEntries(entries);
    }
  }

  Future<void> deleteEntry(List<Entry> entries, String id) async {
    final entry = entries.firstWhere((e) => e.id == id);
    // Delete associated photos from our managed folder
    for (final path in entry.photoPaths) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    entries.removeWhere((e) => e.id == id);
    await saveEntries(entries);
  }

  // ---------- Photo helpers ----------

  /// Copies an image from its picked path into the app's photos folder.
  /// Returns the new persistent path.
  Future<String> copyPhotoToAppFolder(String sourcePath) async {
    final dir = await photosDir;
    final ext = sourcePath.split('.').last;
    final dest =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<void> deletePhoto(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
