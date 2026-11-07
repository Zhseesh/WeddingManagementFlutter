import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../wedding_profile/data/wedding_profile_model.dart';
import 'dashboard_data.dart';

class DashboardRepository {
  final DatabaseHelper _dbHelper;

  DashboardRepository(this._dbHelper);

  Future<DashboardData?> getDashboardData(int profileId) async {
    final db = await _dbHelper.database;

    // 1. Profile aktif
    final profileResult = await db.query(
      'wedding_profiles',
      where: 'id = ?',
      whereArgs: [profileId],
      limit: 1,
    );
    if (profileResult.isEmpty) return null;
    final profile = WeddingProfile.fromMap(profileResult.first);

    // 2. Ringkasan keuangan dari view v_financial_summary
    final finResult = await db.query(
      'v_financial_summary',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      limit: 1,
    );
    final totalIncome = finResult.isEmpty
        ? 0
        : (finResult.first['total_income'] as int?) ?? 0;
    final totalExpense = finResult.isEmpty
        ? 0
        : (finResult.first['total_expense'] as int?) ?? 0;

    // 3. Ringkasan budget dari view v_budget_summary
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

    // 4. Progres checklist
    final checklistTotal = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM checklists WHERE profile_id = ?',
          [profileId],
        )) ??
        0;
    final checklistCompleted = Sqflite.firstIntValue(await db.rawQuery(
          "SELECT COUNT(*) FROM checklists WHERE profile_id = ? AND status = 'completed'",
          [profileId],
        )) ??
        0;

    // 5. Countdown hari ke pernikahan
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
      totalExpense: totalExpense,
      totalBudget: totalBudget,
      remainingBudget: remainingBudget,
      checklistTotal: checklistTotal,
      checklistCompleted: checklistCompleted,
      daysToWedding: daysToWedding,
    );
  }
}