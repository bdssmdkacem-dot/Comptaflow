import '../../core/services/supabase_client.dart';
import '../models/invoice.dart';

class InvoiceRepository {
  Future<List<InvoiceModel>> list() async {
    final rows = await SupabaseClientService.client
        .from('invoices')
        .select()
        .order('date', ascending: false);
    return (rows as List)
        .map((row) => InvoiceModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }
}
