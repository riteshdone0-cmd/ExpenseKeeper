import '../models/finance_models.dart';

class AiEngine {
  static String financialPersonality(List<int> q) {
    if (q.isEmpty) {
      return 'Balanced Planner';
    }
    final score = q.reduce((a, b) => a + b) / q.length;
    if (score >= 4.2) {
      return 'Growth Builder';
    }
    if (score >= 3.4) {
      return 'Balanced Planner';
    }
    if (score >= 2.6) {
      return 'Reactive Spender';
    }
    return 'High-Risk Impulsive';
  }

  static double burnRatePerDay(List<ExpenseItem> monthExpenses, DateTime now) {
    final spent = monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final elapsed = now.day <= 0 ? 1 : now.day;
    return spent / elapsed;
  }

  static double forecastSpendForMonth(List<ExpenseItem> monthExpenses, DateTime now) {
    final days = DateTime(now.year, now.month + 1, 0).day;
    return burnRatePerDay(monthExpenses, now) * days;
  }

  static double savingsForecast({
    required double monthlyIncome,
    required double forecastSpend,
    required double hiddenSavingsAmount,
  }) {
    return monthlyIncome - forecastSpend - hiddenSavingsAmount;
  }

  static List<String> overspendingAlerts({
    required double forecastSpend,
    required double budget,
    required Map<ExpenseCategory, double> categoryTotals,
  }) {
    final alerts = <String>[];
    if (forecastSpend > budget) {
      alerts.add('Projected spending is above budget by ${_fmt(forecastSpend - budget)}.');
    }
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isNotEmpty && sorted.first.value > budget * 0.35) {
      alerts.add('${sorted.first.key.label} is consuming a large share of your budget.');
    }
    return alerts;
  }

  static int healthScore({
    required double income,
    required double spent,
    required int recurringCount,
    required Map<EmotionTag, int> emotions,
  }) {
    final savingsRatio = income <= 0 ? 0.0 : ((income - spent) / income).clamp(0, 1);
    final impulsiveEvents = (emotions[EmotionTag.impulsive] ?? 0) + (emotions[EmotionTag.regret] ?? 0);
    final emotionalPenalty = (impulsiveEvents * 3).clamp(0, 25);
    final recurringPenalty = (recurringCount * 4).clamp(0, 20);
    final score = (savingsRatio * 70 + 30 - emotionalPenalty - recurringPenalty).round();
    return score.clamp(1, 100);
  }

  static double suggestedBudget({
    required double income,
    required double currentSpend,
  }) {
    final safety = income * 0.55;
    final softCap = currentSpend * 1.03;
    return safety < softCap ? safety : softCap;
  }

  static double recommendedDailyLimit({
    required double budget,
    required double monthSpent,
    required DateTime now,
  }) {
    final daysLeft = (DateTime(now.year, now.month + 1, 0).day - now.day + 1).clamp(1, 31);
    final remaining = (budget - monthSpent).clamp(0, budget);
    return remaining / daysLeft;
  }

  static String optimizationSuggestion(RecurringInsight r) {
    if (r.averageAmount > 999) {
      return 'High yearly impact. Negotiate or downgrade this plan.';
    }
    if (r.occurrences >= 6) {
      return 'Long-running charge. Verify active usage.';
    }
    return 'Track this for two more billing cycles before action.';
  }

  static String _fmt(double value) => 'Rs ${value.toStringAsFixed(0)}';
}
