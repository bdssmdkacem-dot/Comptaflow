class ClientModel {
  const ClientModel({required this.id, required this.userId, required this.name, this.ice, this.ifNumber, this.rcNumber, this.tpNumber, this.phone, this.email, this.address, this.city, this.createdAt, this.updatedAt});

  final String id;
  final String userId;
  final String name;
  final String? ice;
  final String? ifNumber;
  final String? rcNumber;
  final String? tpNumber;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ClientModel.fromMap(Map<String, dynamic> map) => ClientModel(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    name: map['name'] as String,
    ice: map['ice'] as String?,
    ifNumber: map['if_number'] as String?,
    rcNumber: map['rc_number'] as String?,
    tpNumber: map['tp_number'] as String?,
    phone: map['phone'] as String?,
    email: map['email'] as String?,
    address: map['address'] as String?,
    city: map['city'] as String?,
    createdAt: _date(map['created_at']),
    updatedAt: _date(map['updated_at']),
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'user_id': userId, 'name': name, 'ice': ice, 'if_number': ifNumber,
    'rc_number': rcNumber, 'tp_number': tpNumber, 'phone': phone, 'email': email,
    'address': address, 'city': city, 'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  static DateTime? _date(dynamic value) => value is String ? DateTime.tryParse(value) : value is DateTime ? value : null;
}
