import '../../core/services/supabase_client.dart';
import '../models/invoice.dart';

class InvoiceLineInput {
  const InvoiceLineInput({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.taxRate = 0,
  });

  final String description;
  final double quantity;
  final double unitPrice;
  final double taxRate;

  double get totalHt => quantity * unitPrice;
  double get totalTva => totalHt * taxRate / 100;
  double get totalTtc => totalHt + totalTva;
}

class InvoiceRepository {
  Future<List<InvoiceModel>> list() async {
    final rows = await SupabaseClientService.client
        .from('invoices')
        .select()
        .order('date', ascending: false)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => InvoiceModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<InvoiceDetails> getDetails(String invoiceId) async {
    final client = SupabaseClientService.client;
    final invoiceRow = await client.from('invoices').select().eq('id', invoiceId).single();
    final itemRows = await client
        .from('invoice_items')
        .select()
        .eq('invoice_id', invoiceId)
        .order('created_at');
    return InvoiceDetails(
      invoice: InvoiceModel.fromMap(Map<String, dynamic>.from(invoiceRow)),
      items: (itemRows as List)
          .map((row) => InvoiceItemModel.fromMap(Map<String, dynamic>.from(row)))
          .toList(),
    );
  }

  Future<String> nextInvoiceNumber() async {
    final result = await SupabaseClientService.client.rpc('next_invoice_number');
    return result as String;
  }

  Future<InvoiceModel> create({
    String? invoiceNumber,
    String? clientId,
    required DateTime date,
    required List<InvoiceLineInput> items,
  }) async {
    final client = SupabaseClientService.client;
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Authentication required');
    if (items.isEmpty) throw ArgumentError('Invoice must contain at least one line');
    _validate(items);

    final number = invoiceNumber?.trim().isNotEmpty == true
        ? invoiceNumber!.trim()
        : await nextInvoiceNumber();
    final totalHt = items.fold<double>(0, (sum, item) => sum + item.totalHt);
    final totalTva = items.fold<double>(0, (sum, item) => sum + item.totalTva);
    final totalTtc = totalHt + totalTva;

    final row = await client.from('invoices').insert({
      'user_id': user.id,
      'client_id': clientId,
      'invoice_number': number,
      'date': date.toIso8601String().split('T').first,
      'total_ht': totalHt,
      'total_tva': totalTva,
      'total_ttc': totalTtc,
      'status': 'draft',
    }).select().single();

    final invoice = InvoiceModel.fromMap(Map<String, dynamic>.from(row));
    try {
      await client.from('invoice_items').insert(
        items.map((item) => {
          'invoice_id': invoice.id,
          'description': item.description.trim(),
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'tax_rate': item.taxRate,
        }).toList(),
      );
    } catch (error) {
      await client.from('invoices').delete().eq('id', invoice.id);
      rethrow;
    }
    return invoice;
  }

  Future<void> updateDraft(
    String invoiceId, {
    required String invoiceNumber,
    String? clientId,
    required DateTime date,
    required List<InvoiceLineInput> items,
  }) async {
    if (items.isEmpty) throw ArgumentError('Invoice must contain at least one line');
    _validate(items);
    final client = SupabaseClientService.client;
    final details = await getDetails(invoiceId);
    if (details.invoice.status != 'draft') {
      throw StateError('Only draft invoices can be edited');
    }

    final totalHt = items.fold<double>(0, (sum, item) => sum + item.totalHt);
    final totalTva = items.fold<double>(0, (sum, item) => sum + item.totalTva);
    final totalTtc = totalHt + totalTva;

    await client.from('invoices').update({
      'invoice_number': invoiceNumber.trim(),
      'client_id': clientId,
      'date': date.toIso8601String().split('T').first,
      'total_ht': totalHt,
      'total_tva': totalTva,
      'total_ttc': totalTtc,
    }).eq('id', invoiceId);

    await client.from('invoice_items').delete().eq('invoice_id', invoiceId);
    await client.from('invoice_items').insert(
      items.map((item) => {
        'invoice_id': invoiceId,
        'description': item.description.trim(),
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'tax_rate': item.taxRate,
      }).toList(),
    );
  }

  Future<void> delete(String invoiceId) async {
    final details = await getDetails(invoiceId);
    if (details.invoice.status != 'draft') {
      throw StateError('Only draft invoices can be deleted');
    }
    await SupabaseClientService.client.from('invoices').delete().eq('id', invoiceId);
  }

  Future<void> updateStatus(String invoiceId, String status) async {
    const allowed = {'draft', 'issued', 'paid', 'cancelled'};
    if (!allowed.contains(status)) throw ArgumentError('Invalid invoice status');

    final current = (await SupabaseClientService.client
            .from('invoices')
            .select('status')
            .eq('id', invoiceId)
            .single())['status'] as String;

    final validTransition = switch (current) {
      'draft' => status == 'issued' || status == 'cancelled',
      'issued' => status == 'paid' || status == 'cancelled',
      'paid' => false,
      'cancelled' => false,
      _ => false,
    };
    if (!validTransition) {
      throw StateError('Invalid invoice status transition: $current -> $status');
    }

    await SupabaseClientService.client
        .from('invoices')
        .update({'status': status})
        .eq('id', invoiceId);
  }

  void _validate(List<InvoiceLineInput> items) {
    for (final item in items) {
      if (item.description.trim().isEmpty) throw ArgumentError('Description is required');
      if (item.quantity <= 0) throw ArgumentError('Quantity must be greater than zero');
      if (item.unitPrice < 0) throw ArgumentError('Unit price cannot be negative');
      if (item.taxRate < 0 || item.taxRate > 100) throw ArgumentError('Tax rate must be between 0 and 100');
    }
  }
}
