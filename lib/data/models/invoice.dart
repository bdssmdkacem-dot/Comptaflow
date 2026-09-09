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
