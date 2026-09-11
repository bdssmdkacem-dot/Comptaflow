import 'canonical_invoice.dart';

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
    this.sellerName,
    this.sellerIce,
    this.sellerIf,
    this.sellerRc,
    this.sellerTp,
    this.sellerAddress,
    this.sellerCity,
    this.sellerPhone,
    this.sellerEmail,
    this.paymentTerms,
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
  final String? sellerName;
  final String? sellerIce;
  final String? sellerIf;
  final String? sellerRc;
  final String? sellerTp;
  final String? sellerAddress;
  final String? sellerCity;
  final String? sellerPhone;
  final String? sellerEmail;
  final String? paymentTerms;

  CanonicalInvoiceStatus get canonicalStatus => switch (status) {
        'draft' => CanonicalInvoiceStatus.draft,
        'issued' => CanonicalInvoiceStatus.issued,
        'paid' => CanonicalInvoiceStatus.paid,
        'cancelled' => CanonicalInvoiceStatus.cancelled,
        _ => CanonicalInvoiceStatus.draft,
      };

  CanonicalInvoice toCanonical({
    required List<CanonicalInvoiceLine> lines,
    CanonicalInvoiceParty? buyer,
  }) {
    return CanonicalInvoice(
      id: id,
      userId: userId,
      number: invoiceNumber,
      issueDate: date,
      status: canonicalStatus,
      lines: List.unmodifiable(lines),
      seller: CanonicalInvoiceParty(
        name: sellerName,
        ice: sellerIce,
        ifNumber: sellerIf,
        rcNumber: sellerRc,
        tpNumber: sellerTp,
        address: sellerAddress,
        city: sellerCity,
        phone: sellerPhone,
        email: sellerEmail,
      ),
      buyer: buyer,
      paymentTerms: paymentTerms,
    );
  }

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
        sellerName: map['seller_name'] as String?,
        sellerIce: map['seller_ice'] as String?,
        sellerIf: map['seller_if'] as String?,
        sellerRc: map['seller_rc'] as String?,
        sellerTp: map['seller_tp'] as String?,
        sellerAddress: map['seller_address'] as String?,
        sellerCity: map['seller_city'] as String?,
        sellerPhone: map['seller_phone'] as String?,
        sellerEmail: map['seller_email'] as String?,
        paymentTerms: map['payment_terms'] as String?,
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

  CanonicalInvoiceLine toCanonical() => CanonicalInvoiceLine(
        description: description,
        quantity: quantity,
        unitPriceHt: unitPrice,
        taxRate: taxRate,
      );

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

  double get totalHt => calculatedHt;
  double get totalTva => calculatedTva;
  double get totalTtc => calculatedTtc;

  CanonicalInvoice toCanonical({CanonicalInvoiceParty? buyer}) => invoice.toCanonical(
        lines: items.map((item) => item.toCanonical()).toList(growable: false),
        buyer: buyer,
      );
}