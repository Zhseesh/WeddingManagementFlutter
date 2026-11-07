import '../../wedding_profile/data/wedding_profile_model.dart';

class DashboardData {
  final WeddingProfile profile;
  final int totalIncome;
  final int totalExpense;
  final int totalBudget;
  final int remainingBudget;
  final int checklistTotal;
  final int checklistCompleted;
  final int daysToWedding;

  const DashboardData({
    required this.profile,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBudget,
    required this.remainingBudget,
    required this.checklistTotal,
    required this.checklistCompleted,
    required this.daysToWedding,
  });

  double get checklistProgress =>
      checklistTotal == 0 ? 0 : checklistCompleted / checklistTotal;

  double get budgetUsage => totalBudget == 0
      ? 0
      : (totalExpense / totalBudget).clamp(0.0, 1.0);
}