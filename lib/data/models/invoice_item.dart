class InvoiceItemModel {
  const InvoiceItemModel({
    required this.id,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final String invoiceId;
  final String description;
  final double quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) => InvoiceItemModel(
        id: map['id'] as String,
        invoiceId: map['invoice_id'] as String,
        description: map['description'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unitPrice: (map['unit_price'] as num).toDouble(),
      );
}
