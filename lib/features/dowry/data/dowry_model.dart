enum DowryStatus {
  notPurchased('not_purchased', 'Belum Dibeli'),
  inProgress('in_progress', 'Sedang Dicari'),
  purchased('purchased', 'Sudah Dibeli'),
  cancelled('cancelled', 'Dibatalkan');

  final String dbValue;
  final String label;
  const DowryStatus(this.dbValue, this.label);

  static DowryStatus fromDb(String v) =>
      values.firstWhere((s) => s.dbValue == v, orElse: () => notPurchased);
}

class DowryModel {
  final int? id;
  final int profileId;
  final String name;
  final String? category;
  final int quantity;
  final int estimatedPrice;
  final int actualPrice;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DowryModel({
    this.id,
    required this.profileId,
    required this.name,
    this.category,
    this.quantity = 1,
    this.estimatedPrice = 0,
    this.actualPrice = 0,
    this.status = 'not_purchased',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  DowryStatus get statusEnum => DowryStatus.fromDb(status);

  Map<String, dynamic> toMap() {
    return {
      'profile_id': profileId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'estimated_price': estimatedPrice,
      'actual_price': actualPrice,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DowryModel.fromMap(Map<String, dynamic> m) {
    return DowryModel(
      id: m['id'] as int?,
      profileId: m['profile_id'] as int,
      name: m['name'] as String,
      category: m['category'] as String?,
      quantity: m['quantity'] as int,
      estimatedPrice: m['estimated_price'] as int,
      actualPrice: m['actual_price'] as int,
      status: m['status'] as String,
      notes: m['notes'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    );
  }
}