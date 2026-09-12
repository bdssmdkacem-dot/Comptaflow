import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/cpu_calculator.dart';
import '../../core/services/supabase_client.dart';
import '../../l10n/app_localizations.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _companyName = TextEditingController();
  final _rc = TextEditingController();
  final _ice = TextEditingController();
  final _ifNumber = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  String _legalForm = 'SARL';
  String _activity = 'services';
  bool _saving = false;

  @override
  void dispose() {
    _fullName.dispose();
    _companyName.dispose();
    _rc.dispose();
    _ice.dispose();
    _ifNumber.dispose();
    _address.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    return value == null || value.trim().isEmpty ? '$label obligatoire' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = SupabaseClientService.client.auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await SupabaseClientService.client.from('profiles').upsert({
        'user_id': user.id,
        'full_name': _fullName.text.trim(),
        'company_name': _companyName.text.trim(),
        'rc': _rc.text.trim(),
        'ice': _ice.text.trim(),
        'if_number': _ifNumber.text.trim(),
        'legal_form': _legalForm,
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'professional_phone': _phone.text.trim(),
        'activity_type': _activity,
        'locale_pref': Localizations.localeOf(context).languageCode,
      }, onConflict: 'user_id');

      if (!mounted) return;
      widget.onSaved?.call();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.message} (${e.code})')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Informations de l’entreprise')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Ces informations sont nécessaires pour créer votre espace comptable.', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            TextFormField(controller: _fullName, decoration: InputDecoration(labelText: l10n.fullName), validator: (v) => _required(v, 'Nom complet'), textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            TextFormField(controller: _companyName, decoration: const InputDecoration(labelText: 'Raison sociale'), validator: (v) => _required(v, 'Raison sociale'), textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            TextFormField(controller: _rc, decoration: const InputDecoration(labelText: 'RC — Registre de commerce'), validator: (v) => _required(v, 'RC'), textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            TextFormField(controller: _ifNumber, decoration: const InputDecoration(labelText: 'IF — Identifiant fiscal'), validator: (v) => _required(v, 'IF'), textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            TextFormField(controller: _ice, decoration: const InputDecoration(labelText: 'ICE — Identifiant commun de l’entreprise'), validator: (v) => _required(v, 'ICE'), textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _legalForm,
              decoration: const InputDecoration(labelText: 'Forme juridique'),
              items: const [
                DropdownMenuItem(value: 'SARL', child: Text('SARL')),
                DropdownMenuItem(value: 'SARL AU', child: Text('SARL AU')),
                DropdownMenuItem(value: 'SA', child: Text('SA')),
                DropdownMenuItem(value: 'SAS', child: Text('SAS')),
                DropdownMenuItem(value: 'AUTO_ENTREPRENEUR', child: Text('Auto-entrepreneur')),
                DropdownMenuItem(value: 'AUTRE', child: Text('Autre')),
              ],
              onChanged: _saving ? null : (value) => setState(() => _legalForm = value ?? 'SARL'),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Adresse professionnelle'), validator: (v) => _required(v, 'Adresse'), textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'Ville'), validator: (v) => _required(v, 'Ville'), textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Téléphone professionnel'), validator: (v) => _required(v, 'Téléphone'), keyboardType: TextInputType.phone, textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _activity,
              decoration: InputDecoration(labelText: l10n.activityType),
              items: const [
                DropdownMenuItem(value: 'services', child: Text('Services — 10%')),
                DropdownMenuItem(value: 'artisanal', child: Text('Artisanal — 5%')),
                DropdownMenuItem(value: 'commercial', child: Text('Commercial — 3%')),
              ],
              onChanged: _saving ? null : (value) => setState(() => _activity = value ?? 'services'),
            ),
            const SizedBox(height: 8),
            Text('Taux: ${(CpuCalculator.rateForActivity(_activity) * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Enregistrer et continuer'),
            ),
          ],
        ),
      ),
    );
  }
}
