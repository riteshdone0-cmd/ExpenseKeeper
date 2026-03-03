import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../services/ai_engine.dart';
import '../services/auth_service.dart';

class FinanceController extends ChangeNotifier {
  FinanceController({AuthService? authService}) : _authService = authService ?? AuthService();

  final AuthService _authService;
  UserProfile? _profile;
  String? _token;
  ThemeMode _themeMode = ThemeMode.system;
  bool _online = true;
  DateTime? _lastSync;
  final List<String> _pendingSyncOps = <String>[];
  final List<ExpenseItem> _expenses = <ExpenseItem>[];

  UserProfile? get profile => _profile;
  bool get isAuthenticated => _profile != null && _token != null;
  ThemeMode get themeMode => _themeMode;
  bool get online => _online;
  DateTime? get lastSync => _lastSync;
  List<String> get pendingSyncOps => List<String>.unmodifiable(_pendingSyncOps);
  List<ExpenseItem> get expenses => List<ExpenseItem>.unmodifiable(_expenses);

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  void setOnline(bool value) {
    _online = value;
    if (_online) {
      syncNow();
    }
    notifyListeners();
  }

  void login(String email, String password) {
    final response = _authService.login(email, password);
    _token = response.token;
    _profile = response.profile;
    _seedExpenses();
    notifyListeners();
  }

  /// Send registration OTP. Returns the generated OTP for demo purposes.
  String sendRegistrationOtp(String email) => _authService.sendOtp(email);

  /// Verify registration OTP.
  bool verifyRegistrationOtp(String email, String otp) => _authService.verifyOtp(email, otp);

  /// Send password-reset OTP. Returns OTP for demo purposes.
  String sendPasswordResetOtp(String email) => _authService.sendOtp(email);

  /// Reset password using OTP. Throws on failure.
  void resetPasswordWithOtp({required String email, required String otp, required String newPassword}) {
    _authService.resetPasswordWithOtp(email: email, otp: otp, newPassword: newPassword);
  }

  void register({
    required String name,
    required String email,
    required String password,
    required double monthlyIncome,
    required double monthlyBudget,
  }) {
    final response = _authService.register(
      name: name,
      email: email,
      password: password,
      monthlyIncome: monthlyIncome,
      monthlyBudget: monthlyBudget,
    );
    _token = response.token;
    _profile = response.profile;
    _expenses.clear();
    notifyListeners();
  }

  void logout() {
    _profile = null;
    _token = null;
    _expenses.clear();
    _pendingSyncOps.clear();
    _lastSync = null;
    notifyListeners();
  }

  void updateProfile({
    String? name,
    double? monthlyIncome,
    double? monthlyBudget,
    bool? hiddenSavingsEnabled,
    double? hiddenSavingsPct,
    List<int>? questionnaire,
  }) {
    final current = _profile;
    if (current == null) {
      return;
    }
    _profile = current.copyWith(
      name: name,
      monthlyIncome: monthlyIncome,
      monthlyBudget: monthlyBudget,
      hiddenSavingsEnabled: hiddenSavingsEnabled,
      hiddenSavingsPct: hiddenSavingsPct,
      questionnaire: questionnaire,
    );
    _queueSync('profile_update');
    notifyListeners();
  }

  void addExpense(ExpenseItem item) {
    _expenses.add(item);
    _queueSync('expense_add');
    notifyListeners();
  }

  void updateExpense(ExpenseItem item) {
    final idx = _expenses.indexWhere((e) => e.id == item.id);
    if (idx == -1) {
      return;
    }
    _expenses[idx] = item;
    _queueSync('expense_update');
    notifyListeners();
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    _queueSync('expense_delete');
    notifyListeners();
  }

  void syncNow() {
    if (!_online) {
      return;
    }
    _pendingSyncOps.clear();
    _lastSync = DateTime.now();
    notifyListeners();
  }

  List<ExpenseItem> monthExpenses([DateTime? date]) {
    final now = date ?? DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get monthSpent => monthExpenses().fold<double>(0, (sum, e) => sum + e.amount);

  double get hiddenSavingsAmount {
    final p = _profile;
    if (p == null || !p.hiddenSavingsEnabled) {
      return 0;
    }
    return p.monthlyIncome * p.hiddenSavingsPct;
  }

  Map<ExpenseCategory, double> get categoryTotals {
    final map = <ExpenseCategory, double>{};
    for (final e in monthExpenses()) {
      map.update(e.category, (value) => value + e.amount, ifAbsent: () => e.amount);
    }
    return map;
  }

  Map<EmotionTag, int> get emotionCounts {
    final map = <EmotionTag, int>{};
    for (final e in monthExpenses()) {
      map.update(e.emotion, (value) => value + 1, ifAbsent: () => 1);
    }
    return map;
  }

  List<RecurringInsight> get recurringExpenses {
    final byTitle = <String, List<ExpenseItem>>{};
    for (final item in _expenses) {
      byTitle.putIfAbsent(item.title.toLowerCase(), () => <ExpenseItem>[]).add(item);
    }

    final recurring = <RecurringInsight>[];
    byTitle.forEach((title, items) {
      if (items.length < 2) {
        return;
      }
      items.sort((a, b) => a.date.compareTo(b.date));
      int monthlyLikeIntervals = 0;
      for (var i = 1; i < items.length; i++) {
        final days = items[i].date.difference(items[i - 1].date).inDays.abs();
        if (days >= 24 && days <= 36) {
          monthlyLikeIntervals += 1;
        }
      }
      final amountAvg = items.fold<double>(0, (sum, e) => sum + e.amount) / items.length;
      if (monthlyLikeIntervals >= 1 || items.length >= 4) {
        recurring.add(
          RecurringInsight(
            title: _toTitle(title),
            averageAmount: amountAvg,
            occurrences: items.length,
            estimatedYearlyImpact: amountAvg * 12,
          ),
        );
      }
    });
    recurring.sort((a, b) => b.estimatedYearlyImpact.compareTo(a.estimatedYearlyImpact));
    return recurring;
  }

  String get financialPersonality {
    final p = _profile;
    if (p == null) {
      return 'Balanced Planner';
    }
    return AiEngine.financialPersonality(p.questionnaire);
  }

  double get burnRatePerDay => AiEngine.burnRatePerDay(monthExpenses(), DateTime.now());

  double get monthForecastSpend => AiEngine.forecastSpendForMonth(monthExpenses(), DateTime.now());

  double get savingsForecast {
    final p = _profile;
    if (p == null) {
      return 0;
    }
    return AiEngine.savingsForecast(
      monthlyIncome: p.monthlyIncome,
      forecastSpend: monthForecastSpend,
      hiddenSavingsAmount: hiddenSavingsAmount,
    );
  }

  List<String> get overspendingAlerts {
    final p = _profile;
    if (p == null) {
      return const <String>[];
    }
    return AiEngine.overspendingAlerts(
      forecastSpend: monthForecastSpend,
      budget: p.monthlyBudget,
      categoryTotals: categoryTotals,
    );
  }

  int get financialHealthScore {
    final p = _profile;
    if (p == null) {
      return 1;
    }
    return AiEngine.healthScore(
      income: p.monthlyIncome,
      spent: monthSpent,
      recurringCount: recurringExpenses.length,
      emotions: emotionCounts,
    );
  }

  double get suggestedBudget {
    final p = _profile;
    if (p == null) {
      return 0;
    }
    return AiEngine.suggestedBudget(income: p.monthlyIncome, currentSpend: monthForecastSpend);
  }

  double get recommendedDailyLimit {
    final p = _profile;
    if (p == null) {
      return 0;
    }
    return AiEngine.recommendedDailyLimit(
      budget: p.monthlyBudget,
      monthSpent: monthSpent,
      now: DateTime.now(),
    );
  }

  Map<DateTime, double> heatmapForCurrentMonth() {
    final map = <DateTime, double>{};
    for (final e in monthExpenses()) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      map.update(key, (value) => value + e.amount, ifAbsent: () => e.amount);
    }
    return map;
  }

  List<double> lastSixMonthSpend() {
    final now = DateTime.now();
    final values = <double>[];
    for (var i = 5; i >= 0; i--) {
      final target = DateTime(now.year, now.month - i, 1);
      final total = _expenses
          .where((e) => e.date.year == target.year && e.date.month == target.month)
          .fold<double>(0, (sum, e) => sum + e.amount);
      values.add(total);
    }
    return values;
  }

  static String toCurrency(double value) => 'Rs ${value.toStringAsFixed(0)}';

  void _queueSync(String op) {
    _pendingSyncOps.add(op);
    if (_online) {
      syncNow();
    }
  }

  void _seedExpenses() {
    if (_expenses.isNotEmpty) {
      return;
    }
    final now = DateTime.now();
    _expenses
      ..clear()
      ..addAll(<ExpenseItem>[
        ExpenseItem(
          id: 'e1',
          title: 'Netflix',
          amount: 649,
          category: ExpenseCategory.subscription,
          emotion: EmotionTag.planned,
          date: DateTime(now.year, now.month - 2, 3),
        ),
        ExpenseItem(
          id: 'e2',
          title: 'Netflix',
          amount: 649,
          category: ExpenseCategory.subscription,
          emotion: EmotionTag.planned,
          date: DateTime(now.year, now.month - 1, 3),
        ),
        ExpenseItem(
          id: 'e3',
          title: 'Netflix',
          amount: 649,
          category: ExpenseCategory.subscription,
          emotion: EmotionTag.planned,
          date: DateTime(now.year, now.month, 3),
        ),
        ExpenseItem(
          id: 'e4',
          title: 'Groceries',
          amount: 2800,
          category: ExpenseCategory.food,
          emotion: EmotionTag.calm,
          date: DateTime(now.year, now.month, 2),
        ),
        ExpenseItem(
          id: 'e5',
          title: 'Cab Ride',
          amount: 350,
          category: ExpenseCategory.transport,
          emotion: EmotionTag.stress,
          date: DateTime(now.year, now.month, 5),
        ),
        ExpenseItem(
          id: 'e6',
          title: 'Shopping Mall',
          amount: 4300,
          category: ExpenseCategory.shopping,
          emotion: EmotionTag.impulsive,
          date: DateTime(now.year, now.month, 8),
        ),
        ExpenseItem(
          id: 'e7',
          title: 'Electricity Bill',
          amount: 2100,
          category: ExpenseCategory.bills,
          emotion: EmotionTag.planned,
          date: DateTime(now.year, now.month, 10),
        ),
        ExpenseItem(
          id: 'e8',
          title: 'Pharmacy',
          amount: 900,
          category: ExpenseCategory.health,
          emotion: EmotionTag.calm,
          date: DateTime(now.year, now.month, 11),
        ),
      ]);
  }

  String _toTitle(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text[0].toUpperCase() + text.substring(1);
  }
}
