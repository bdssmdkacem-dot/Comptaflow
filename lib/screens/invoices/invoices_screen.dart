import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});
  @override
  Widget build(BuildContext context) => Center(child: Text(AppLocalizations.of(context).invoices, style: Theme.of(context).textTheme.headlineMedium));
}
