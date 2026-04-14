import 'package:flutter/material.dart';

import 'expense_screen.dart';
import 'focus_timer_screen.dart';
import 'habits_screen.dart';
import 'health_screen.dart';
import 'journal_screen.dart';
import 'review_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ModuleCard(
          icon: Icons.watch_outlined,
          title: 'Health',
          subtitle: 'Steps, heart rate, sleep & more from your Band 10',
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HealthScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _ModuleCard(
          icon: Icons.repeat_rounded,
          title: 'Habit Tracker',
          subtitle: 'Build streaks, track daily & weekly habits',
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HabitsScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _ModuleCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Expense Log',
          subtitle: 'Log spending and track monthly budgets',
          color: Colors.indigo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExpenseScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _ModuleCard(
          icon: Icons.menu_book_outlined,
          title: 'Daily Journal',
          subtitle: 'Mood check-in and daily reflection',
          color: Colors.deepPurple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _ModuleCard(
          icon: Icons.timer_outlined,
          title: 'Focus Timer',
          subtitle: 'Pomodoro sessions with automatic logging',
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FocusTimerScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _ModuleCard(
          icon: Icons.bar_chart_rounded,
          title: 'Weekly & Monthly Review',
          subtitle: 'Habits, mood, spend, and focus at a glance',
          color: Colors.blueGrey,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReviewScreen()),
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                radius: 28,
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
