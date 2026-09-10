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
  final _name = TextEditingController();
  final _ice = TextEditingController();
  final _ifNumber = TextEditingController();
  String _activity = 'services';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _ice.dispose();
    _ifNumber.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = SupabaseClientService.client.auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await SupabaseClientService.client.from('profiles').upsert({
        'user_id': user.id,
        'full_name': _name.text.trim(),
        'ice': _ice.text.trim().isEmpty ? null : _ice.text.trim(),
        'if_number': _ifNumber.text.trim().isEmpty ? null : _ifNumber.text.trim(),
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
      appBar: AppBar(title: Text(l10n.completeProfile)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.fullName),
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.fullName
                  : null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ice,
              decoration: InputDecoration(labelText: l10n.ice),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ifNumber,
              decoration: InputDecoration(labelText: l10n.ifNumber),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _activity,
              decoration: InputDecoration(labelText: l10n.activityType),
              items: const [
                DropdownMenuItem(value: 'services', child: Text('Services — 10%')),
                DropdownMenuItem(value: 'artisanal', child: Text('Artisanal — 5%')),
                DropdownMenuItem(value: 'commercial', child: Text('Commercial — 3%')),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _activity = value ?? 'services'),
            ),
            const SizedBox(height: 8),
            Text(
              'Taux: ${(CpuCalculator.rateForActivity(_activity) * 100).toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
