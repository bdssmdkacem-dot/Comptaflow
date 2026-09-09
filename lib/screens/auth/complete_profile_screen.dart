import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/cpu_calculator.dart';
import '../../core/services/supabase_client.dart';
import '../../l10n/app_localizations.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
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
    final user = SupabaseClientService.client.auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await SupabaseClientService.client.from('profiles').upsert({
        'user_id': user.id,
        'full_name': _name.text.trim(),
        'ice': _ice.text.trim(),
        'if_number': _ifNumber.text.trim(),
        'activity_type': _activity,
        'locale_pref': Localizations.localeOf(context).languageCode,
      });
      if (mounted) Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.completeProfile)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _name, decoration: InputDecoration(labelText: l10n.fullName)),
          const SizedBox(height: 12),
          TextField(controller: _ice, decoration: InputDecoration(labelText: l10n.ice)),
          const SizedBox(height: 12),
          TextField(controller: _ifNumber, decoration: InputDecoration(labelText: l10n.ifNumber)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _activity,
            decoration: InputDecoration(labelText: l10n.activityType),
            items: const [
              DropdownMenuItem(value: 'services', child: Text('Services — 10%')),
              DropdownMenuItem(value: 'artisanal', child: Text('Artisanal — 5%')),
              DropdownMenuItem(value: 'commercial', child: Text('Commercial — 3%')),
            ],
            onChanged: (value) => setState(() => _activity = value ?? 'services'),
          ),
          const SizedBox(height: 8),
          Text('Taux: ${(CpuCalculator.rateForActivity(_activity) * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 24),
          FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ],
      ),
    );
  }
}
