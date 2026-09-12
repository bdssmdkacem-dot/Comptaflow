import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthDeepLinkService {
  AuthDeepLinkService._();

  static const String redirectUri = 'comptaflow://login-callback/';

  static final ValueNotifier<bool> emailConfirmed = ValueNotifier<bool>(false);
  static StreamSubscription<Uri>? _subscription;

  static Future<void> initialize() async {
    if (kIsWeb) return;

    final appLinks = AppLinks();

    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        await _handle(initialUri);
      }
    } catch (error) {
      debugPrint('Auth deep link initial handling failed: $error');
    }

    await _subscription?.cancel();
    _subscription = appLinks.uriLinkStream.listen(
      (uri) => _handle(uri),
      onError: (Object error) {
        debugPrint('Auth deep link stream failed: $error');
      },
    );
  }

  static Future<void> _handle(Uri uri) async {
    if (uri.scheme != 'comptaflow' || uri.host != 'login-callback') return;

    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      emailConfirmed.value = true;
    } catch (error) {
      debugPrint('Auth confirmation link failed: $error');
    }
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    emailConfirmed.dispose();
  }
}
