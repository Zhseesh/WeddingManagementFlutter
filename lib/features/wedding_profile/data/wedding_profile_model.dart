class WeddingProfile {
  final int? id;
  final String partnerOne;
  final String partnerTwo;
  final DateTime? weddingDate;
  final DateTime? engagementDate;
  final String? weddingLocation;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WeddingProfile({
    this.id,
    required this.partnerOne,
    required this.partnerTwo,
    this.weddingDate,
    this.engagementDate,
    this.weddingLocation,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'partner_one': partnerOne,
      'partner_two': partnerTwo,
      'wedding_date': weddingDate != null
          ? weddingDate!.toIso8601String().substring(0, 10)
          : null,
      'engagement_date': engagementDate != null
          ? engagementDate!.toIso8601String().substring(0, 10)
          : null,
      'wedding_location': weddingLocation,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WeddingProfile.fromMap(Map<String, dynamic> map) {
    return WeddingProfile(
      id: map['id'] as int?,
      partnerOne: map['partner_one'] as String,
      partnerTwo: map['partner_two'] as String,
      weddingDate: map['wedding_date'] != null
          ? DateTime.parse(map['wedding_date'] as String)
          : null,
      engagementDate: map['engagement_date'] != null
          ? DateTime.parse(map['engagement_date'] as String)
          : null,
      weddingLocation: map['wedding_location'] as String?,
      notes: map['notes'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}