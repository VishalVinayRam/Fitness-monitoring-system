import 'package:health/health.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HealthService — reads from Health Connect (Android) via the `health` package.
//
// On Samsung devices, Samsung Health syncs data into Health Connect automatically
// once the user enables it in: Samsung Health → Profile → Settings → Health
// Connect → Turn on syncing.
// ─────────────────────────────────────────────────────────────────────────────

enum AuthResult { success, healthConnectNotInstalled, failed }

class HealthData {
  final int? steps;
  final double? heartRate;
  final double? sleepHours;
  final double? calories;
  final int? stress; // not available via Health Connect — kept for UI compat
  final double? spo2; // blood oxygen saturation %

  const HealthData({
    this.steps,
    this.heartRate,
    this.sleepHours,
    this.calories,
    this.stress,
    this.spo2,
  });

  static const empty = HealthData();
}

class HealthService {
  static HealthService? _instance;
  static HealthService get instance => _instance ??= HealthService._();
  HealthService._();

  final _health = Health();
  bool _authorized = false;

  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.BLOOD_OXYGEN,
  ];

  bool get isAuthorized => _authorized;

  /// Returns false when Health Connect is not installed/available on device.
  Future<bool> isHealthConnectAvailable() =>
      _health.isHealthConnectAvailable();

  /// Opens the Health Connect permission screen. Returns [AuthResult].
  Future<AuthResult> authorize() async {
    try {
      final available = await _health.isHealthConnectAvailable();
      if (!available) return AuthResult.healthConnectNotInstalled;

      final granted = await _health.requestAuthorization(_types);
      if (granted) {
        _authorized = true;
        return AuthResult.success;
      }
      return AuthResult.failed;
    } catch (_) {
      return AuthResult.failed;
    }
  }

  /// Installs Health Connect via the Play Store.
  Future<void> installHealthConnect() => _health.installHealthConnect();

  // ── Main fetch ──────────────────────────────────────────────────────────────

  Future<HealthData> fetchTodayData() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final results = await Future.wait([
        _fetchSteps(startOfDay, now),
        _fetchLatestHR(startOfDay, now),
        _fetchSleep(startOfDay, now),
        _fetchCalories(startOfDay, now),
        _fetchLatestSpO2(startOfDay, now),
      ]);

      return HealthData(
        steps: results[0] as int?,
        heartRate: results[1] as double?,
        sleepHours: results[2] as double?,
        calories: results[3] as double?,
        spo2: results[4] as double?,
      );
    } catch (_) {
      return HealthData.empty;
    }
  }

  // ── Steps ───────────────────────────────────────────────────────────────────

  Future<int?> _fetchSteps(DateTime start, DateTime end) async {
    try {
      final total = await _health.getTotalStepsInInterval(start, end);
      return (total != null && total > 0) ? total : null;
    } catch (_) {
      return null;
    }
  }

  // ── Heart Rate ──────────────────────────────────────────────────────────────

  Future<double?> _fetchLatestHR(DateTime start, DateTime end) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.HEART_RATE],
      );
      if (points.isEmpty) return null;
      final v = (points.last.value as NumericHealthValue).numericValue;
      return v > 0 ? v.toDouble() : null;
    } catch (_) {
      return null;
    }
  }

  // ── Sleep ───────────────────────────────────────────────────────────────────

  Future<double?> _fetchSleep(DateTime start, DateTime end) async {
    try {
      // Look back 16 h to capture last night's session
      final from = end.subtract(const Duration(hours: 16));
      final points = await _health.getHealthDataFromTypes(
        startTime: from,
        endTime: end,
        types: [HealthDataType.SLEEP_SESSION],
      );
      if (points.isEmpty) return null;
      int totalMs = 0;
      for (final p in points) {
        totalMs += p.dateTo.difference(p.dateFrom).inMilliseconds;
      }
      final hours = totalMs / 3600000.0;
      return hours > 0 ? hours : null;
    } catch (_) {
      return null;
    }
  }

  // ── Calories ────────────────────────────────────────────────────────────────

  Future<double?> _fetchCalories(DateTime start, DateTime end) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.TOTAL_CALORIES_BURNED],
      );
      if (points.isEmpty) return null;
      double total = 0;
      for (final p in points) {
        total += (p.value as NumericHealthValue).numericValue.toDouble();
      }
      return total > 0 ? total : null;
    } catch (_) {
      return null;
    }
  }

  // ── Blood Oxygen / SpO2 ─────────────────────────────────────────────────────

  Future<double?> _fetchLatestSpO2(DateTime start, DateTime end) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.BLOOD_OXYGEN],
      );
      if (points.isEmpty) return null;
      final v = (points.last.value as NumericHealthValue).numericValue;
      return v > 0 ? v.toDouble() : null;
    } catch (_) {
      return null;
    }
  }
}
