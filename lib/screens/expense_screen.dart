import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../services/storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Expense Screen
// ─────────────────────────────────────────────────────────────────────────────

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  List<Expense> _expenses = [];
  List<Budget> _budgets = [];
  bool _loading = true;
  String? _filterCategory;

  static final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _monthFmt = DateFormat('MMMM yyyy');
  static final _dayFmt = DateFormat('EEE, MMM d');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await StorageService.instance.loadExpenses();
    setState(() {
      _expenses = data.expenses;
      _budgets = data.budgets;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await StorageService.instance.saveExpenses(_expenses, _budgets);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<Expense> get _thisMonthExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
  }

  double _spentForCategory(String cat, [List<Expense>? source]) {
    final list = source ?? _thisMonthExpenses;
    return list.where((e) => e.category == cat).fold(0.0, (s, e) => s + e.amount);
  }

  double get _totalBudget =>
      _budgets.fold(0.0, (s, b) => s + b.monthlyLimit);

  double get _totalSpentThisMonth =>
      _thisMonthExpenses.fold(0.0, (s, e) => s + e.amount);

  Budget? _budgetFor(String cat) {
    try {
      return _budgets.firstWhere((b) => b.category == cat);
    } catch (_) {
      return null;
    }
  }

  // Grouped by day, sorted newest first
  List<MapEntry<String, List<Expense>>> _groupedExpenses() {
    final source = _filterCategory == null
        ? _thisMonthExpenses
        : _thisMonthExpenses.where((e) => e.category == _filterCategory).toList();
    source.sort((a, b) => b.date.compareTo(a.date));

    final map = <String, List<Expense>>{};
    for (final e in source) {
      final k = DateFormat('yyyy-MM-dd').format(e.date);
      map.putIfAbsent(k, () => []).add(e);
    }
    return map.entries.toList();
  }

  // ── Add expense ─────────────────────────────────────────────────────────────

  Future<void> _showAddSheet() async {
    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddExpenseSheet(),
    );
    if (result == null) return;
    _expenses.add(result);
    setState(() {});
    await _save();
  }

  Future<void> _deleteExpense(Expense e) async {
    _expenses.removeWhere((x) => x.id == e.id);
    setState(() {});
    await _save();
  }

  // ── Budget management ────────────────────────────────────────────────────────

  Future<void> _showBudgetsDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => _BudgetDialog(
        budgets: _budgets,
        onSave: (updated) async {
          setState(() => _budgets = updated);
          await _save();
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Manage budgets',
            onPressed: _showBudgetsDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expense_fab',
        onPressed: _showAddSheet,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildSummaryCard(scheme)),
                SliverToBoxAdapter(child: _buildCategoryChips()),
                ..._buildExpenseList(scheme),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(ColorScheme scheme) {
    final spent = _totalSpentThisMonth;
    final budget = _totalBudget;
    final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final over = budget > 0 && spent > budget;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        color: scheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_monthFmt.format(DateTime.now()),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer)),
                  Text(_currencyFmt.format(spent),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: over ? scheme.error : scheme.onPrimaryContainer)),
                ],
              ),
              if (budget > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: ratio,
                  color: over ? scheme.error : scheme.primary,
                  backgroundColor: scheme.onPrimaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
                const SizedBox(height: 4),
                Text(
                  over
                      ? 'Over budget by ${_currencyFmt.format(spent - budget)}'
                      : '${_currencyFmt.format(budget - spent)} remaining of ${_currencyFmt.format(budget)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.8)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: kExpenseCategories.map((cat) {
          final spent = _spentForCategory(cat);
          final budget = _budgetFor(cat);
          final selected = _filterCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(budget != null && budget.monthlyLimit > 0
                  ? '$cat · ${_currencyFmt.format(spent)}/${_currencyFmt.format(budget.monthlyLimit)}'
                  : '$cat · ${_currencyFmt.format(spent)}'),
              selected: selected,
              onSelected: (v) =>
                  setState(() => _filterCategory = v ? cat : null),
              selectedColor: Colors.indigo.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildExpenseList(ColorScheme scheme) {
    final groups = _groupedExpenses();
    if (groups.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64,
                      color: scheme.outline.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    _filterCategory != null
                        ? 'No "$_filterCategory" expenses this month'
                        : 'No expenses this month',
                    style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return groups.map((entry) {
      final dayDate = DateFormat('yyyy-MM-dd').parse(entry.key);
      final dayTotal = entry.value.fold(0.0, (s, e) => s + e.amount);

      return SliverMainAxisGroup(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_dayFmt.format(dayDate),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6))),
                Text(_currencyFmt.format(dayTotal),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final exp = entry.value[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Slidable(
                  key: ValueKey(exp.id),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => _deleteExpense(exp),
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Colors.indigo.withValues(alpha: 0.1),
                        child: Icon(
                            kCategoryIcons[exp.category] ??
                                Icons.category_outlined,
                            color: Colors.indigo,
                            size: 20),
                      ),
                      title: Text(
                          exp.note.isNotEmpty ? exp.note : exp.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: exp.note.isNotEmpty
                          ? Text(exp.category,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall)
                          : null,
                      trailing: Text(
                        _currencyFmt.format(exp.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.error,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: entry.value.length,
          ),
        ),
      ]);
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add expense bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddExpenseSheet extends StatefulWidget {
  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _category;
  DateTime _date = DateTime.now();

  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0 || _category == null) return;
    Navigator.pop(
      context,
      Expense(
        id: const Uuid().v4(),
        amount: amount,
        category: _category!,
        note: _noteCtrl.text.trim(),
        date: _date,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _amountCtrl.text.trim().isNotEmpty && _category != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Expense',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Amount', prefixText: '\$ '),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Category chips
            Text('Category',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: kExpenseCategories.map((cat) {
                return ChoiceChip(
                  label: Text(cat),
                  selected: _category == cat,
                  onSelected: (v) =>
                      setState(() => _category = v ? cat : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Note
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                  labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 12),

            // Date
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _pickDate,
                  child: Text(_dateFmt.format(_date)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canSubmit ? _submit : null,
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget management dialog
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetDialog extends StatefulWidget {
  final List<Budget> budgets;
  final Future<void> Function(List<Budget>) onSave;

  const _BudgetDialog({required this.budgets, required this.onSave});

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final cat in kExpenseCategories)
        cat: TextEditingController(
          text: () {
            try {
              final b = widget.budgets.firstWhere((b) => b.category == cat);
              return b.monthlyLimit > 0 ? b.monthlyLimit.toStringAsFixed(2) : '';
            } catch (_) {
              return '';
            }
          }(),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = kExpenseCategories.map((cat) {
      final val = double.tryParse(_controllers[cat]!.text.trim()) ?? 0.0;
      return Budget(category: cat, monthlyLimit: val);
    }).toList();
    await widget.onSave(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Monthly Budgets'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: kExpenseCategories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _controllers[cat],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: cat,
                  prefixText: '\$ ',
                  hintText: '0.00',
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
