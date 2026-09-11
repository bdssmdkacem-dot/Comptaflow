import '../../core/services/supabase_client.dart';
import '../models/company_profile.dart';

class CompanyProfileRepository {
  Future<CompanyProfile?> get() async {
    final user = SupabaseClientService.client.auth.currentUser;
    if (user == null) throw StateError('Authentication required');
    final rows = await SupabaseClientService.client
        .from('profiles')
        .select()
        .eq('user_id', user.id)
        .limit(1);
    if (rows.isEmpty) return null;
    return CompanyProfile.fromMap(Map<String, dynamic>.from(rows.first));
  }

  Future<CompanyProfile> save({
    required String fullName,
    String? companyName,
    String? ice,
    String? ifNumber,
    String? rcNumber,
    String? tpNumber,
    String activityType = 'services',
    String? address,
    String? city,
    String? phone,
    String? email,
    String? paymentTerms,
  }) async {
    final user = SupabaseClientService.client.auth.currentUser;
    if (user == null) throw StateError('Authentication required');
    final row = await SupabaseClientService.client.from('profiles').upsert({
      'user_id': user.id,
      'full_name': fullName.trim(),
      'company_name': _clean(companyName),
      'ice': _clean(ice),
      'if_number': _clean(ifNumber),
      'rc_number': _clean(rcNumber),
      'tp_number': _clean(tpNumber),
      'activity_type': activityType.trim().isEmpty ? 'services' : activityType.trim(),
      'company_address': _clean(address),
      'city': _clean(city),
      'phone': _clean(phone),
      'email': _clean(email),
      'payment_terms': _clean(paymentTerms),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id').select().single();
    return CompanyProfile.fromMap(Map<String, dynamic>.from(row));
  }

  String? _clean(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
