enum ExpenseCategory {
  food,
  transport,
  shopping,
  bills,
  entertainment,
  health,
  education,
  subscription,
  other,
}

enum EmotionTag { calm, stress, impulsive, planned, regret, happy }

extension ExpenseCategoryX on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.bills:
        return 'Bills';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.subscription:
        return 'Subscription';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}

extension EmotionTagX on EmotionTag {
  String get label {
    switch (this) {
      case EmotionTag.calm:
        return 'Calm';
      case EmotionTag.stress:
        return 'Stress';
      case EmotionTag.impulsive:
        return 'Impulsive';
      case EmotionTag.planned:
        return 'Planned';
      case EmotionTag.regret:
        return 'Regret';
      case EmotionTag.happy:
        return 'Happy';
    }
  }
}

class ExpenseItem {
  const ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.emotion,
    required this.date,
  });

  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final EmotionTag emotion;
  final DateTime date;

  ExpenseItem copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    EmotionTag? emotion,
    DateTime? date,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      emotion: emotion ?? this.emotion,
      date: date ?? this.date,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.monthlyIncome,
    required this.monthlyBudget,
    required this.hiddenSavingsEnabled,
    required this.hiddenSavingsPct,
    required this.questionnaire,
  });

  final String id;
  final String name;
  final String email;
  final double monthlyIncome;
  final double monthlyBudget;
  final bool hiddenSavingsEnabled;
  final double hiddenSavingsPct;
  final List<int> questionnaire;

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    double? monthlyIncome,
    double? monthlyBudget,
    bool? hiddenSavingsEnabled,
    double? hiddenSavingsPct,
    List<int>? questionnaire,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      hiddenSavingsEnabled: hiddenSavingsEnabled ?? this.hiddenSavingsEnabled,
      hiddenSavingsPct: hiddenSavingsPct ?? this.hiddenSavingsPct,
      questionnaire: questionnaire ?? this.questionnaire,
    );
  }
}

class RecurringInsight {
  const RecurringInsight({
    required this.title,
    required this.averageAmount,
    required this.occurrences,
    required this.estimatedYearlyImpact,
  });

  final String title;
  final double averageAmount;
  final int occurrences;
  final double estimatedYearlyImpact;
}
