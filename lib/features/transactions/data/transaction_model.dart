class TransactionModel {
  final int? id;
  final int profileId;
  final int? categoryId;
  final String type; // 'income' | 'expense'
  final int amount;
  final DateTime transactionDate;
  final String? source;
  final String? paymentMethod;
  final String? description;
  final String status; // 'posted' | 'void'
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    this.id,
    required this.profileId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.transactionDate,
    this.source,
    this.paymentMethod,
    this.description,
    this.status = 'posted',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isPosted => status == 'posted';
  bool get isVoid => status == 'void';

  Map<String, dynamic> toMap() {
    return {
      'profile_id': profileId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String().substring(0, 10),
      'source': source,
      'payment_method': paymentMethod,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      profileId: map['profile_id'] as int,
      categoryId: map['category_id'] as int?,
      type: map['type'] as String,
      amount: map['amount'] as int,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      source: map['source'] as String?,
      paymentMethod: map['payment_method'] as String?,
      description: map['description'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}