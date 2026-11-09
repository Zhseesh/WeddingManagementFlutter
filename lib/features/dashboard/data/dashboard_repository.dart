import 'package:weddingmanagementf/core/database/database_helper.dart';
import 'package:weddingmanagementf/features/dashboard/data/dashboard_data.dart';
import 'package:weddingmanagementf/features/transactions/data/transaction_model.dart';
import 'package:weddingmanagementf/features/wedding_profile/data/wedding_profile_model.dart';

class DashboardRepository {
  final DatabaseHelper _dbHelper;
  DashboardRepository(this._dbHelper);

  Future<DashboardData?> getDashboardData(int profileId) async {
    final db = await _dbHelper.database;

    final profileResult = await db.query(
      'wedding_profiles',
      where: 'id = ?',
      whereArgs: [profileId],
      limit: 1,
    );
    if (profileResult.isEmpty) return null;
    final profile = WeddingProfile.fromMap(profileResult.first);

    final finResult = await db.query(
      'v_financial_summary',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      limit: 1,
    );
    final totalIncome = finResult.isEmpty
        ? 0
        : (finResult.first['total_income'] as int?) ?? 0;
    final totalPaid = finResult.isEmpty
        ? 0
        : (finResult.first['total_expense'] as int?) ?? 0;

    final budgetResult = await db.query(
      'v_budget_summary',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      limit: 1,
    );
    final totalBudget = budgetResult.isEmpty
        ? 0
        : (budgetResult.first['total_amount'] as int?) ?? 0;
    final remainingBudget = budgetResult.isEmpty
        ? 0
        : (budgetResult.first['remaining_budget'] as int?) ?? 0;

    final catsResult = await db.rawQuery(
      '''
      SELECT bc.id, bc.name, bc.allocated_amount, bc.color, bc.icon,
             COALESCE((
               SELECT SUM(t.amount) FROM transactions t
               WHERE t.category_id = bc.id
                 AND t.status = 'posted' AND t.type = 'expense'
             ), 0) AS spent
      FROM budget_categories bc
      WHERE bc.budget_id = (
        SELECT id FROM budgets WHERE profile_id = ? AND is_active = 1 LIMIT 1
      )
      ORDER BY bc.sort_order ASC, bc.id ASC
      ''',
      [profileId],
    );
    final categories = catsResult
        .map((r) => DashboardCategory(
              categoryId: r['id'] as int?,
              name: r['name'] as String,
              budget: (r['allocated_amount'] as int?) ?? 0,
              spent: (r['spent'] as int?) ?? 0,
              colorHex: r['color'] as String?,
              icon: r['icon'] as String?,
            ))
        .toList();

    final recentResult = await db.query(
      'transactions',
      where: 'profile_id = ? AND status = ?',
      whereArgs: [profileId, 'posted'],
      orderBy: 'transaction_date DESC, id DESC',
      limit: 4,
    );
    final recentTransactions =
        recentResult.map(TransactionModel.fromMap).toList();

    int daysToWedding = -1;
    if (profile.weddingDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weddingDay = DateTime(
        profile.weddingDate!.year,
        profile.weddingDate!.month,
        profile.weddingDate!.day,
      );
      daysToWedding = weddingDay.difference(today).inDays;
    }

    return DashboardData(
      profile: profile,
      totalIncome: totalIncome,
      totalPaid: totalPaid,
      totalBudget: totalBudget,
      remainingBudget: remainingBudget,
      daysToWedding: daysToWedding,
      categories: categories,
      recentTransactions: recentTransactions,
    );
  }
}