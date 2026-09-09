import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../clients/clients_screen.dart';
import '../cpu/cpu_screen.dart';
import '../invoices/invoices_screen.dart';
import '../products/products_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = [
      _Home(l10n: l10n),
      const InvoicesScreen(),
      const ClientsScreen(),
      const ProductsScreen(),
      const CpuScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboard)),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined), label: l10n.dashboard),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), label: l10n.invoices),
          NavigationDestination(icon: const Icon(Icons.people_outline), label: l10n.clients),
          const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Produits'),
          NavigationDestination(icon: const Icon(Icons.calculate_outlined), label: l10n.cpu),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l10n.settings),
        ],
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.welcomeDashboard, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (user?.phone != null) ...[
            const SizedBox(height: 8),
            Text(user!.phone!),
          ],
          const SizedBox(height: 24),
          Card(child: ListTile(leading: const Icon(Icons.receipt_long), title: Text(l10n.invoices), subtitle: const Text('0'))),
          Card(child: ListTile(leading: const Icon(Icons.people), title: Text(l10n.clients), subtitle: const Text('0'))),
          Card(child: ListTile(leading: const Icon(Icons.inventory_2), title: const Text('Produits & services'), subtitle: const Text('Catalogue'))),
          Card(child: ListTile(leading: const Icon(Icons.calculate), title: Text(l10n.cpu), subtitle: const Text('—'))),
        ],
      ),
    );
  }
}
