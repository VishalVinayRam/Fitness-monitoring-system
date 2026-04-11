import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/health_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Internal screen state
// ─────────────────────────────────────────────────────────────────────────────
enum _HealthState { loading, healthConnectNotInstalled, notConnected, connected }

// ─────────────────────────────────────────────────────────────────────────────
// Health Screen — reads data via Health Connect (Samsung Health syncs into it)
// ─────────────────────────────────────────────────────────────────────────────

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  _HealthState _state = _HealthState.loading;
  HealthData _data = HealthData.empty;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (HealthService.instance.isAuthorized) {
      await _fetchData();
      if (mounted) setState(() => _state = _HealthState.connected);
    } else {
      if (mounted) setState(() => _state = _HealthState.notConnected);
    }
  }

  Future<void> _fetchData() async {
    _data = await HealthService.instance.fetchTodayData();
  }

  Future<void> _refresh() async {
    setState(() => _state = _HealthState.loading);
    try {
      await _fetchData();
      if (mounted) setState(() => _state = _HealthState.connected);
    } catch (_) {
      if (mounted) setState(() => _state = _HealthState.connected);
    }
  }

  Future<void> _authorize() async {
    setState(() => _state = _HealthState.loading);
    final result = await HealthService.instance.authorize();
    if (!mounted) return;
    switch (result) {
      case AuthResult.success:
        await _fetchData();
        setState(() => _state = _HealthState.connected);
      case AuthResult.healthConnectNotInstalled:
        setState(() => _state = _HealthState.healthConnectNotInstalled);
      case AuthResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied. Grant access in Health Connect.')),
        );
        setState(() => _state = _HealthState.notConnected);
    }
  }

  Future<void> _installHealthConnect() async {
    await HealthService.instance.installHealthConnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health'),
        actions: [
          if (_state == _HealthState.connected)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _refresh,
            ),
        ],
      ),
      body: switch (_state) {
        _HealthState.loading                    => const Center(child: CircularProgressIndicator()),
        _HealthState.healthConnectNotInstalled  => _HealthConnectNotInstalledView(onInstall: _installHealthConnect),
        _HealthState.notConnected               => _ConnectView(onConnect: _authorize),
        _HealthState.connected                  => _DataView(data: _data),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data display
// ─────────────────────────────────────────────────────────────────────────────

class _DataView extends StatelessWidget {
  final HealthData data;
  const _DataView({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(Icons.watch_outlined, color: scheme.primary, size: 18),
              const SizedBox(width: 6),
              Text('Today · $today',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        // Steps — full width with progress bar
        _StepsCard(steps: data.steps),
        const SizedBox(height: 8),

        // 2-column grid for other metrics
        Row(
          children: [
            Expanded(child: _MetricCard(
              icon: Icons.favorite_outline,
              label: 'Heart Rate',
              value: data.heartRate != null
                  ? '${data.heartRate!.toStringAsFixed(0)} bpm'
                  : '—',
              color: Colors.red,
              subtitle: _hrLabel(data.heartRate),
            )),
            const SizedBox(width: 8),
            Expanded(child: _MetricCard(
              icon: Icons.local_fire_department_outlined,
              label: 'Calories',
              value: data.calories != null
                  ? '${data.calories!.toStringAsFixed(0)} kcal'
                  : '—',
              color: Colors.orange,
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _MetricCard(
              icon: Icons.bedtime_outlined,
              label: 'Sleep',
              value: data.sleepHours != null
                  ? _formatSleep(data.sleepHours!)
                  : '—',
              color: Colors.indigo,
              subtitle: _sleepLabel(data.sleepHours),
            )),
            const SizedBox(width: 8),
            Expanded(child: _MetricCard(
              icon: Icons.air_outlined,
              label: 'Blood Oxygen',
              value: data.spo2 != null
                  ? '${data.spo2!.toStringAsFixed(1)}%'
                  : '—',
              color: Colors.teal,
              subtitle: _spo2Label(data.spo2),
            )),
          ],
        ),
        const SizedBox(height: 8),
        _MetricCard(
          icon: Icons.psychology_outlined,
          label: 'Stress',
          value: data.stress != null ? '${data.stress}' : '—',
          color: Colors.deepPurple,
          subtitle: _stressLabel(data.stress),
          fullWidth: true,
          extraWidget: data.stress != null
              ? LinearProgressIndicator(
                  value: data.stress! / 99.0,
                  color: _stressColor(data.stress!),
                  backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                )
              : null,
        ),
      ],
    );
  }

  static String _formatSleep(double h) {
    final hrs = h.floor();
    final mins = ((h - hrs) * 60).round();
    return mins > 0 ? '${hrs}h ${mins}m' : '${hrs}h';
  }

  static String? _hrLabel(double? bpm) {
    if (bpm == null) return null;
    if (bpm < 60) return 'Below normal';
    if (bpm <= 100) return 'Normal';
    return 'Elevated';
  }

  static String? _sleepLabel(double? h) {
    if (h == null) return null;
    if (h < 6) return 'Below recommended';
    if (h <= 9) return 'Good';
    return 'Long';
  }

  static String? _spo2Label(double? v) {
    if (v == null) return null;
    if (v >= 95) return 'Normal';
    if (v >= 90) return 'Slightly low';
    return 'Low';
  }

  static String? _stressLabel(int? v) {
    if (v == null) return null;
    if (v <= 25) return 'Relaxed';
    if (v <= 50) return 'Normal';
    if (v <= 75) return 'Medium stress';
    return 'High stress';
  }

  static Color _stressColor(int v) {
    if (v <= 25) return Colors.green;
    if (v <= 50) return Colors.lightGreen;
    if (v <= 75) return Colors.orange;
    return Colors.red;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Steps card (full width with goal progress)
// ─────────────────────────────────────────────────────────────────────────────

class _StepsCard extends StatelessWidget {
  final int? steps;
  static const int _goal = 10000;

  const _StepsCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = steps != null ? (steps! / _goal).clamp(0.0, 1.0) : 0.0;
    final reached = (steps ?? 0) >= _goal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_walk, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text('Steps',
                    style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                Text(
                  steps != null
                      ? NumberFormat('#,###').format(steps)
                      : '—',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: reached
                          ? Colors.green.shade700
                          : scheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                color: reached ? Colors.green : Colors.green.shade300,
                backgroundColor: Colors.green.withValues(alpha: 0.1),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps != null
                  ? reached
                      ? '🎉 Goal reached! (${NumberFormat('#,###').format(_goal)} steps)'
                      : '${NumberFormat('#,###').format(_goal - steps!)} steps to goal'
                  : 'Goal: ${NumberFormat('#,###').format(_goal)} steps',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic metric card
// ─────────────────────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;
  final bool fullWidth;
  final Widget? extraWidget;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
    this.fullWidth = false,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7))),
                if (fullWidth) ...[
                  const Spacer(),
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold, color: color)),
                ],
              ],
            ),
            if (!fullWidth) ...[
              const SizedBox(height: 6),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55))),
            ],
            if (extraWidget != null) ...[
              const SizedBox(height: 8),
              extraWidget!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Not connected view
// ─────────────────────────────────────────────────────────────────────────────

class _ConnectView extends StatelessWidget {
  final VoidCallback onConnect;
  const _ConnectView({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.watch_outlined,
                size: 80, color: scheme.outline.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text('Connect Health Data',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Grant access to Health Connect to pull steps, heart rate, sleep, calories and SpO2 from your Samsung Health app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 6),
            Text(
              'Make sure Samsung Health → Settings → Health Connect syncing is enabled.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.link),
              label: const Text('Connect Health Connect'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Health Connect not installed view
// ─────────────────────────────────────────────────────────────────────────────

class _HealthConnectNotInstalledView extends StatelessWidget {
  final VoidCallback onInstall;
  const _HealthConnectNotInstalledView({required this.onInstall});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 72, color: Colors.orange.shade400),
            const SizedBox(height: 20),
            Text('Health Connect Required',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Health Connect is not installed on this device. It is needed to read data from Samsung Health.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onInstall,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Install Health Connect'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
