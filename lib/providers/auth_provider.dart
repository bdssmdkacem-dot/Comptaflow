import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/auth_repo.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) {
    _session = _repository.currentSession;
    _subscription = _repository.authStateChanges.listen(
      (state) {
        _session = state.session;
        _loading = false;
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        _error = error.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthState> _subscription;
  Session? _session;
  bool _loading = false;
  String? _error;

  Session? get session => _session;
  User? get user => _session?.user;
  bool get isAuthenticated => _session != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> sendOtp(String phone) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.sendPhoneOtp(phone);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtp(String phone, String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.verifyPhoneOtp(phone, token);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() => _repository.signOut();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
