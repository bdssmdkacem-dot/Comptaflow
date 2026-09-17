import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cpu_declaration.dart';
import '../../core/services/cpu_calculator.dart';

class CpuDeclarationRepository {
  CpuDeclarationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<CpuDeclaration>> list({int limit = 24}) async {
    final rows = await _client
        .from('cpu_declarations')
        .select()
        .order('period', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((row) => CpuDeclaration.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<CpuDeclaration> save({
    required DateTime period,
    required double caEncaisse,
    required double cpuRate,
  }) async {
    if (caEncaisse < 0) throw ArgumentError.value(caEncaisse, 'caEncaisse');
    final amount = CpuCalculator.calculate(caEncaisse: caEncaisse, rate: cpuRate);
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Utilisateur non authentifié');

    final row = await _client
        .from('cpu_declarations')
        .upsert({
          'user_id': userId,
          'period': _dateOnly(period),
          'ca_encaisse': caEncaisse,
          'cpu_rate': cpuRate,
          'cpu_amount': amount,
          'declared_at': null,
        }, onConflict: 'user_id,period')
        .select()
        .single();
    return CpuDeclaration.fromMap(Map<String, dynamic>.from(row));
  }

  Future<CpuDeclaration> markDeclared(String id) async {
    final row = await _client
        .from('cpu_declarations')
        .update({'declared_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .select()
        .single();
    return CpuDeclaration.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> delete(String id) async {
    await _client.from('cpu_declarations').delete().eq('id', id);
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
