enum ChecklistPriority {
  low('low', 'Rendah'),
  medium('medium', 'Sedang'),
  high('high', 'Tinggi');

  final String dbValue;
  final String label;
  const ChecklistPriority(this.dbValue, this.label);

  static ChecklistPriority fromDb(String v) =>
      values.firstWhere((p) => p.dbValue == v, orElse: () => medium);
}

enum ChecklistStatus {
  pending('pending', 'Pending'),
  inProgress('in_progress', 'Dikerjakan'),
  completed('completed', 'Selesai');

  final String dbValue;
  final String label;
  const ChecklistStatus(this.dbValue, this.label);

  static ChecklistStatus fromDb(String v) =>
      values.firstWhere((s) => s.dbValue == v, orElse: () => pending);
}

class ChecklistModel {
  final int? id;
  final int profileId;
  final String title;
  final String? category;
  final String? description;
  final String priority;
  final DateTime? dueDate;
  final String status;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChecklistModel({
    this.id,
    required this.profileId,
    required this.title,
    this.category,
    this.description,
    this.priority = 'medium',
    this.dueDate,
    this.status = 'pending',
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  ChecklistPriority get priorityEnum => ChecklistPriority.fromDb(priority);
  ChecklistStatus get statusEnum => ChecklistStatus.fromDb(status);
  bool get isCompleted => status == 'completed';

  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(today);
  }

  Map<String, dynamic> toMap() {
    return {
      'profile_id': profileId,
      'title': title,
      'category': category,
      'description': description,
      'priority': priority,
      'due_date': dueDate?.toIso8601String().substring(0, 10),
      'status': status,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ChecklistModel.fromMap(Map<String, dynamic> m) {
    return ChecklistModel(
      id: m['id'] as int?,
      profileId: m['profile_id'] as int,
      title: m['title'] as String,
      category: m['category'] as String?,
      description: m['description'] as String?,
      priority: m['priority'] as String,
      dueDate:
          m['due_date'] != null ? DateTime.parse(m['due_date'] as String) : null,
      status: m['status'] as String,
      isDefault: (m['is_default'] as int) == 1,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    );
  }
}