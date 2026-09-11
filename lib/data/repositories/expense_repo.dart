import '../../core/services/supabase_client.dart';
import '../models/expense.dart';

class ExpenseRepository {
  Future<List<ExpenseModel>> list() async {
    final rows = await SupabaseClientService.client
        .from('expenses')
        .select()
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => ExpenseModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<ExpenseModel> create({
    required String supplierName,
    required String description,
    required String category,
    required double amountHt,
    required double taxRate,
    required DateTime date,
    String? notes,
  }) async {
    final user = SupabaseClientService.client.auth.currentUser;
    if (user == null) throw StateError('Authentication required');
    _validate(amountHt, taxRate, supplierName, description);
    final row = await SupabaseClientService.client.from('expenses').insert({
      'user_id': user.id,
      'supplier_name': supplierName.trim(),
      'description': description.trim(),
      'category': category,
      'amount_ht': amountHt,
      'tax_rate': taxRate,
      'expense_date': date.toIso8601String().split('T').first,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    }).select().single();
    return ExpenseModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> update(
    String id, {
    required String supplierName,
    required String description,
    required String category,
    required double amountHt,
    required double taxRate,
    required DateTime date,
    String? notes,
  }) async {
    _validate(amountHt, taxRate, supplierName, description);
    await SupabaseClientService.client.from('expenses').update({
      'supplier_name': supplierName.trim(),
      'description': description.trim(),
      'category': category,
      'amount_ht': amountHt,
      'tax_rate': taxRate,
      'expense_date': date.toIso8601String().split('T').first,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await SupabaseClientService.client.from('expenses').delete().eq('id', id);
  }

  void _validate(double amountHt, double taxRate, String supplier, String description) {
    if (supplier.trim().isEmpty) throw ArgumentError('Supplier is required');
    if (description.trim().isEmpty) throw ArgumentError('Description is required');
    if (amountHt < 0) throw ArgumentError('Amount cannot be negative');
    if (taxRate < 0 || taxRate > 100) throw ArgumentError('Tax rate must be between 0 and 100');
  }
}
