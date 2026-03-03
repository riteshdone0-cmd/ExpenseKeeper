import 'package:flutter/material.dart';

import '../core/finance_controller.dart';
import '../models/finance_models.dart';
import '../services/ai_engine.dart';
import '../widgets/finance_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller});

  final FinanceController controller;

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile!;
    final remaining = (profile.monthlyBudget - controller.monthSpent).clamp(0, profile.monthlyBudget);
    final progress = (controller.monthSpent / profile.monthlyBudget).clamp(0, 1).toDouble();
    return ModuleScaffold(
      title: 'Dashboard',
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Welcome ${profile.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Remaining Budget: ${FinanceController.toCurrency(remaining.toDouble())}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress),
              ],
            ),
          ),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: InfoCard(
                title: 'Spent',
                value: FinanceController.toCurrency(controller.monthSpent),
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
            Expanded(
              child: InfoCard(
                title: 'Burn Rate',
                value: '${FinanceController.toCurrency(controller.burnRatePerDay)}/day',
                icon: Icons.local_fire_department_rounded,
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: InfoCard(
                title: 'Forecast',
                value: FinanceController.toCurrency(controller.monthForecastSpend),
                icon: Icons.insights_rounded,
              ),
            ),
            Expanded(
              child: InfoCard(
                title: 'Health Score',
                value: '${controller.financialHealthScore}/100',
                icon: Icons.monitor_heart_rounded,
              ),
            ),
          ],
        ),
        Card(
          child: SwitchListTile(
            value: controller.online,
            onChanged: controller.setOnline,
            title: const Text('Cloud Sync'),
            subtitle: Text(controller.online
                ? 'Online. Pending ops: ${controller.pendingSyncOps.length}'
                : 'Offline mode. Queue size: ${controller.pendingSyncOps.length}'),
          ),
        ),
        if (controller.overspendingAlerts.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Overspending Alerts', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...controller.overspendingAlerts.map((a) => Text('- $a')),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, required this.controller});

  final FinanceController controller;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _query = '';
  ExpenseCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final items = widget.controller.monthExpenses().where((e) {
      final q = _query.toLowerCase().trim();
      final qOk = q.isEmpty || e.title.toLowerCase().contains(q) || e.category.label.toLowerCase().contains(q);
      final fOk = _filter == null || e.category == _filter;
      return qOk && fOk;
    }).toList();

    return ModuleScaffold(
      title: 'Expense Module',
      children: <Widget>[
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search expense',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: const Text('All'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            ...ExpenseCategory.values.map((c) => ChoiceChip(
                  label: Text(c.label),
                  selected: _filter == c,
                  onSelected: (_) => setState(() => _filter = c),
                )),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((expense) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Dismissible(
                key: ValueKey(expense.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => widget.controller.deleteExpense(expense.id),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Theme.of(context).cardColor,
                  title: Text(expense.title),
                  subtitle: Text(
                      '${expense.category.label} | Emotion: ${expense.emotion.label} | ${expense.date.day}/${expense.date.month}/${expense.date.year}'),
                  trailing: Text(FinanceController.toCurrency(expense.amount)),
                  onTap: () => _openEditor(context, existing: expense),
                ),
              ),
            )),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, {ExpenseItem? existing}) async {
    final item = await showModalBottomSheet<ExpenseItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ExpenseEditor(existing: existing),
    );
    if (item == null) {
      return;
    }
    if (existing == null) {
      widget.controller.addExpense(item);
    } else {
      widget.controller.updateExpense(item);
    }
  }
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key, required this.controller});

  final FinanceController controller;

  @override
  Widget build(BuildContext context) {
    final monthSeries = controller.lastSixMonthSpend();
    final labels = <String>['-5', '-4', '-3', '-2', '-1', 'Now'];
    final categoryEntries = controller.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final categoryLabels = categoryEntries
        .map((e) => e.key.label.substring(0, e.key.label.length > 3 ? 3 : e.key.label.length))
        .toList();
    final categoryValues = categoryEntries.map((e) => e.value).toList();
    final now = DateTime.now();
    return ModuleScaffold(
      title: 'Analytics Module',
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Spending Heatmap', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                HeatmapCalendar(
                  startDate: DateTime(now.year, now.month, 1),
                  daysInMonth: DateTime(now.year, now.month + 1, 0).day,
                  dailySpend: controller.heatmapForCurrentMonth(),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Category-wise Spend', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                SpendBarChart(
                  labels: categoryLabels.isEmpty ? const <String>['NA'] : categoryLabels,
                  values: categoryValues.isEmpty ? const <double>[0] : categoryValues,
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Monthly Comparison', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                SpendBarChart(labels: labels, values: monthSeries),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AiScreen extends StatelessWidget {
  const AiScreen({super.key, required this.controller});

  final FinanceController controller;

  @override
  Widget build(BuildContext context) {
    final p = controller.profile!;
    final hidden = controller.hiddenSavingsAmount;
    return ModuleScaffold(
      title: 'AI Intelligence',
      children: <Widget>[
        InfoCard(
          title: 'Financial Personality',
          value: controller.financialPersonality,
          subtitle: 'Questionnaire-based behavior profile',
          icon: Icons.psychology_rounded,
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: InfoCard(
                title: 'Burn Rate',
                value: '${FinanceController.toCurrency(controller.burnRatePerDay)}/day',
              ),
            ),
            Expanded(
              child: InfoCard(
                title: 'Savings Forecast',
                value: FinanceController.toCurrency(controller.savingsForecast),
              ),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Forecast Spend: ${FinanceController.toCurrency(controller.monthForecastSpend)}'),
                Text('Monthly Budget: ${FinanceController.toCurrency(p.monthlyBudget)}'),
                Text('Hidden Savings Buffer: ${FinanceController.toCurrency(hidden)}'),
              ],
            ),
          ),
        ),
        if (controller.overspendingAlerts.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('AI Alerts', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...controller.overspendingAlerts.map((e) => Text('- $e')),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key, required this.controller});

  final FinanceController controller;

  @override
  Widget build(BuildContext context) {
    final score = controller.financialHealthScore;
    final grade = score >= 80
        ? 'Excellent'
        : score >= 65
            ? 'Stable'
            : score >= 45
                ? 'At Risk'
                : 'Critical';
    return ModuleScaffold(
      title: 'Financial Health',
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Text('$score / 100', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
                Text(grade),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: score / 100),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...controller.emotionCounts.entries.map((e) {
          return ListTile(
            title: Text('Emotion: ${e.key.label}'),
            trailing: Text('Count ${e.value}'),
          );
        }),
        ListTile(
          title: const Text('Recurring liabilities'),
          trailing: Text('${controller.recurringExpenses.length}'),
        ),
      ],
    );
  }
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key, required this.controller});

  final FinanceController controller;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late final TextEditingController _budgetController;
  double _hiddenPct = 0.1;
  bool _hiddenEnabled = false;

  @override
  void initState() {
    super.initState();
    final p = widget.controller.profile!;
    _budgetController = TextEditingController(text: p.monthlyBudget.toStringAsFixed(0));
    _hiddenPct = p.hiddenSavingsPct <= 0 ? 0.1 : p.hiddenSavingsPct;
    _hiddenEnabled = p.hiddenSavingsEnabled;
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      title: 'Goal & Budget Module',
      children: <Widget>[
        InfoCard(
          title: 'Suggested Budget',
          value: FinanceController.toCurrency(widget.controller.suggestedBudget),
          subtitle: 'AI recommendation from current trend',
          icon: Icons.auto_graph_rounded,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Monthly Budget'),
                const SizedBox(height: 6),
                TextField(
                  controller: _budgetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () {
                    final budget = double.tryParse(_budgetController.text);
                    if (budget == null || budget <= 0) {
                      return;
                    }
                    widget.controller.updateProfile(monthlyBudget: budget);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Monthly budget updated')));
                  },
                  child: const Text('Apply Budget'),
                ),
              ],
            ),
          ),
        ),
        InfoCard(
          title: 'Auto Daily Limit',
          value: FinanceController.toCurrency(widget.controller.recommendedDailyLimit),
          subtitle: 'Dynamic limit based on remaining month budget',
          icon: Icons.today_rounded,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SwitchListTile(
                  value: _hiddenEnabled,
                  onChanged: (v) => setState(() => _hiddenEnabled = v),
                  title: const Text('Hidden Savings Mode'),
                  contentPadding: EdgeInsets.zero,
                ),
                Text('Reserve percentage: ${(_hiddenPct * 100).toStringAsFixed(0)}%'),
                Slider(
                  value: _hiddenPct,
                  min: 0.05,
                  max: 0.30,
                  divisions: 25,
                  onChanged: (v) => setState(() => _hiddenPct = v),
                ),
                FilledButton(
                  onPressed: () {
                    widget.controller.updateProfile(
                      hiddenSavingsEnabled: _hiddenEnabled,
                      hiddenSavingsPct: _hiddenPct,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hidden savings settings saved')),
                    );
                  },
                  child: const Text('Save Hidden Savings'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key, required this.controller});

  final FinanceController controller;

  @override
  Widget build(BuildContext context) {
    final recurring = controller.recurringExpenses;
    return ModuleScaffold(
      title: 'Subscription Tracker',
      children: <Widget>[
        if (recurring.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('No repeating payments detected yet.'),
            ),
          ),
        ...recurring.map((r) {
          return Card(
            child: ListTile(
              title: Text(r.title),
              subtitle: Text(
                'Avg: ${FinanceController.toCurrency(r.averageAmount)} | Yearly impact: ${FinanceController.toCurrency(r.estimatedYearlyImpact)}',
              ),
              trailing: Text('${r.occurrences}x'),
            ),
          );
        }),
        if (recurring.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Optimization Suggestions', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...recurring.take(3).map((r) => Text('- ${r.title}: ${AiEngine.optimizationSuggestion(r)}')),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.controller});

  final FinanceController controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final List<double> _answers;

  @override
  void initState() {
    super.initState();
    final p = widget.controller.profile!;
    _nameController = TextEditingController(text: p.name);
    _answers = p.questionnaire.map((e) => e.toDouble()).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile!;
    return ModuleScaffold(
      title: 'Profile & Questionnaire',
      children: <Widget>[
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 8),
        Text('Email: ${profile.email}'),
        const SizedBox(height: 12),
        const Text('Financial Personality Questions (1-5):'),
        ...List<Widget>.generate(_answers.length, (int i) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 8),
              Text('Q${i + 1}: Spending discipline level'),
              Slider(
                value: _answers[i],
                min: 1,
                max: 5,
                divisions: 4,
                label: _answers[i].round().toString(),
                onChanged: (v) => setState(() => _answers[i] = v),
              ),
            ],
          );
        }),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            widget.controller.updateProfile(
              name: _nameController.text.trim(),
              questionnaire: _answers.map((e) => e.round()).toList(),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile and questionnaire updated')),
            );
          },
          child: const Text('Save Profile'),
        ),
      ],
    );
  }
}

class _ExpenseEditor extends StatefulWidget {
  const _ExpenseEditor({this.existing});

  final ExpenseItem? existing;

  @override
  State<_ExpenseEditor> createState() => _ExpenseEditorState();
}

class _ExpenseEditorState extends State<_ExpenseEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late ExpenseCategory _category;
  late EmotionTag _emotion;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(text: e?.amount.toStringAsFixed(0) ?? '');
    _category = e?.category ?? ExpenseCategory.other;
    _emotion = e?.emotion ?? EmotionTag.planned;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 18),
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ExpenseCategory>(
            initialValue: _category,
            items: ExpenseCategory.values
                .map((c) => DropdownMenuItem<ExpenseCategory>(value: c, child: Text(c.label)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<EmotionTag>(
            initialValue: _emotion,
            items:
                EmotionTag.values.map((e) => DropdownMenuItem<EmotionTag>(value: e, child: Text(e.label))).toList(),
            onChanged: (v) => setState(() => _emotion = v ?? _emotion),
            decoration: const InputDecoration(labelText: 'Emotion Tag'),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Date: ${_date.day}/${_date.month}/${_date.year}'),
            trailing: TextButton(onPressed: _pickDate, child: const Text('Pick')),
          ),
          FilledButton(
            onPressed: () {
              final title = _titleController.text.trim();
              final amount = double.tryParse(_amountController.text.trim());
              if (title.isEmpty || amount == null || amount <= 0) {
                return;
              }
              Navigator.pop(
                context,
                ExpenseItem(
                  id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  amount: amount,
                  category: _category,
                  emotion: _emotion,
                  date: _date,
                ),
              );
            },
            child: Text(widget.existing == null ? 'Add Expense' : 'Update Expense'),
          ),
        ],
      ),
    );
  }
}
