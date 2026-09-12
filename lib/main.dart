import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/auth_deep_link_service.dart';
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

  Object? initializationError;
  StackTrace? initializationStackTrace;

  try {
    await SupabaseClientService.initialize();
  } catch (error, stackTrace) {
    initializationError = error;
    initializationStackTrace = stackTrace;
  }

  if (initializationError != null) {
    runApp(StartupErrorApp(error: initializationError, stackTrace: initializationStackTrace));
    return;
  }

  final localeProvider = LocaleProvider();
  try {
    await localeProvider.load();
  } catch (_) {}

  runApp(ComptaflowApp(localeProvider: localeProvider));
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error, this.stackTrace});
  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4A84F);
    const ink = Color(0xFF050505);
    const panel = Color(0xFF101010);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Comptaflow',
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark, surface: panel), scaffoldBackgroundColor: ink),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_outlined, size: 56, color: gold),
                    const SizedBox(height: 16),
                    const Text('Comptaflow ne peut pas démarrer', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    const Text('La connexion Supabase n’a pas pu être initialisée.', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    SelectableText(error.toString(), textAlign: TextAlign.center),
                    if (stackTrace != null) ExpansionTile(title: const Text('Détails techniques'), children: [Padding(padding: const EdgeInsets.all(12), child: SelectableText(stackTrace.toString(), style: const TextStyle(fontSize: 11)))]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ComptaflowApp extends StatelessWidget {
  const ComptaflowApp({super.key, required this.localeProvider});
  final LocaleProvider localeProvider;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4A84F);
    const ink = Color(0xFF050505);
    const panel = Color(0xFF101010);
    const panelElevated = Color(0xFF171717);
    final colorScheme = ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark, surface: panel);

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
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: colorScheme,
            scaffoldBackgroundColor: ink,
            canvasColor: ink,
            cardColor: panel,
            appBarTheme: const AppBarTheme(backgroundColor: ink, foregroundColor: Colors.white, elevation: 0, centerTitle: false),
            navigationBarTheme: NavigationBarThemeData(backgroundColor: panel, indicatorColor: gold.withValues(alpha: 0.22), labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w600))),
            cardTheme: CardThemeData(color: panel, elevation: 0, margin: const EdgeInsets.symmetric(vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withValues(alpha: 0.07)))),
            inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: panelElevated, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: gold, width: 1.4))),
            filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: ink, minimumSize: const Size(48, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
            snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    AuthDeepLinkService.emailConfirmed.addListener(_onEmailConfirmed);
  }

  @override
  void dispose() {
    AuthDeepLinkService.emailConfirmed.removeListener(_onEmailConfirmed);
    super.dispose();
  }

  void _onEmailConfirmed() {
    if (!AuthDeepLinkService.emailConfirmed.value || !mounted) return;
    AuthDeepLinkService.emailConfirmed.value = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.verified_outlined),
          title: const Text('تم تأكيد حسابك'),
          content: const Text('تم تأكيد بريدك الإلكتروني بنجاح. مرحباً بك في ComptaFlow.'),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('متابعة'))],
        ),
      );
    });
  }

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
    final row = await SupabaseClientService.client.from('profiles').select('user_id').eq('user_id', user.id).maybeSingle();
    return row != null;
  }

  void _refreshProfile() => setState(() => _future = _hasProfile());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            const Text('Impossible de vérifier le profil.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('${snapshot.error}', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: _refreshProfile, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
          ])));
        }
        return snapshot.data == true ? const DashboardScreen() : CompleteProfileScreen(onSaved: _refreshProfile);
      },
    );
  }
}
