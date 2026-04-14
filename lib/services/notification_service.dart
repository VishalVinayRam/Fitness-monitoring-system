import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/entry.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'life_tracker_plans';
  static const _channelName = 'Plans & Reminders';
  static const _channelDesc = 'Notifications for your upcoming plans';

  static const _photoChannelId = 'photo_reminder';
  static const _photoChannelName = 'Daily Photo Reminder';
  static const _photoNotifId = 999001;

  static const _focusChannelId = 'focus_timer';
  static const _focusChannelName = 'Focus Timer';
  static const _focusWorkNotifId = 999002;
  static const _focusBreakNotifId = 999003;

  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create high-importance channel for Android
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    const photoChannel = AndroidNotificationChannel(
      _photoChannelId,
      _photoChannelName,
      description: 'Daily end-of-day reminder to capture a photo',
      importance: Importance.defaultImportance,
    );
    const focusChannel = AndroidNotificationChannel(
      _focusChannelId,
      _focusChannelName,
      description: 'Focus session and break timer notifications',
      importance: Importance.high,
    );
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);
    await androidImpl?.createNotificationChannel(photoChannel);
    await androidImpl?.createNotificationChannel(focusChannel);
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted =
        await android?.requestNotificationsPermission() ?? false;
    return granted;
  }

  Future<void> scheduleForEntry(Entry entry) async {
    if (entry.notificationTime == null) return;
    final scheduledDate = entry.notificationTime!;
    if (scheduledDate.isBefore(DateTime.now())) return;

    final id = entry.id.hashCode.abs() % 100000;

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id,
      entry.title,
      entry.content.isEmpty ? entry.typeLabel : entry.content,
      tzDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(entry.content),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelForEntry(String entryId) async {
    final id = entryId.hashCode.abs() % 100000;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async => _plugin.cancelAll();

  // ── Daily photo reminder ────────────────────────────────────────────────────

  /// Schedules (or reschedules) a daily photo reminder at [hour]:[minute].
  Future<void> scheduleDailyPhotoReminder(int hour, int minute) async {
    await cancelPhotoReminder();

    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      _photoNotifId,
      '📸 End of day',
      "Time to capture your day! Open the Photos tab.",
      tz.TZDateTime.from(next, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _photoChannelId,
          _photoChannelName,
          channelDescription: 'Daily end-of-day reminder to capture a photo',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelPhotoReminder() async =>
      _plugin.cancel(_photoNotifId);

  // ── Focus timer notifications ───────────────────────────────────────────────

  Future<void> scheduleFocusWorkEnd(int seconds, {String? label}) async {
    await cancelFocusWorkNotification();
    final fireAt = DateTime.now().add(Duration(seconds: seconds));
    await _plugin.zonedSchedule(
      _focusWorkNotifId,
      '⏱ Focus session complete!',
      label != null ? '"$label" is done. Take a break.' : 'Great work! Time for a break.',
      tz.TZDateTime.from(fireAt, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _focusChannelId,
          _focusChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleFocusBreakEnd(int seconds) async {
    await cancelFocusBreakNotification();
    final fireAt = DateTime.now().add(Duration(seconds: seconds));
    await _plugin.zonedSchedule(
      _focusBreakNotifId,
      '🎯 Break over — ready to focus?',
      'Your break is done. Start your next session.',
      tz.TZDateTime.from(fireAt, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _focusChannelId,
          _focusChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelFocusWorkNotification() async =>
      _plugin.cancel(_focusWorkNotifId);

  Future<void> cancelFocusBreakNotification() async =>
      _plugin.cancel(_focusBreakNotifId);
}
