import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/focus_session.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Focus Timer Screen
// ─────────────────────────────────────────────────────────────────────────────

enum _TimerPhase { idle, work, workPaused, breakPhase }

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with TickerProviderStateMixin {
  // ── Config ──────────────────────────────────────────────────────────────────
  int _workMinutes = 25;
  int _breakMinutes = 5;

  // ── Timer state ─────────────────────────────────────────────────────────────
  _TimerPhase _phase = _TimerPhase.idle;
  late int _remaining; // seconds
  Timer? _ticker;
  final _labelCtrl = TextEditingController();

  // ── Session history ─────────────────────────────────────────────────────────
  List<FocusSession> _sessions = [];
  bool _loading = true;

  // ── Animations ──────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _remaining = _workMinutes * 60;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final s = await StorageService.instance.loadFocusSessions();
    s.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    if (!mounted) return;
    setState(() {
      _sessions = s;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  // ── Timer helpers ────────────────────────────────────────────────────────────

  int get _totalSeconds =>
      (_phase == _TimerPhase.breakPhase ? _breakMinutes : _workMinutes) * 60;

  double get _progress => _totalSeconds > 0 ? 1 - (_remaining / _totalSeconds) : 0;

  void _startWork() {
    _phase = _TimerPhase.work;
    _remaining = _workMinutes * 60;
    _tick();
    NotificationService.instance.scheduleFocusWorkEnd(
      _remaining,
      label: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
    );
  }

  void _pauseWork() {
    _ticker?.cancel();
    NotificationService.instance.cancelFocusWorkNotification();
    setState(() => _phase = _TimerPhase.workPaused);
  }

  void _resumeWork() {
    setState(() => _phase = _TimerPhase.work);
    _tick();
    NotificationService.instance.scheduleFocusWorkEnd(
      _remaining,
      label: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
    );
  }

  void _startBreak() {
    _phase = _TimerPhase.breakPhase;
    _remaining = _breakMinutes * 60;
    _tick();
    NotificationService.instance.scheduleFocusBreakEnd(_remaining);
  }

  void _skipBreak() {
    _ticker?.cancel();
    NotificationService.instance.cancelFocusBreakNotification();
    setState(() {
      _phase = _TimerPhase.idle;
      _remaining = _workMinutes * 60;
    });
  }

  void _reset() {
    _ticker?.cancel();
    NotificationService.instance.cancelFocusWorkNotification();
    NotificationService.instance.cancelFocusBreakNotification();
    setState(() {
      _phase = _TimerPhase.idle;
      _remaining = _workMinutes * 60;
    });
  }

  void _tick() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) {
        _ticker?.cancel();
        _onPhaseComplete();
        return;
      }
      setState(() => _remaining--);
    });
  }

  Future<void> _onPhaseComplete() async {
    if (_phase == _TimerPhase.work) {
      final label = _labelCtrl.text.trim();
      final session = FocusSession(
        id: const Uuid().v4(),
        durationMinutes: _workMinutes,
        label: label.isEmpty ? null : label,
        completedAt: DateTime.now(),
      );
      await StorageService.instance.addFocusSession(session);
      await _loadSessions();

      if (!mounted) return;
      setState(() => _phase = _TimerPhase.idle);

      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Session complete! 🎉'),
          content: Text(
            '${_workMinutes}min focus session done.\nReady for a ${_breakMinutes}min break?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Skip break'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Start break'),
            ),
          ],
        ),
      ).then((startBreak) {
        if (startBreak == true && mounted) {
          setState(() => _startBreak());
        } else {
          setState(() {
            _phase = _TimerPhase.idle;
            _remaining = _workMinutes * 60;
          });
        }
      });
    } else if (_phase == _TimerPhase.breakPhase) {
      if (!mounted) return;
      setState(() {
        _phase = _TimerPhase.idle;
        _remaining = _workMinutes * 60;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Break over — ready to focus again!')),
      );
    }
  }

  // ── Config bottom sheet ──────────────────────────────────────────────────────

  Future<void> _showConfig() async {
    int work = _workMinutes;
    int brk = _breakMinutes;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Timer Settings',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _DurationStepper(
                label: 'Focus duration',
                value: work,
                min: 5,
                max: 90,
                step: 5,
                onChanged: (v) => setInner(() => work = v),
              ),
              const SizedBox(height: 16),
              _DurationStepper(
                label: 'Break duration',
                value: brk,
                min: 1,
                max: 30,
                step: 1,
                onChanged: (v) => setInner(() => brk = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (_phase == _TimerPhase.idle) {
      setState(() {
        _workMinutes = work;
        _breakMinutes = brk;
        _remaining = work * 60;
      });
    } else {
      setState(() {
        _workMinutes = work;
        _breakMinutes = brk;
      });
    }
  }

  // ── Today stats ──────────────────────────────────────────────────────────────

  int get _todayTotalMinutes {
    final today = DateTime.now();
    return _sessions
        .where((s) =>
            s.completedAt.year == today.year &&
            s.completedAt.month == today.month &&
            s.completedAt.day == today.day)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  int get _todaySessionCount {
    final today = DateTime.now();
    return _sessions
        .where((s) =>
            s.completedAt.year == today.year &&
            s.completedAt.month == today.month &&
            s.completedAt.day == today.day)
        .length;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBreak = _phase == _TimerPhase.breakPhase;
    final accentColor = isBreak ? Colors.teal : scheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer'),
        actions: [
          if (_phase == _TimerPhase.idle)
            IconButton(
              icon: const Icon(Icons.tune_outlined),
              tooltip: 'Settings',
              onPressed: _showConfig,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                if (_phase == _TimerPhase.idle ||
                    _phase == _TimerPhase.workPaused) ...[
                  TextField(
                    controller: _labelCtrl,
                    enabled: _phase == _TimerPhase.idle,
                    decoration: InputDecoration(
                      labelText: 'Session label (optional)',
                      hintText: 'e.g. Deep work, Study, Writing...',
                      prefixIcon: const Icon(Icons.label_outline),
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Center(
                  child: _TimerRing(
                    progress: _progress,
                    remaining: _remaining,
                    phase: _phase,
                    workMinutes: _workMinutes,
                    breakMinutes: _breakMinutes,
                    accentColor: accentColor,
                    pulseCtrl: _pulseCtrl,
                  ),
                ),
                const SizedBox(height: 32),
                _buildControls(scheme),
                const SizedBox(height: 32),
                _TodayStats(
                  totalMinutes: _todayTotalMinutes,
                  sessionCount: _todaySessionCount,
                ),
                const SizedBox(height: 24),
                if (_sessions.isNotEmpty) ...[
                  Text('Recent sessions',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 8),
                  ..._sessions.take(10).map((s) => _SessionTile(session: s)),
                ],
              ],
            ),
    );
  }

  Widget _buildControls(ColorScheme scheme) {
    switch (_phase) {
      case _TimerPhase.idle:
        return Center(
          child: FilledButton.icon(
            onPressed: () => setState(_startWork),
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: const Text('Start Focus', style: TextStyle(fontSize: 16)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        );
      case _TimerPhase.work:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pauseWork,
              icon: const Icon(Icons.pause_rounded),
              label: const Text('Pause'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Stop'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                foregroundColor: scheme.error,
              ),
            ),
          ],
        );
      case _TimerPhase.workPaused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: _resumeWork,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Resume'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Stop'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                foregroundColor: scheme.error,
              ),
            ),
          ],
        );
      case _TimerPhase.breakPhase:
        return Center(
          child: OutlinedButton.icon(
            onPressed: _skipBreak,
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text('Skip break'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timer Ring
// ─────────────────────────────────────────────────────────────────────────────

class _TimerRing extends StatelessWidget {
  final double progress;
  final int remaining;
  final _TimerPhase phase;
  final int workMinutes;
  final int breakMinutes;
  final Color accentColor;
  final AnimationController pulseCtrl;

  const _TimerRing({
    required this.progress,
    required this.remaining,
    required this.phase,
    required this.workMinutes,
    required this.breakMinutes,
    required this.accentColor,
    required this.pulseCtrl,
  });

  String get _timeString {
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _phaseLabel {
    switch (phase) {
      case _TimerPhase.idle: return '$workMinutes min focus';
      case _TimerPhase.work: return 'Focusing...';
      case _TimerPhase.workPaused: return 'Paused';
      case _TimerPhase.breakPhase: return 'Break time ☕';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (context, _) {
        final pulse = phase == _TimerPhase.work || phase == _TimerPhase.breakPhase
            ? 0.5 + pulseCtrl.value * 0.5
            : 1.0;
        return SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  color: accentColor.withValues(alpha: 0.1),
                ),
              ),
              SizedBox.expand(
                child: Transform.rotate(
                  angle: -math.pi / 2,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    color: accentColor.withValues(alpha: pulse),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _timeString,
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w300,
                      color: accentColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _phaseLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today stats bar
// ─────────────────────────────────────────────────────────────────────────────

class _TodayStats extends StatelessWidget {
  final int totalMinutes;
  final int sessionCount;

  const _TodayStats({required this.totalMinutes, required this.sessionCount});

  String _fmt(int m) {
    if (m < 60) return '${m}min';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? '${h}h ${rem}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.timer_outlined,
            value: _fmt(totalMinutes),
            label: "Today's focus",
            color: scheme.primary,
          ),
          Container(width: 1, height: 36, color: scheme.outline.withValues(alpha: 0.3)),
          _StatItem(
            icon: Icons.check_circle_outline,
            value: '$sessionCount',
            label: sessionCount == 1 ? 'session' : 'sessions',
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session tile
// ─────────────────────────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final FocusSession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final isToday = session.completedAt.year == today.year &&
        session.completedAt.month == today.month &&
        session.completedAt.day == today.day;
    final dateStr = isToday
        ? DateFormat('h:mm a').format(session.completedAt)
        : DateFormat('MMM d · h:mm a').format(session.completedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          radius: 20,
          child: Text('${session.durationMinutes}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimaryContainer)),
        ),
        title: Text(session.label ?? 'Focus session',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(dateStr,
            style: TextStyle(
                fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.55))),
        trailing: Text('${session.durationMinutes}min',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: scheme.primary)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Duration stepper
// ─────────────────────────────────────────────────────────────────────────────

class _DurationStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _DurationStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        IconButton.outlined(
          icon: const Icon(Icons.remove),
          onPressed: value > min ? () => onChanged(value - step) : null,
        ),
        SizedBox(
          width: 64,
          child: Text('$value min',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        IconButton.outlined(
          icon: const Icon(Icons.add),
          onPressed: value < max ? () => onChanged(value + step) : null,
        ),
      ],
    );
  }
}
