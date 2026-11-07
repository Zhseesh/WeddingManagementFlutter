import 'package:weddingmanagementf/features/transactions/data/transaction_model.dart';

class ReportPeriod {
  final DateTime start;
  final DateTime end;

  const ReportPeriod({required this.start, required this.end});

  static ReportPeriod thisMonth() {
    final now = DateTime.now();
    return ReportPeriod(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  static ReportPeriod last3Months() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final start = DateTime(now.year, now.month - 2, 1);
    return ReportPeriod(start: start, end: end);
  }

  static ReportPeriod thisYear() {
    final now = DateTime.now();
    return ReportPeriod(
      start: DateTime(now.year, 1, 1),
      end: DateTime(now.year, 12, 31, 23, 59, 59),
    );
  }

  String get startIso =>
      '${start.year.toString().padLeft(4, '0')}-'
      '${start.month.toString().padLeft(2, '0')}-'
      '${start.day.toString().padLeft(2, '0')}';

  String get endIso =>
      '${end.year.toString().padLeft(4, '0')}-'
      '${end.month.toString().padLeft(2, '0')}-'
      '${end.day.toString().padLeft(2, '0')}';
}

class ReportFilter {
  final ReportPeriod period;
  final int? categoryId;
  final String? type; // null | 'income' | 'expense'

  const ReportFilter({
    required this.period,
    this.categoryId,
    this.type,
  });

  ReportFilter withPeriod(ReportPeriod p) =>
      ReportFilter(period: p, categoryId: categoryId, type: type);

  ReportFilter withCategory(int? c) =>
      ReportFilter(period: period, categoryId: c, type: type);

  ReportFilter withType(String? t) =>
      ReportFilter(period: period, categoryId: categoryId, type: t);
}

class CategoryBreakdown {
  final int? categoryId;
  final String name;
  final int total;
  final int transactionCount;

  const CategoryBreakdown({
    required this.categoryId,
    required this.name,
    required this.total,
    required this.transactionCount,
  });
}

class VendorBreakdown {
  final int vendorId;
  final String name;
  final int agreedPrice;
  final int paid;
  final int remaining;

  const VendorBreakdown({
    required this.vendorId,
    required this.name,
    required this.agreedPrice,
    required this.paid,
    required this.remaining,
  });
}

class InstallmentBreakdown {
  final int id;
  final String name;
  final int totalAmount;
  final int paid;
  final int remaining;

  const InstallmentBreakdown({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.paid,
    required this.remaining,
  });
}

class ReportData {
  final ReportFilter filter;
  final int totalIncome;
  final int totalExpense;
  final int totalBudget;
  final List<CategoryBreakdown> categories;
  final List<VendorBreakdown> vendors;
  final List<InstallmentBreakdown> installments;
  final List<TransactionModel> transactions;

  const ReportData({
    required this.filter,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBudget,
    required this.categories,
    required this.vendors,
    required this.installments,
    required this.transactions,
  });

  int get netBalance => totalIncome - totalExpense;
  int get remainingBudget => totalBudget - totalExpense;
  double get budgetUsage => totalBudget == 0
      ? 0
      : (totalExpense / totalBudget).clamp(0.0, 1.0);
}