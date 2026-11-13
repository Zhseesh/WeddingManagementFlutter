class GuestModel {
  final int? id;
  final int profileId;
  final String name;
  final bool isInvited;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GuestModel({
    this.id,
    required this.profileId,
    required this.name,
    this.isInvited = false,
    required this.createdAt,
    required this.updatedAt,
  });

  GuestModel copyWith({
    int? id,
    int? profileId,
    String? name,
    bool? isInvited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GuestModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      isInvited: isInvited ?? this.isInvited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profile_id': profileId,
      'name': name,
      'is_invited': isInvited ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory GuestModel.fromMap(Map<String, dynamic> m) {
    return GuestModel(
      id: m['id'] as int?,
      profileId: m['profile_id'] as int,
      name: m['name'] as String,
      isInvited: (m['is_invited'] as int) == 1,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    );
  }
}