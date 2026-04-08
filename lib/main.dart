import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/widget_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.init();
  await WidgetService.instance.init();

  runApp(const LifeTrackerApp());
}

class LifeTrackerApp extends StatefulWidget {
  const LifeTrackerApp({super.key});

  @override
  State<LifeTrackerApp> createState() => _LifeTrackerAppState();
}

class _LifeTrackerAppState extends State<LifeTrackerApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _firstLaunchSetup();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme') ?? 'system';
    setState(() {
      _themeMode = saved == 'dark'
          ? ThemeMode.dark
          : saved == 'light'
              ? ThemeMode.light
              : ThemeMode.system;
    });
  }

  Future<void> _firstLaunchSetup() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('first_launch_done') == true) return;

    // On first launch, request storage permission so data goes to public folder
    await StorageService.instance.requestStoragePermission();
    await NotificationService.instance.requestPermission();
    await prefs.setBool('first_launch_done', true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
