class ProductModel {
  const ProductModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.unitPrice,
    this.description,
    this.unit = 'unit',
    this.taxRate = 0,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final String unit;
  final double unitPrice;
  final double taxRate;

  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        unit: (map['unit'] as String?) ?? 'unit',
        unitPrice: (map['unit_price'] as num).toDouble(),
        taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toInsertMap(String ownerId) => {
        'user_id': ownerId,
        'name': name,
        'description': description,
        'unit': unit,
        'unit_price': unitPrice,
        'tax_rate': taxRate,
      };
}
