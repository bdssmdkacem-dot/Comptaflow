import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = context.watch<LocaleProvider>().locale;
    return ListView(
      children: [
        ListTile(title: Text(l10n.language), trailing: DropdownButton<String>(value: locale.languageCode, items: [
          DropdownMenuItem(value: 'ar', child: Text(l10n.arabic)),
          DropdownMenuItem(value: 'fr', child: Text(l10n.french)),
        ], onChanged: (v) { if (v != null) context.read<LocaleProvider>().setLocale(Locale(v)); })),
        ListTile(leading: const Icon(Icons.logout), title: Text(l10n.logout), onTap: () => context.read<AuthProvider>().signOut()),
      ],
    );
  }
}
