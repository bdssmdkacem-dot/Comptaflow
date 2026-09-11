enum CanonicalInvoiceStatus { draft, issued, paid, cancelled }

class CanonicalInvoiceParty {
  const CanonicalInvoiceParty({
    this.name,
    this.ice,
    this.ifNumber,
    this.rcNumber,
    this.tpNumber,
    this.address,
    this.city,
    this.phone,
    this.email,
  });

  final String? name;
  final String? ice;
  final String? ifNumber;
  final String? rcNumber;
  final String? tpNumber;
  final String? address;
  final String? city;
  final String? phone;
  final String? email;
}

class CanonicalInvoiceLine {
  const CanonicalInvoiceLine({
    required this.description,
    required this.quantity,
    required this.unitPriceHt,
    required this.taxRate,
  });

  final String description;
  final double quantity;
  final double unitPriceHt;
  final double taxRate;

  double get totalHt => quantity * unitPriceHt;
  double get totalTva => totalHt * taxRate / 100;
  double get totalTtc => totalHt + totalTva;
}

class CanonicalInvoice {
  const CanonicalInvoice({
    required this.id,
    required this.userId,
    required this.number,
    required this.issueDate,
    required this.status,
    required this.lines,
    required this.seller,
    this.buyer,
    this.paymentTerms,
  });

  final String id;
  final String userId;
  final String number;
  final DateTime issueDate;
  final CanonicalInvoiceStatus status;
  final List<CanonicalInvoiceLine> lines;
  final CanonicalInvoiceParty seller;
  final CanonicalInvoiceParty? buyer;
  final String? paymentTerms;

  double get totalHt => lines.fold(0, (sum, line) => sum + line.totalHt);
  double get totalTva => lines.fold(0, (sum, line) => sum + line.totalTva);
  double get totalTtc => totalHt + totalTva;
}
