import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_deep_link_service.dart';

class SupabaseClientService {
  SupabaseClientService._();

  static Future<void> initialize() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

    if (url.isEmpty || publishableKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY. '
        'Run with --dart-define values.',
      );
    }

    await Supabase.initialize(url: url, publishableKey: publishableKey);
    await AuthDeepLinkService.initialize();
  }

  static SupabaseClient get client => Supabase.instance.client;
}
