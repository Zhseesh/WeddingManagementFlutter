enum EngagementStatus {
  pending('pending', 'Pending'),
  inProgress('in_progress', 'Dikerjakan'),
  completed('completed', 'Selesai'),
  cancelled('cancelled', 'Dibatalkan');

  final String dbValue;
  final String label;
  const EngagementStatus(this.dbValue, this.label);

  static EngagementStatus fromDb(String v) =>
      values.firstWhere((s) => s.dbValue == v, orElse: () => pending);
}

class EngagementModel {
  final int? id;
  final int profileId;
  final String name;
  final String? category;
  final int quantity;
  final int estimatedPrice;
  final int actualPrice;
  final String status;
  final DateTime? dueDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EngagementModel({
    this.id,
    required this.profileId,
    required this.name,
    this.category,
    this.quantity = 1,
    this.estimatedPrice = 0,
    this.actualPrice = 0,
    this.status = 'pending',
    this.dueDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  EngagementStatus get statusEnum => EngagementStatus.fromDb(status);

  Map<String, dynamic> toMap() {
    return {
      'profile_id': profileId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'estimated_price': estimatedPrice,
      'actual_price': actualPrice,
      'status': status,
      'due_date': dueDate?.toIso8601String().substring(0, 10),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EngagementModel.fromMap(Map<String, dynamic> m) {
    return EngagementModel(
      id: m['id'] as int?,
      profileId: m['profile_id'] as int,
      name: m['name'] as String,
      category: m['category'] as String?,
      quantity: m['quantity'] as int,
      estimatedPrice: m['estimated_price'] as int,
      actualPrice: m['actual_price'] as int,
      status: m['status'] as String,
      dueDate:
          m['due_date'] != null ? DateTime.parse(m['due_date'] as String) : null,
      notes: m['notes'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    );
  }
}