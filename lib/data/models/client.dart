class ClientModel {
  const ClientModel({
    required this.id,
    required this.userId,
    required this.name,
    this.ice,
    this.phone,
  });

  final String id;
  final String userId;
  final String name;
  final String? ice;
  final String? phone;

  factory ClientModel.fromMap(Map<String, dynamic> map) => ClientModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        ice: map['ice'] as String?,
        phone: map['phone'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'ice': ice,
        'phone': phone,
      };
}
