class BudgetModel {
  final int? id;
  final int profileId;
  final String name;
  final int totalAmount;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetModel({
    this.id,
    required this.profileId,
    required this.name,
    required this.totalAmount,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as int?,
      profileId: map['profile_id'] as int,
      name: map['name'] as String,
      totalAmount: map['total_amount'] as int,
      isActive: (map['is_active'] as int) == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class BudgetCategoryModel {
  final int? id;
  final int budgetId;
  final String name;
  final int allocatedAmount;
  final String? icon;
  final String? color;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetCategoryModel({
    this.id,
    required this.budgetId,
    required this.name,
    required this.allocatedAmount,
    this.icon,
    this.color,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BudgetCategoryModel.fromMap(Map<String, dynamic> map) {
    return BudgetCategoryModel(
      id: map['id'] as int?,
      budgetId: map['budget_id'] as int,
      name: map['name'] as String,
      allocatedAmount: map['allocated_amount'] as int,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class BudgetSummary {
  final int totalBudget;
  final int totalExpense;
  final int remaining;

  const BudgetSummary({
    required this.totalBudget,
    required this.totalExpense,
    required this.remaining,
  });

  double get usagePercent =>
      totalBudget == 0 ? 0 : (totalExpense / totalBudget).clamp(0.0, 1.0);
}

class CategorySpending {
  final BudgetCategoryModel category;
  final int spent;

  const CategorySpending({required this.category, required this.spent});

  int get remaining => category.allocatedAmount - spent;
  double get progress {
    if (category.allocatedAmount == 0) {
      return spent > 0 ? 1.0 : 0.0;
    }
    return (spent / category.allocatedAmount).clamp(0.0, 1.0);
  }
}