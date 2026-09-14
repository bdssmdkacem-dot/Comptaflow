import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/auth_deep_link_service.dart';
import 'core/services/supabase_client.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
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
    runApp(
      StartupErrorApp(
        error: initializationError,
        stackTrace: initializationStackTrace,
      ),
    );
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ComptaFlow',
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 56, color: AppColors.accent),
                      const SizedBox(height: 16),
                      const Text(
                        'ComptaFlow ne peut pas démarrer',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'La connexion Supabase n’a pas pu être initialisée.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SelectableText(error.toString(), textAlign: TextAlign.center),
                      if (stackTrace != null)
                        ExpansionTile(
                          title: const Text('Détails techniques'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: SelectableText(
                                stackTrace.toString(),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthRepository())),
        ChangeNotifierProvider(create: (_) => InvoiceProvider(InvoiceRepository())),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ComptaFlow',
          locale: locale.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.dark(),
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
    if (AuthDeepLinkService.emailConfirmed.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onEmailConfirmed());
    }
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
          content: const Text(
            'تم تأكيد بريدك الإلكتروني بنجاح. مرحباً بك في ComptaFlow.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('متابعة'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) return const LoginScreen();
    if (auth.user?.emailConfirmedAt == null) return const _ConfirmEmailScreen();
    return const _ProfileGate();
  }
}

class _ConfirmEmailScreen extends StatelessWidget {
  const _ConfirmEmailScreen();

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().user?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'أكد بريدك الإلكتروني',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'تم إرسال رابط التأكيد إلى $email. افتح الرسالة واضغط على رابط التأكيد للمتابعة.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.read<AuthProvider>().signOut(),
                  child: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    _future = _ensureProfile();
  }

  Future<bool> _ensureProfile() async {
    final user = SupabaseClientService.client.auth.currentUser;
    if (user == null) return false;

    final row = await SupabaseClientService.client
        .from('profiles')
        .select('user_id')
        .eq('user_id', user.id)
        .maybeSingle();
    if (row != null) return true;

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final requiredKeys = [
      'full_name',
      'company_name',
      'rc',
      'if_number',
      'ice',
      'legal_form',
      'address',
      'city',
      'professional_phone',
    ];
    if (requiredKeys.any(
      (key) => (metadata[key]?.toString().trim() ?? '').isEmpty,
    )) {
      return false;
    }

    await SupabaseClientService.client.from('profiles').insert({
      'user_id': user.id,
      'full_name': metadata['full_name'],
      'company_name': metadata['company_name'],
      'rc': metadata['rc'],
      'if_number': metadata['if_number'],
      'ice': metadata['ice'],
      'legal_form': metadata['legal_form'],
      'address': metadata['address'],
      'city': metadata['city'],
      'professional_phone': metadata['professional_phone'],
      'activity_type': 'services',
      'locale_pref': Localizations.localeOf(context).languageCode,
    });
    return true;
  }

  void _refreshProfile() => setState(() => _future = _ensureProfile());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Impossible de finaliser le profil.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _refreshProfile,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return snapshot.data == true
            ? const DashboardScreen()
            : CompleteProfileScreen(onSaved: _refreshProfile);
      },
    );
  }
}
