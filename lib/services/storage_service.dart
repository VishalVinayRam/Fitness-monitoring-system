import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/entry.dart';
import '../models/expense.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';

class StorageService {
  static const String _dataFileName = 'data.json';
  static const String _labelsFileName = 'photo_labels.json';
  static const String _habitsFileName = 'habits.json';
  static const String _expensesFileName = 'expenses.json';
  static const String _journalFileName = 'journal.json';
  static const String _appFolderName = 'LifeTracker';
  static const String _photosFolderName = 'photos';

  static const List<String> _defaultLabels = ['medicine', 'ss', 'documents'];

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

  Future<Directory> getLabelPhotosDir(String label) async {
    final base = await appDir;
    final dir = Directory('${base.path}/$_photosFolderName/$label');
    await dir.create(recursive: true);
    return dir;
  }

  Future<File> get _dataFile async {
    final dir = await appDir;
    return File('${dir.path}/$_dataFileName');
  }

  Future<File> get _labelsFile async {
    final dir = await appDir;
    return File('${dir.path}/$_labelsFileName');
  }

  Future<File> get _habitsFile async {
    final dir = await appDir;
    return File('${dir.path}/$_habitsFileName');
  }

  Future<File> get _expensesFile async {
    final dir = await appDir;
    return File('${dir.path}/$_expensesFileName');
  }

  Future<File> get _journalFile async {
    final dir = await appDir;
    return File('${dir.path}/$_journalFileName');
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

  /// Copies an image into a label-specific sub-folder. Returns the new path.
  Future<String> copyPhotoToLabelFolder(String sourcePath, String label) async {
    final dir = await getLabelPhotosDir(label);
    final ext = sourcePath.split('.').last.toLowerCase();
    final name = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final dest = '${dir.path}/$name';
    await File(sourcePath).copy(dest);
    return dest;
  }

  /// Returns all photo file paths for a label, newest first.
  Future<List<String>> getPhotosForLabel(String label) async {
    final dir = await getLabelPhotosDir(label);
    if (!await dir.exists()) return [];
    final entities = await dir.list().toList();
    final files = entities
        .whereType<File>()
        .where((f) {
          final lower = f.path.toLowerCase();
          return lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.png') ||
              lower.endsWith('.webp');
        })
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files.map((f) => f.path).toList();
  }

  Future<void> deletePhoto(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  // ---------- Label management ----------

  Future<List<String>> loadLabels() async {
    try {
      final file = await _labelsFile;
      if (!await file.exists()) return List.from(_defaultLabels);
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List;
      return list.cast<String>();
    } catch (_) {
      return List.from(_defaultLabels);
    }
  }

  Future<void> saveLabels(List<String> labels) async {
    final file = await _labelsFile;
    await file.writeAsString(jsonEncode(labels));
  }

  // ---------- Habits ----------

  Future<({List<Habit> habits, List<HabitLog> logs})> loadHabits() async {
    try {
      final file = await _habitsFile;
      if (!await file.exists()) return (habits: <Habit>[], logs: <HabitLog>[]);
      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final habits = (map['habits'] as List? ?? [])
          .map((e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList();
      final logs = (map['logs'] as List? ?? [])
          .map((e) => HabitLog.fromJson(e as Map<String, dynamic>))
          .toList();
      return (habits: habits, logs: logs);
    } catch (_) {
      return (habits: <Habit>[], logs: <HabitLog>[]);
    }
  }

  Future<void> saveHabits(List<Habit> habits, List<HabitLog> logs) async {
    final file = await _habitsFile;
    await file.writeAsString(jsonEncode({
      'habits': habits.map((h) => h.toJson()).toList(),
      'logs': logs.map((l) => l.toJson()).toList(),
    }));
  }

  // ---------- Expenses ----------

  Future<({List<Expense> expenses, List<Budget> budgets})> loadExpenses() async {
    try {
      final file = await _expensesFile;
      if (!await file.exists()) return (expenses: <Expense>[], budgets: <Budget>[]);
      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final expenses = (map['expenses'] as List? ?? [])
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();
      final budgets = (map['budgets'] as List? ?? [])
          .map((e) => Budget.fromJson(e as Map<String, dynamic>))
          .toList();
      return (expenses: expenses, budgets: budgets);
    } catch (_) {
      return (expenses: <Expense>[], budgets: <Budget>[]);
    }
  }

  Future<void> saveExpenses(List<Expense> expenses, List<Budget> budgets) async {
    final file = await _expensesFile;
    await file.writeAsString(jsonEncode({
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'budgets': budgets.map((b) => b.toJson()).toList(),
    }));
  }

  // ---------- Journal ----------

  Future<List<JournalEntry>> loadJournal() async {
    try {
      final file = await _journalFile;
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List;
      return list.map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveJournal(List<JournalEntry> entries) async {
    final file = await _journalFile;
    await file.writeAsString(jsonEncode(entries.map((e) => e.toJson()).toList()));
  }
}
