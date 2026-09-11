import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/company_profile.dart';
import '../../data/repositories/company_profile_repo.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repository = CompanyProfileRepository();
  late Future<CompanyProfile?> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.get();
  }

  Future<void> _editCompanyProfile(CompanyProfile? profile) async {
    final fullName = TextEditingController(text: profile?.fullName ?? '');
    final companyName = TextEditingController(text: profile?.companyName ?? '');
    final ice = TextEditingController(text: profile?.ice ?? '');
    final ifNumber = TextEditingController(text: profile?.ifNumber ?? '');
    final rc = TextEditingController(text: profile?.rcNumber ?? '');
    final tp = TextEditingController(text: profile?.tpNumber ?? '');
    final address = TextEditingController(text: profile?.address ?? '');
    final city = TextEditingController(text: profile?.city ?? '');
    final phone = TextEditingController(text: profile?.phone ?? '');
    final email = TextEditingController(text: profile?.email ?? '');
    final paymentTerms = TextEditingController(text: profile?.paymentTerms ?? '');
    final formKey = GlobalKey<FormState>();

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Identité de facturation'),
          content: SizedBox(
            width: 620,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(controller: companyName, decoration: const InputDecoration(labelText: 'Nom / raison sociale')),
                    TextFormField(controller: fullName, decoration: const InputDecoration(labelText: 'Nom du responsable'), validator: (v) => v == null || v.trim().isEmpty ? 'Nom requis' : null),
                    const SizedBox(height: 8),
                    TextFormField(controller: ice, decoration: const InputDecoration(labelText: 'ICE')),
                    TextFormField(controller: ifNumber, decoration: const InputDecoration(labelText: 'IF — Identifiant fiscal')),
                    TextFormField(controller: rc, decoration: const InputDecoration(labelText: 'RC — Registre de commerce')),
                    TextFormField(controller: tp, decoration: const InputDecoration(labelText: 'TP — Taxe professionnelle')),
                    const Divider(height: 24),
                    TextFormField(controller: address, decoration: const InputDecoration(labelText: 'Adresse')),
                    TextFormField(controller: city, decoration: const InputDecoration(labelText: 'Ville')),
                    TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Téléphone')),
                    TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email professionnel')),
                    TextFormField(controller: paymentTerms, decoration: const InputDecoration(labelText: 'Conditions de paiement', hintText: 'Ex. Paiement à 30 jours')),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await _repository.save(
                    fullName: fullName.text,
                    companyName: companyName.text,
                    ice: ice.text,
                    ifNumber: ifNumber.text,
                    rcNumber: rc.text,
                    tpNumber: tp.text,
                    address: address.text,
                    city: city.text,
                    phone: phone.text,
                    email: email.text,
                    paymentTerms: paymentTerms.text,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Erreur : $error')));
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      );
      if (saved == true && mounted) setState(() => _future = _repository.get());
    } finally {
      for (final controller in [fullName, companyName, ice, ifNumber, rc, tp, address, city, phone, email, paymentTerms]) {
        controller.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = context.watch<LocaleProvider>().locale;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: Text(l10n.language),
          trailing: DropdownButton<String>(
            value: locale.languageCode,
            items: [
              DropdownMenuItem(value: 'ar', child: Text(l10n.arabic)),
              DropdownMenuItem(value: 'fr', child: Text(l10n.french)),
            ],
            onChanged: (v) { if (v != null) context.read<LocaleProvider>().setLocale(Locale(v)); },
          ),
        ),
        const Divider(),
        FutureBuilder<CompanyProfile?>(
          future: _future,
          builder: (context, snapshot) {
            final profile = snapshot.data;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.business_outlined),
                title: const Text('Identité de facturation'),
                subtitle: Text(profile?.companyName?.isNotEmpty == true ? profile!.companyName! : 'ICE • IF • RC • TP • Conditions de paiement'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editCompanyProfile(profile),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Ces informations seront figées sur la facture lors de son passage de brouillon à émise. Le PDF n’est qu’une représentation de ces données.'),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(leading: const Icon(Icons.logout), title: Text(l10n.logout), onTap: () => context.read<AuthProvider>().signOut()),
      ],
    );
  }
}
