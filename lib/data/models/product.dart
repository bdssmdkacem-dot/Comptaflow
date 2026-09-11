class ProductModel {
  const ProductModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.unitPrice,
    this.description,
    this.reference,
    this.type = 'product',
    this.unit = 'unit',
    this.purchasePrice = 0,
    this.taxRate = 0,
    this.stockManaged = false,
    this.stockQuantity = 0,
    this.minStock = 0,
    this.active = true,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? reference;
  final String type;
  final String unit;
  final double unitPrice;
  final double purchasePrice;
  final double taxRate;
  final bool stockManaged;
  final double stockQuantity;
  final double minStock;
  final bool active;

  bool get isService => type == 'service';
  bool get lowStock => stockManaged && stockQuantity <= minStock;

  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        reference: map['reference'] as String?,
        type: (map['type'] as String?) ?? 'product',
        unit: (map['unit'] as String?) ?? 'unit',
        unitPrice: (map['unit_price'] as num).toDouble(),
        purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0,
        taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
        stockManaged: (map['stock_managed'] as bool?) ?? false,
        stockQuantity: (map['stock_quantity'] as num?)?.toDouble() ?? 0,
        minStock: (map['min_stock'] as num?)?.toDouble() ?? 0,
        active: (map['active'] as bool?) ?? true,
      );

  Map<String, dynamic> toInsertMap(String ownerId) => {
        'user_id': ownerId,
        'name': name,
        'description': description,
        'reference': reference,
        'type': type,
        'unit': unit,
        'unit_price': unitPrice,
        'purchase_price': purchasePrice,
        'tax_rate': taxRate,
        'stock_managed': stockManaged,
        'stock_quantity': stockQuantity,
        'min_stock': minStock,
        'active': active,
      };
}