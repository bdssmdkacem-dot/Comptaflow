import '../../core/services/supabase_client.dart';
import '../models/client.dart';

class ClientRepository {
  Future<List<ClientModel>> list() async {
    final rows = await SupabaseClientService.client
        .from('clients')
        .select()
        .order('name');
    return (rows as List)
        .map((row) => ClientModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> create({required String name, String? ice, String? phone}) async {
    final user = SupabaseClientService.client.auth.currentUser;
    if (user == null) throw StateError('Authentication required');
    await SupabaseClientService.client.from('clients').insert({
      'user_id': user.id,
      'name': name,
      'ice': ice,
      'phone': phone,
    });
  }
}
