import '../../core/services/supabase_client.dart';
import '../models/product.dart';

class ProductRepository {
  const ProductRepository();

  Future<List<ProductModel>> list({String? search, bool activeOnly = true}) async {
    final userId = SupabaseClientService.client.auth.currentUser?.id;
    if (userId == null) return const [];
    var query = SupabaseClientService.client.from('products').select().eq('user_id', userId);
    if (activeOnly) query = query.eq('active', true);
    final rows = await query.order('name');
    final products = (rows as List)
        .map((row) => ProductModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
    final term = search?.trim().toLowerCase();
    if (term == null || term.isEmpty) return products;
    return products
        .where((p) => p.name.toLowerCase().contains(term) ||
            p.reference?.toLowerCase().contains(term) == true)
        .toList(growable: false);
  }

  Future<ProductModel> create({required String name, required double unitPrice, String? description, String? reference, String type = 'product', String unit = 'unit', double purchasePrice = 0, double taxRate = 0, bool stockManaged = false, double stockQuantity = 0, double minStock = 0}) async {
    final userId = SupabaseClientService.client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');
    _validate(name: name, unitPrice: unitPrice, purchasePrice: purchasePrice, taxRate: taxRate, stockQuantity: stockQuantity, minStock: minStock, type: type, stockManaged: stockManaged);
    final row = await SupabaseClientService.client.from('products').insert({'user_id': userId, 'name': name.trim(), 'description': description, 'reference': reference?.trim().isEmpty == true ? null : reference?.trim(), 'type': type, 'unit': unit, 'unit_price': unitPrice, 'purchase_price': purchasePrice, 'tax_rate': taxRate, 'stock_managed': stockManaged, 'stock_quantity': stockQuantity, 'min_stock': minStock}).select().single();
    return ProductModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<ProductModel> update({required String id, required String name, required double unitPrice, String? description, String? reference, required String type, required String unit, required double purchasePrice, required double taxRate, required bool stockManaged, required double minStock, bool? active}) async {
    _validate(name: name, unitPrice: unitPrice, purchasePrice: purchasePrice, taxRate: taxRate, stockQuantity: 0, minStock: minStock, type: type, stockManaged: stockManaged);
    final current = await SupabaseClientService.client.from('products').select('stock_quantity').eq('id', id).single();
    final currentStock = (current['stock_quantity'] as num?)?.toDouble() ?? 0;
    if (!stockManaged && currentStock != 0) throw StateError('Stock quantity must be zero before disabling stock management');
    final row = await SupabaseClientService.client.from('products').update({'name': name.trim(), 'description': description, 'reference': reference?.trim().isEmpty == true ? null : reference?.trim(), 'type': type, 'unit': unit, 'unit_price': unitPrice, 'purchase_price': purchasePrice, 'tax_rate': taxRate, 'stock_managed': stockManaged, 'min_stock': minStock, if (active != null) 'active': active}).eq('id', id).select().single();
    return ProductModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> archive(String id) async => SupabaseClientService.client.from('products').update({'active': false}).eq('id', id);
  Future<void> delete(String id) async => SupabaseClientService.client.from('products').delete().eq('id', id);

  Future<void> addStock({required String productId, required double quantity, String? note}) async {
    if (quantity <= 0) throw ArgumentError('Quantity must be greater than zero');
    final userId = SupabaseClientService.client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');
    await SupabaseClientService.client.from('stock_movements').insert({'user_id': userId, 'product_id': productId, 'type': 'purchase', 'quantity': quantity, 'note': note});
  }

  Future<void> adjustStock({required String productId, required double quantity, required bool increase, String? note}) async {
    if (quantity <= 0) throw ArgumentError('Quantity must be greater than zero');
    final userId = SupabaseClientService.client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');
    await SupabaseClientService.client.from('stock_movements').insert({'user_id': userId, 'product_id': productId, 'type': increase ? 'adjustment_in' : 'adjustment_out', 'quantity': quantity, 'note': note});
  }

  Future<List<Map<String, dynamic>>> stockMovements(String productId) async {
    final rows = await SupabaseClientService.client.from('stock_movements').select().eq('product_id', productId).order('created_at', ascending: false);
    return (rows as List).map((row) => Map<String, dynamic>.from(row as Map)).toList(growable: false);
  }

  void _validate({required String name, required double unitPrice, required double purchasePrice, required double taxRate, required double stockQuantity, required double minStock, required String type, required bool stockManaged}) {
    if (name.trim().isEmpty) throw ArgumentError('Name is required');
    if (!{'product', 'service'}.contains(type)) throw ArgumentError('Invalid product type');
    if (unitPrice < 0 || purchasePrice < 0) throw ArgumentError('Prices cannot be negative');
    if (taxRate < 0 || taxRate > 100) throw ArgumentError('Tax rate must be between 0 and 100');
    if (stockManaged && stockQuantity < 0) throw ArgumentError('Stock cannot be negative');
    if (minStock < 0) throw ArgumentError('Minimum stock cannot be negative');
  }
}
