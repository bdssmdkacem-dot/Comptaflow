import '../../core/services/supabase_client.dart';
import '../models/product.dart';

class ProductRepository {
  const ProductRepository();

  Future<List<ProductModel>> list() async {
    final userId = SupabaseClientService.client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await SupabaseClientService.client
        .from('products')
        .select()
        .eq('user_id', userId)
        .order('name');
    return (rows as List)
        .map((row) => ProductModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<ProductModel> create({
    required String name,
    required double unitPrice,
    String? description,
    String unit = 'unit',
    double taxRate = 0,
  }) async {
    final userId = SupabaseClientService.client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');
    final row = await SupabaseClientService.client
        .from('products')
        .insert({
          'user_id': userId,
          'name': name,
          'description': description,
          'unit': unit,
          'unit_price': unitPrice,
          'tax_rate': taxRate,
        })
        .select()
        .single();
    return ProductModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> delete(String id) async {
    await SupabaseClientService.client.from('products').delete().eq('id', id);
  }
}
