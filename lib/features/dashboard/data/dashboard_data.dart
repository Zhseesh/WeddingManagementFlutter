import 'package:weddingmanagementf/features/transactions/data/transaction_model.dart';
import 'package:weddingmanagementf/features/wedding_profile/data/wedding_profile_model.dart';

class DashboardCategory {
  final int? categoryId;
  final String name;
  final int budget;
  final int spent;
  final String? colorHex;
  final String? icon;

  const DashboardCategory({
    this.categoryId,
    required this.name,
    required this.budget,
    required this.spent,
    this.colorHex,
    this.icon,
  });

  double get progress {
    if (budget == 0) return spent > 0 ? 1.0 : 0.0;
    return (spent / budget).clamp(0.0, 1.0);
  }
}

class DashboardData {
  final WeddingProfile profile;
  final int totalIncome;
  final int totalPaid;
  final int totalBudget;
  final int remainingBudget;
  final int daysToWedding;
  final List<DashboardCategory> categories;
  final List<TransactionModel> recentTransactions;

  const DashboardData({
    required this.profile,
    required this.totalIncome,
    required this.totalPaid,
    required this.totalBudget,
    required this.remainingBudget,
    required this.daysToWedding,
    required this.categories,
    required this.recentTransactions,
  });

  double get budgetProgress =>
      totalBudget == 0 ? 0 : (totalPaid / totalBudget).clamp(0.0, 1.0);
  double get budgetPercent => budgetProgress * 100;
}