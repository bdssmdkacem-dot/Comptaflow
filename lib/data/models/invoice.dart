class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.userId,
    required this.invoiceNumber,
    required this.date,
    required this.totalHt,
    required this.totalTva,
    required this.totalTtc,
    required this.status,
    this.clientId,
    this.pdfUrl,
  });

  final String id;
  final String userId;
  final String? clientId;
  final String invoiceNumber;
  final DateTime date;
  final double totalHt;
  final double totalTva;
  final double totalTtc;
  final String status;
  final String? pdfUrl;

  factory InvoiceModel.fromMap(Map<String, dynamic> map) => InvoiceModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        clientId: map['client_id'] as String?,
        invoiceNumber: map['invoice_number'] as String,
        date: DateTime.parse(map['date'] as String),
        totalHt: (map['total_ht'] as num).toDouble(),
        totalTva: (map['total_tva'] as num).toDouble(),
        totalTtc: (map['total_ttc'] as num).toDouble(),
        status: map['status'] as String,
        pdfUrl: map['pdf_url'] as String?,
      );
}

class InvoiceItemModel {
  const InvoiceItemModel({
    required this.id,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
  });

  final String id;
  final String invoiceId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double taxRate;

  double get totalHt => quantity * unitPrice;
  double get totalTva => totalHt * taxRate / 100;
  double get totalTtc => totalHt + totalTva;

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) => InvoiceItemModel(
        id: map['id'] as String,
        invoiceId: map['invoice_id'] as String,
        description: map['description'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unitPrice: (map['unit_price'] as num).toDouble(),
        taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
      );
}

class InvoiceDetails {
  const InvoiceDetails({required this.invoice, required this.items});

  final InvoiceModel invoice;
  final List<InvoiceItemModel> items;

  double get calculatedHt => items.fold(0, (sum, item) => sum + item.totalHt);
  double get calculatedTva => items.fold(0, (sum, item) => sum + item.totalTva);
  double get calculatedTtc => calculatedHt + calculatedTva;
}