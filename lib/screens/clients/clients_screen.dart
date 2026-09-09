import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});
  @override
  Widget build(BuildContext context) => Center(child: Text(AppLocalizations.of(context).clients, style: Theme.of(context).textTheme.headlineMedium));
}
