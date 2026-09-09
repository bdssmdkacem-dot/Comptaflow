import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_client.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseClientService.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Future<void> sendPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<void> verifyPhoneOtp(String phone, String token) async {
    await _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: phone,
      token: token,
    );
  }

  Future<void> signInWithPassword(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithPassword(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();
}
