import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import 'complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUpMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showCompanyStep = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _email.text.trim();
    final password = _password.text;

    try {
      final auth = context.read<AuthProvider>();
      if (_signUpMode) {
        if (!_showCompanyStep) {
          setState(() => _showCompanyStep = true);
          return;
        }
        await auth.signUp(email: email, password: password, fullName: _name.text.trim());
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Vérifiez votre e-mail'),
            content: Text('Un message de confirmation a été envoyé à $email. Ouvrez-le et appuyez sur le bouton de confirmation pour revenir dans ComptaFlow.'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
          ),
        );
      } else {
        await auth.signIn(email, password);
      }
    } catch (e) {
      if (!mounted) return;
      _show(e.toString());
    }
  }

  void _show(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loading = context.watch<AuthProvider>().loading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.appName, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Text(_signUpMode ? 'Créer votre compte professionnel' : l10n.welcome, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 28),
                    if (_signUpMode) ...[
                      TextFormField(controller: _name, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: l10n.fullName, prefixIcon: const Icon(Icons.person_outline)), validator: (v) => v == null || v.trim().isEmpty ? 'Nom complet obligatoire' : null),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.email_outlined)), validator: (v) {
                      final value = v?.trim() ?? '';
                      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value) ? null : 'Adresse e-mail invalide';
                    }),
                    const SizedBox(height: 16),
                    TextFormField(controller: _password, obscureText: _obscurePassword, textInputAction: _signUpMode ? TextInputAction.next : TextInputAction.done, decoration: InputDecoration(labelText: 'Mot de passe', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _obscurePassword = !_obscurePassword), icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => (v ?? '').length >= 8 ? null : 'Le mot de passe doit contenir au moins 8 caractères'),
                    const SizedBox(height: 16),
                    if (_signUpMode) ...[
                      TextFormField(obscureText: _obscureConfirmPassword, textInputAction: TextInputAction.done, decoration: const InputDecoration(labelText: 'Confirmer le mot de passe', prefixIcon: Icon(Icons.lock_reset_outlined)), validator: (v) => v == _password.text ? null : 'Les mots de passe ne correspondent pas'),
                      const SizedBox(height: 20),
                      if (_showCompanyStep) ...[
                        const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('بعد المتابعة، ستدخل معلومات الشركة القانونية: Raison sociale، RC، IF، ICE، الشكل القانوني، العنوان، المدينة والهاتف المهني.'))),
                        const SizedBox(height: 12),
                      ],
                    ],
                    FilledButton(onPressed: loading ? null : _submit, child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_signUpMode ? (_showCompanyStep ? 'Créer le compte' : 'Continuer vers les informations de l’entreprise') : l10n.login)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: loading ? null : () => setState(() { _signUpMode = !_signUpMode; _showCompanyStep = false; }), child: Text(_signUpMode ? 'J’ai déjà un compte' : 'Créer un nouveau compte')),
                    if (_signUpMode && _showCompanyStep) TextButton(onPressed: loading ? null : () => setState(() => _showCompanyStep = false), child: const Text('Retour')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
