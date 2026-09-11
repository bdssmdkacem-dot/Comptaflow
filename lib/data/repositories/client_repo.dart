import '../../core/services/supabase_client.dart';
import '../models/client.dart';

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
