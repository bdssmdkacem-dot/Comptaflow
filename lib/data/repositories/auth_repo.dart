import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/auth_deep_link_service.dart';
import '../../core/services/supabase_client.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseClientService.client;

  static const String emailConfirmationRedirect = AuthDeepLinkService.redirectUri;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithPassword(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName == null || fullName.trim().isEmpty
          ? null
          : {'full_name': fullName.trim()},
      emailRedirectTo: emailConfirmationRedirect,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}
