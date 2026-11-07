class InstallmentModel {
  final int? id;
  final int profileId;
  final int? vendorId;
  final String name;
  final int totalAmount;
  final DateTime? startDate;
  final String? notes;
  final String status; // 'active' | 'completed' | 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentModel({
    this.id,
    required this.profileId,
    this.vendorId,
    required this.name,
    required this.totalAmount,
    this.startDate,
    this.notes,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'profile_id': profileId,
      'vendor_id': vendorId,
      'name': name,
      'total_amount': totalAmount,
      'start_date': startDate?.toIso8601String().substring(0, 10),
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InstallmentModel.fromMap(Map<String, dynamic> map) {
    return InstallmentModel(
      id: map['id'] as int?,
      profileId: map['profile_id'] as int,
      vendorId: map['vendor_id'] as int?,
      name: map['name'] as String,
      totalAmount: map['total_amount'] as int,
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      notes: map['notes'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Lunas';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Aktif';
    }
  }
}

class InstallmentWithSummary {
  final InstallmentModel installment;
  final int totalPaid;
  final int remaining;
  final DateTime? nextDueDate;

  const InstallmentWithSummary({
    required this.installment,
    required this.totalPaid,
    required this.remaining,
    this.nextDueDate,
  });

  double get progress {
    if (installment.totalAmount == 0) {
      return totalPaid > 0 ? 1.0 : 0.0;
    }
    return (totalPaid / installment.totalAmount).clamp(0.0, 1.0);
  }

  static InstallmentWithSummary fromJoinRow(Map<String, dynamic> row) {
    return InstallmentWithSummary(
      installment: InstallmentModel.fromMap(row),
      totalPaid: (row['total_paid'] as int?) ?? 0,
      remaining: (row['remaining'] as int?) ?? 0,
      nextDueDate: row['next_due_date'] != null
          ? DateTime.parse(row['next_due_date'] as String)
          : null,
    );
  }
}

class ScheduleModel {
  final int? id;
  final int installmentId;
  final int sequenceNumber;
  final DateTime dueDate;
  final int amount;
  final String status; // 'pending' | 'partial' | 'paid' | 'overdue'

  const ScheduleModel({
    this.id,
    required this.installmentId,
    required this.sequenceNumber,
    required this.dueDate,
    required this.amount,
    required this.status,
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] as int?,
      installmentId: map['installment_id'] as int,
      sequenceNumber: map['sequence_number'] as int,
      dueDate: DateTime.parse(map['due_date'] as String),
      amount: map['amount'] as int,
      status: map['status'] as String,
    );
  }

  /// Display status mempertimbangkan tanggal jatuh tempo.
  String get displayStatus {
    if (status == 'paid') return 'paid';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (dueDate.isBefore(today)) return 'overdue';
    return status;
  }

  String get displayStatusLabel {
    switch (displayStatus) {
      case 'paid':
        return 'Lunas';
      case 'partial':
        return 'Sebagian';
      case 'overdue':
        return 'Jatuh Tempo';
      default:
        return 'Menunggu';
    }
  }
}

class InstallmentPaymentRecord {
  final int transactionId;
  final int amount;
  final DateTime date;
  final String? method;
  final String? description;
  final String status;

  const InstallmentPaymentRecord({
    required this.transactionId,
    required this.amount,
    required this.date,
    this.method,
    this.description,
    required this.status,
  });

  bool get isVoid => status == 'void';
}

class ScheduleWithPayments {
  final ScheduleModel schedule;
  final int totalPaid;
  final List<InstallmentPaymentRecord> payments;

  const ScheduleWithPayments({
    required this.schedule,
    required this.totalPaid,
    required this.payments,
  });

  int get remaining => (schedule.amount - totalPaid).clamp(0, schedule.amount);

  double get progress {
    if (schedule.amount == 0) return totalPaid > 0 ? 1.0 : 0.0;
    return (totalPaid / schedule.amount).clamp(0.0, 1.0);
  }
}

class InstallmentDetail {
  final InstallmentWithSummary summary;
  final List<ScheduleWithPayments> schedules;

  const InstallmentDetail({
    required this.summary,
    required this.schedules,
  });
}