import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/supabase_client.dart';
import 'data/repositories/auth_repo.dart';
import 'data/repositories/invoice_repo.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseClientService.initialize();
  final localeProvider = LocaleProvider();
  await localeProvider.load();
  runApp(ComptaflowApp(localeProvider: localeProvider));
}

class ComptaflowApp extends StatelessWidget {
  const ComptaflowApp({super.key, required this.localeProvider});
  final LocaleProvider localeProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthRepository())),
        ChangeNotifierProvider(create: (_) => InvoiceProvider(InvoiceRepository())),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Comptaflow',
          locale: locale.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFB8892E)),
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) return const LoginScreen();
    return const _ProfileGate();
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate();
  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late Future<bool> _future;

  @override
  void initState() {
    super.initState();
    _future = _hasProfile();
  }

  Future<bool> _hasProfile() async {
    final user = SupabaseClientService.client.auth.currentUser;
    if (user == null) return false;
    try {
      final row = await SupabaseClientService.client
          .from('profiles')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();
      return row != null;
    } catch (_) {
      // Until the first database migration is applied, let the user complete
      // the profile rather than exposing a broken dashboard.
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data == true ? const DashboardScreen() : const CompleteProfileScreen();
      },
    );
  }
}
