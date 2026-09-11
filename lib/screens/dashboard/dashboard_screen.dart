import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/invoice.dart';
import '../../data/repositories/client_repo.dart';
import '../../data/repositories/expense_repo.dart';
import '../../data/repositories/invoice_repo.dart';
import '../../data/repositories/product_repo.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../clients/clients_screen.dart';
import '../cpu/cpu_screen.dart';
import '../expenses/expenses_screen.dart';
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
      const ExpensesScreen(),
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
          const NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Dépenses'),
          NavigationDestination(icon: const Icon(Icons.people_outline), label: l10n.clients),
          const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Produits'),
          NavigationDestination(icon: const Icon(Icons.calculate_outlined), label: l10n.cpu),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l10n.settings),
        ],
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({required this.invoices, required this.expenses, required this.clientCount, required this.productCount});
  final List<InvoiceModel> invoices;
  final List<dynamic> expenses;
  final int clientCount;
  final int productCount;

  double get invoiced => invoices.where((i) => i.status != 'cancelled').fold(0, (sum, i) => sum + i.totalTtc);
  double get collected => invoices.where((i) => i.status == 'paid').fold(0, (sum, i) => sum + i.totalTtc);
  double get receivable => invoices.where((i) => i.status == 'issued').fold(0, (sum, i) => sum + i.totalTtc);
  double get expensesTotal => expenses.fold<double>(0, (sum, e) => sum + (e.totalTtc as double));
  double get vatCollected => invoices.where((i) => i.status != 'cancelled').fold(0, (sum, i) => sum + i.totalTva);
  double get vatOnExpenses => expenses.fold<double>(0, (sum, e) => sum + (e.taxAmount as double));
}

class _Home extends StatefulWidget {
  const _Home({required this.l10n});
  final AppLocalizations l10n;
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final results = await Future.wait<dynamic>([
      InvoiceRepository().list(),
      ExpenseRepository().list(),
      ClientRepository().list(),
      ProductRepository().list(),
    ]);
    return _DashboardData(
      invoices: results[0] as List<InvoiceModel>,
      expenses: results[1] as List<dynamic>,
      clientCount: (results[2] as List).length,
      productCount: (results[3] as List).length,
    );
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, size: 48), const SizedBox(height: 12), Text('Impossible de charger le tableau de bord.\n${snapshot.error}', textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Réessayer'))])));
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async { _refresh(); await _future; },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(widget.l10n.welcomeDashboard, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (user?.phone != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(user!.phone!)),
              const SizedBox(height: 20),
              GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.55, children: [
                _MetricCard(icon: Icons.trending_up, label: 'CA facturé', value: data.invoiced),
                _MetricCard(icon: Icons.account_balance_wallet_outlined, label: 'Encaissé', value: data.collected),
                _MetricCard(icon: Icons.schedule, label: 'À encaisser', value: data.receivable),
                _MetricCard(icon: Icons.payments_outlined, label: 'Dépenses', value: data.expensesTotal),
              ]),
              const SizedBox(height: 16),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Synthèse TVA', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _SummaryRow(label: 'TVA collectée', value: data.vatCollected),
                _SummaryRow(label: 'TVA sur dépenses', value: data.vatOnExpenses),
                const Divider(),
                _SummaryRow(label: 'TVA nette estimée', value: data.vatCollected - data.vatOnExpenses, bold: true),
                const SizedBox(height: 6),
                Text('Indicateur de gestion, pas un calcul fiscal officiel.', style: Theme.of(context).textTheme.bodySmall),
              ]))),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: _CountCard(icon: Icons.receipt_long, label: 'Factures', value: data.invoices.length)), const SizedBox(width: 10), Expanded(child: _CountCard(icon: Icons.people_outline, label: 'Clients', value: data.clientCount)), const SizedBox(width: 10), Expanded(child: _CountCard(icon: Icons.inventory_2_outlined, label: 'Produits', value: data.productCount))]),
              const SizedBox(height: 16),
              Card(child: ListTile(leading: const Icon(Icons.insights_outlined), title: const Text('Solde opérationnel'), subtitle: const Text('Encaissé − dépenses'), trailing: Text('${(data.collected - data.expensesTotal).toStringAsFixed(2)} DH', style: const TextStyle(fontWeight: FontWeight.bold)))) ,
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 22), const SizedBox(height: 6), Text(label, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 3), Text('${value.toStringAsFixed(2)} DH', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))])));
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 12), leading: Icon(icon), title: Text('$value'), subtitle: Text(label)));
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.bold = false});
  final String label;
  final double value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)), Text('${value.toStringAsFixed(2)} DH', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))]));
}
