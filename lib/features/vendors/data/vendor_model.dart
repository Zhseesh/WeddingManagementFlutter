enum VendorStatus {
  notContacted('not_contacted', 'Belum Dihubungi'),
  negotiating('negotiating', 'Negosiasi'),
  booked('booked', 'Dipesan'),
  dpPaid('dp_paid', 'DP Dibayar'),
  paid('paid', 'Lunas'),
  cancelled('cancelled', 'Dibatalkan');

  final String dbValue;
  final String label;
  const VendorStatus(this.dbValue, this.label);

  static VendorStatus fromDb(String v) => values.firstWhere(
        (s) => s.dbValue == v,
        orElse: () => notContacted,
      );
}

class VendorModel {
  final int? id;
  final int profileId;
  final int? categoryId;
  final String name;
  final String? contactName;
  final String? phone;
  final String? address;
  final int agreedPrice;
  final DateTime? bookingDate;
  final DateTime? eventDate;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorModel({
    this.id,
    required this.profileId,
    this.categoryId,
    required this.name,
    this.contactName,
    this.phone,
    this.address,
    required this.agreedPrice,
    this.bookingDate,
    this.eventDate,
    this.status = 'not_contacted',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  VendorStatus get statusEnum => VendorStatus.fromDb(status);

  Map<String, dynamic> toMap() {
    return {
      'profile_id': profileId,
      'category_id': categoryId,
      'name': name,
      'contact_name': contactName,
      'phone': phone,
      'address': address,
      'agreed_price': agreedPrice,
      'booking_date': bookingDate?.toIso8601String().substring(0, 10),
      'event_date': eventDate?.toIso8601String().substring(0, 10),
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory VendorModel.fromMap(Map<String, dynamic> map) {
    return VendorModel(
      id: map['id'] as int?,
      profileId: map['profile_id'] as int,
      categoryId: map['category_id'] as int?,
      name: map['name'] as String,
      contactName: map['contact_name'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      agreedPrice: map['agreed_price'] as int,
      bookingDate: map['booking_date'] != null
          ? DateTime.parse(map['booking_date'] as String)
          : null,
      eventDate: map['event_date'] != null
          ? DateTime.parse(map['event_date'] as String)
          : null,
      status: map['status'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  VendorModel copyWith({
    int? categoryId,
    String? name,
    String? contactName,
    String? phone,
    String? address,
    int? agreedPrice,
    DateTime? bookingDate,
    DateTime? eventDate,
    String? status,
    String? notes,
  }) {
    return VendorModel(
      id: id,
      profileId: profileId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      bookingDate: bookingDate ?? this.bookingDate,
      eventDate: eventDate ?? this.eventDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class VendorWithPayment {
  final VendorModel vendor;
  final int totalPaid;
  final int remaining;

  const VendorWithPayment({
    required this.vendor,
    required this.totalPaid,
    required this.remaining,
  });

  double get progress {
    if (vendor.agreedPrice == 0) return totalPaid > 0 ? 1.0 : 0.0;
    return (totalPaid / vendor.agreedPrice).clamp(0.0, 1.0);
  }

  static VendorWithPayment fromJoinRow(Map<String, dynamic> row) {
    return VendorWithPayment(
      vendor: VendorModel.fromMap(row),
      totalPaid: (row['total_paid'] as int?) ?? 0,
      remaining: (row['remaining'] as int?) ?? 0,
    );
  }
}

class PaymentRecord {
  final int transactionId;
  final int amount;
  final DateTime date;
  final String? method;
  final String? description;
  final String status;

  const PaymentRecord({
    required this.transactionId,
    required this.amount,
    required this.date,
    this.method,
    this.description,
    required this.status,
  });

  bool get isVoid => status == 'void';
}

class VendorDetail {
  final VendorWithPayment summary;
  final List<PaymentRecord> payments;

  const VendorDetail({required this.summary, required this.payments});
}