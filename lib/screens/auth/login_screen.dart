import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _companyName = TextEditingController();
  final _rc = TextEditingController();
  final _ifNumber = TextEditingController();
  final _ice = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _signUpMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _legalForm = 'SARL';

  @override
  void dispose() {
    for (final controller in [_name, _companyName, _rc, _ifNumber, _ice, _address, _city, _phone, _email, _password, _confirmPassword]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value, String label) => value == null || value.trim().isEmpty ? '$label obligatoire' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final auth = context.read<AuthProvider>();
      if (_signUpMode) {
        await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          fullName: _name.text.trim(),
          companyName: _companyName.text.trim(),
          rc: _rc.text.trim(),
          ifNumber: _ifNumber.text.trim(),
          ice: _ice.text.trim(),
          legalForm: _legalForm,
          address: _address.text.trim(),
          city: _city.text.trim(),
          professionalPhone: _phone.text.trim(),
        );
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.mark_email_read_outlined),
            title: const Text(l10n.verifyEmailTitle),
            content: Text(l10n.verifyEmailMessage(_email.text.trim())),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(l10n.ok))],
          ),
        );
      } else {
        await auth.signIn(_email.text.trim(), _password.text);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon));

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
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.appName, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Text(_signUpMode ? l10n.signUpTitle : l10n.welcome, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 28),
                    if (_signUpMode) ...[
                      Text(l10n.companyInfo, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      TextFormField(controller: _name, decoration: _decoration(l10n.fullName, Icons.person_outline), validator: (v) => _required(v, l10n.fullName), textInputAction: TextInputAction.next),
                      const SizedBox(height: 12),
                      TextFormField(controller: _companyName, decoration: _decoration(l10n.companyName, Icons.business_outlined), validator: (v) => _required(v, l10n.companyName), textInputAction: TextInputAction.next),
                      const SizedBox(height: 12),
                      TextFormField(controller: _rc, decoration: _decoration(l10n.rcLabel, Icons.assignment_outlined), validator: (v) => _required(v, l10n.rcLabel), textInputAction: TextInputAction.next),
                      const SizedBox(height: 12),
                      TextFormField(controller: _ifNumber, decoration: _decoration(l10n.ifLabel, Icons.receipt_long_outlined), validator: (v) => _required(v, l10n.ifLabel), textInputAction: TextInputAction.next),
                      const SizedBox(height: 12),
                      TextFormField(controller: _ice, decoration: _decoration(l10n.iceLabel, Icons.badge_outlined), validator: (v) => _required(v, l10n.iceLabel), textInputAction: TextInputAction.next),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(initialValue: _legalForm, decoration: _decoration(l10n.legalForm, Icons.gavel_outlined), items: const [
                        DropdownMenuItem(value: 'SARL', child: Text('SARL')),
                        DropdownMenuItem(value: 'SARL AU', child: Text('SARL AU')),
                        DropdownMenuItem(value: 'SA', child: Text('SA')),
                        DropdownMenuItem(value: 'SAS', child: Text('SAS')),
                        DropdownMenuItem(value: 'AUTO_ENTREPRENEUR', child: Text('Auto-entrepreneur')),
                        DropdownMenuItem(value: 'AUTRE', child: Text('Autre')),
                      ], onChanged: loading ? null : (v) => setState(() => _legalForm = v ?? 'SARL')),
                      const SizedBox(height: 12),
                      TextFormField(controller: _address, decoration: _decoration(l10n.address, Icons.location_on_outlined), validator: (v) => _required(v, l10n.address), textInputAction: TextInputAction.next),
                      const SizedBox(height: 12),
                      TextFormField(controller: _city, decoration: _decoration(l10n.city, Icons.location_city_outlined), validator: (v) => _required(v, l10n.city), textInputAction: TextInputAction.next),
                      const SizedBox(height: 12),
                      TextFormField(controller: _phone, decoration: _decoration(l10n.professionalPhone, Icons.phone_outlined), validator: (v) => _required(v, l10n.professionalPhone), keyboardType: TextInputType.phone, textInputAction: TextInputAction.next),
                      const SizedBox(height: 24),
                    ],
                    TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: _decoration(l10n.email, Icons.email_outlined), validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '') ? null : l10n.invalidEmail, textInputAction: TextInputAction.next),
                    const SizedBox(height: 12),
                    TextFormField(controller: _password, obscureText: _obscurePassword, decoration: _decoration(l10n.password, Icons.lock_outline).copyWith(suffixIcon: IconButton(onPressed: () => setState(() => _obscurePassword = !_obscurePassword), icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => (v ?? '').length >= 8 ? null : l10n.passwordMin, textInputAction: _signUpMode ? TextInputAction.next : TextInputAction.done),
                    if (_signUpMode) ...[
                      const SizedBox(height: 12),
                      TextFormField(controller: _confirmPassword, obscureText: _obscureConfirmPassword, decoration: _decoration(l10n.confirmPassword, Icons.lock_reset_outlined).copyWith(suffixIcon: IconButton(onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword), icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => v == _password.text ? null : l10n.passwordMismatch),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(onPressed: loading ? null : _submit, child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_signUpMode ? l10n.createAccount : l10n.login)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: loading ? null : () => setState(() => _signUpMode = !_signUpMode), child: Text(_signUpMode ? l10n.alreadyAccount : l10n.newAccount)),
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
