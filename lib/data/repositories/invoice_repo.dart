import '../../core/services/supabase_client.dart';
import '../models/invoice.dart';

class InvoiceLineInput {
  const InvoiceLineInput({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  final String description;
  final double quantity;
  final double unitPrice;
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

  Future<InvoiceModel> create({
    required String invoiceNumber,
    String? clientId,
    required DateTime date,
    required List<InvoiceLineInput> items,
    double taxRate = 0,
  }) async {
    final client = SupabaseClientService.client;
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Authentication required');
    if (items.isEmpty) throw ArgumentError('Invoice must contain at least one line');

    final totalHt = items.fold<double>(
      0,
      (sum, item) => sum + item.quantity * item.unitPrice,
    );
    final totalTva = totalHt * taxRate / 100;
    final totalTtc = totalHt + totalTva;

    final row = await client
        .from('invoices')
        .insert({
          'user_id': user.id,
          'client_id': clientId,
          'invoice_number': invoiceNumber.trim(),
          'date': date.toIso8601String().split('T').first,
          'total_ht': totalHt,
          'total_tva': totalTva,
          'total_ttc': totalTtc,
          'status': 'draft',
        })
        .select()
        .single();

    final invoice = InvoiceModel.fromMap(Map<String, dynamic>.from(row));
    try {
      await client.from('invoice_items').insert(
        items
            .map(
              (item) => {
                'invoice_id': invoice.id,
                'description': item.description.trim(),
                'quantity': item.quantity,
                'unit_price': item.unitPrice,
              },
            )
            .toList(),
      );
    } catch (error) {
      await client.from('invoices').delete().eq('id', invoice.id);
      rethrow;
    }
    return invoice;
  }
}
