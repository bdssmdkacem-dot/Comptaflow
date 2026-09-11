import '../../core/services/supabase_client.dart';
import '../models/client.dart';
import '../models/invoice.dart';

class ClientInvoiceStats {
  const ClientInvoiceStats({
    required this.invoiceCount,
    required this.caHt,
    required this.encaisseTtc,
    required this.restantTtc,
  });

  final int invoiceCount;
  final double caHt;
  final double encaisseTtc;
  final double restantTtc;
}

class ClientRepository {
  Future<List<ClientModel>> list({String query = ''}) async {
    final normalized = query.trim();
    var request = SupabaseClientService.client.from('clients').select();
    if (normalized.isNotEmpty) {
      request = request.or('name.ilike.%$normalized%,ice.ilike.%$normalized%,phone.ilike.%$normalized%,email.ilike.%$normalized%,city.ilike.%$normalized%');
    }
    final rows = await request.order('name');
    return (rows as List).map((row) => ClientModel.fromMap(Map<String, dynamic>.from(row))).toList();
  }

  Future<List<InvoiceModel>> invoices(String clientId) async {
    final rows = await SupabaseClientService.client
        .from('invoices')
        .select()
        .eq('client_id', clientId)
        .order('date', ascending: false)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => InvoiceModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<ClientInvoiceStats> stats(String clientId) async {
    final row = await SupabaseClientService.client.rpc(
      'client_invoice_stats',
      params: {'p_client_id': clientId},
    );
    final map = Map<String, dynamic>.from((row as List).single);
    return ClientInvoiceStats(
      invoiceCount: (map['invoice_count'] as num).toInt(),
      caHt: (map['ca_ht'] as num).toDouble(),
      encaisseTtc: (map['encaisse_ttc'] as num).toDouble(),
      restantTtc: (map['restant_ttc'] as num).toDouble(),
    );
  }

  Future<void> create({required String name, String? ice, String? ifNumber, String? rcNumber, String? tpNumber, String? phone, String? email, String? address, String? city}) async {
    final user = _userId;
    await SupabaseClientService.client.from('clients').insert(_payload(user, name, ice, ifNumber, rcNumber, tpNumber, phone, email, address, city));
  }

  Future<void> update({required String id, required String name, String? ice, String? ifNumber, String? rcNumber, String? tpNumber, String? phone, String? email, String? address, String? city}) async {
    _userId;
    await SupabaseClientService.client.from('clients').update({
      'name': name.trim(), 'ice': _clean(ice), 'if_number': _clean(ifNumber), 'rc_number': _clean(rcNumber),
      'tp_number': _clean(tpNumber), 'phone': _clean(phone), 'email': _clean(email), 'address': _clean(address), 'city': _clean(city),
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    _userId;
    final count = await SupabaseClientService.client
        .from('invoices')
        .select('id')
        .eq('client_id', id)
        .count();
    if (count.count > 0) {
      throw StateError('Ce client est lié à ${count.count} facture(s) et ne peut pas être supprimé.');
    }
    await SupabaseClientService.client.from('clients').delete().eq('id', id);
  }

  String get _userId {
    final user = SupabaseClientService.client.auth.currentUser;
    if (user == null) throw StateError('Authentication required');
    return user.id;
  }

  Map<String, dynamic> _payload(String userId, String name, String? ice, String? ifNumber, String? rcNumber, String? tpNumber, String? phone, String? email, String? address, String? city) => {
    'user_id': userId, 'name': name.trim(), 'ice': _clean(ice), 'if_number': _clean(ifNumber), 'rc_number': _clean(rcNumber),
    'tp_number': _clean(tpNumber), 'phone': _clean(phone), 'email': _clean(email), 'address': _clean(address), 'city': _clean(city),
  };

  String? _clean(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
}
