class ReminderModel {
  final int? id;
  final int profileId;
  final String title;
  final String? description;
  final DateTime reminderDate;
  final String? referenceType;
  final int? referenceId;
  final bool isEnabled;
  final bool isCompleted;
  final DateTime createdAt;

  const ReminderModel({
    this.id,
    required this.profileId,
    required this.title,
    this.description,
    required this.reminderDate,
    this.referenceType,
    this.referenceId,
    this.isEnabled = true,
    this.isCompleted = false,
    required this.createdAt,
  });

  bool get isPast => reminderDate.isBefore(DateTime.now());

  ReminderModel copyWith({
    String? title,
    String? description,
    DateTime? reminderDate,
    bool? isEnabled,
    bool? isCompleted,
  }) {
    return ReminderModel(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderDate: reminderDate ?? this.reminderDate,
      referenceType: referenceType,
      referenceId: referenceId,
      isEnabled: isEnabled ?? this.isEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profile_id': profileId,
      'title': title,
      'description': description,
      'reminder_date': reminderDate.toIso8601String(),
      'reference_type': referenceType,
      'reference_id': referenceId,
      'is_enabled': isEnabled ? 1 : 0,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> m) {
    return ReminderModel(
      id: m['id'] as int?,
      profileId: m['profile_id'] as int,
      title: m['title'] as String,
      description: m['description'] as String?,
      reminderDate: DateTime.parse(m['reminder_date'] as String),
      referenceType: m['reference_type'] as String?,
      referenceId: m['reference_id'] as int?,
      isEnabled: (m['is_enabled'] as int) == 1,
      isCompleted: (m['is_completed'] as int) == 1,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}