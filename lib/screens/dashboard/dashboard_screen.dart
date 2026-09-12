import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/expense.dart';
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

enum _DashboardPeriod { month, quarter, year }

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
    final pages = <Widget>[
      _Home(l10n: l10n),
      const InvoicesScreen(),
      const ExpensesScreen(),
      const ClientsScreen(),
      const ProductsScreen(),
      const CpuScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_index == 0 ? l10n.dashboard : _label(l10n))),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Accueil'),
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

  String _label(AppLocalizations l10n) {
    switch (_index) {
      case 1:
        return l10n.invoices;
      case 2:
        return 'Dépenses';
      case 3:
        return l10n.clients;
      case 4:
        return 'Produits';
      case 5:
        return l10n.cpu;
      case 6:
        return l10n.settings;
      default:
        return l10n.dashboard;
    }
  }
}

class _DashboardData {
  const _DashboardData({required this.invoices, required this.expenses, required this.clientCount, required this.productCount});

  final List<InvoiceModel> invoices;
  final List<ExpenseModel> expenses;
  final int clientCount;
  final int productCount;

  _Metrics metrics(_DashboardPeriod period, DateTime now) {
    final range = _range(period, now);
    final periodInvoices = invoices.where((i) => !i.date.isBefore(range.start) && i.date.isBefore(range.end));
    final periodExpenses = expenses.where((e) => !e.date.isBefore(range.start) && e.date.isBefore(range.end));
    return _Metrics(
      invoiced: periodInvoices.where((i) => i.status != 'cancelled').fold(0.0, (s, i) => s + i.totalTtc),
      collected: periodInvoices.where((i) => i.status == 'paid').fold(0.0, (s, i) => s + i.totalTtc),
      receivable: periodInvoices.where((i) => i.status == 'issued').fold(0.0, (s, i) => s + i.totalTtc),
      expenses: periodExpenses.fold(0.0, (s, e) => s + e.totalTtc),
      vatCollected: periodInvoices.where((i) => i.status != 'cancelled').fold(0.0, (s, i) => s + i.totalTva),
      vatOnExpenses: periodExpenses.fold(0.0, (s, e) => s + e.taxAmount),
    );
  }

  static _Range _range(_DashboardPeriod period, DateTime now) {
    switch (period) {
      case _DashboardPeriod.month:
        return _Range(DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 1));
      case _DashboardPeriod.quarter:
        final startMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return _Range(DateTime(now.year, startMonth, 1), DateTime(now.year, startMonth + 3, 1));
      case _DashboardPeriod.year:
        return _Range(DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
    }
  }
}

class _Range {
  const _Range(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

class _Metrics {
  const _Metrics({required this.invoiced, required this.collected, required this.receivable, required this.expenses, required this.vatCollected, required this.vatOnExpenses});
  final double invoiced;
  final double collected;
  final double receivable;
  final double expenses;
  final double vatCollected;
  final double vatOnExpenses;
  double get netVat => vatCollected - vatOnExpenses;
  double get operatingBalance => collected - expenses;
}

class _Home extends StatefulWidget {
  const _Home({required this.l10n});
  final AppLocalizations l10n;
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  late Future<_DashboardData> _future;
  _DashboardPeriod _period = _DashboardPeriod.month;

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
      expenses: results[1] as List<ExpenseModel>,
      clientCount: (results[2] as List).length,
      productCount: (results[3] as List).length,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text('Impossible de charger le tableau de bord.\n${snapshot.error}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
          ])));
        }

        final data = snapshot.data!;
        final current = data.metrics(_period, DateTime.now());
        final previous = data.metrics(_period, _previousAnchor(DateTime.now()));

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(widget.l10n.welcomeDashboard, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (user?.phone != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(user!.phone!)),
              const SizedBox(height: 16),
              SegmentedButton<_DashboardPeriod>(
                segments: const [
                  ButtonSegment(value: _DashboardPeriod.month, label: Text('Mois'), icon: Icon(Icons.calendar_month_outlined)),
                  ButtonSegment(value: _DashboardPeriod.quarter, label: Text('Trimestre'), icon: Icon(Icons.date_range_outlined)),
                  ButtonSegment(value: _DashboardPeriod.year, label: Text('Année'), icon: Icon(Icons.calendar_today_outlined)),
                ],
                selected: {_period},
                onSelectionChanged: (value) => setState(() => _period = value.first),
              ),
              const SizedBox(height: 16),
              Text(_periodLabel(), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.32,
                children: [
                  _MetricCard(icon: Icons.trending_up, label: 'CA facturé', value: current.invoiced),
                  _MetricCard(icon: Icons.account_balance_wallet_outlined, label: 'Encaissé', value: current.collected),
                  _MetricCard(icon: Icons.schedule, label: 'À encaisser', value: current.receivable),
                  _MetricCard(icon: Icons.payments_outlined, label: 'Dépenses', value: current.expenses),
                ],
              ),
              const SizedBox(height: 10),
              _ComparisonCard(current: current, previous: previous),
              const SizedBox(height: 16),
              _SummaryCard(metrics: current),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _CountCard(icon: Icons.receipt_long, label: 'Factures', value: data.invoices.length)),
                const SizedBox(width: 10),
                Expanded(child: _CountCard(icon: Icons.people_outline, label: 'Clients', value: data.clientCount)),
                const SizedBox(width: 10),
                Expanded(child: _CountCard(icon: Icons.inventory_2_outlined, label: 'Produits', value: data.productCount)),
              ]),
              const SizedBox(height: 16),
              Card(child: ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: const Text('Solde opérationnel'),
                subtitle: const Text('Encaissé − dépenses'),
                trailing: Text('${current.operatingBalance.toStringAsFixed(2)} DH', style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
            ],
          ),
        );
      },
    );
  }

  DateTime _previousAnchor(DateTime now) {
    switch (_period) {
      case _DashboardPeriod.month:
        return DateTime(now.year, now.month - 1, 1);
      case _DashboardPeriod.quarter:
        return DateTime(now.year, now.month - 3, 1);
      case _DashboardPeriod.year:
        return DateTime(now.year - 1, now.month, 1);
    }
  }

  String _periodLabel() {
    switch (_period) {
      case _DashboardPeriod.month: return 'Ce mois';
      case _DashboardPeriod.quarter: return 'Ce trimestre';
      case _DashboardPeriod.year: return 'Cette année';
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 22),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 3),
        FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text('${value.toStringAsFixed(2)} DH', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
      ]),
    ),
  );
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.current, required this.previous});
  final _Metrics current;
  final _Metrics previous;

  double _change(double current, double previous) => previous == 0 ? (current == 0 ? 0 : 100) : ((current - previous) / previous) * 100;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Évolution vs période précédente', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _ChangeRow(label: 'CA facturé', value: _change(current.invoiced, previous.invoiced)),
        _ChangeRow(label: 'Encaissé', value: _change(current.collected, previous.collected)),
        _ChangeRow(label: 'Dépenses', value: _change(current.expenses, previous.expenses)),
      ]),
    ),
  );
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(value >= 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
      const SizedBox(width: 6),
      Expanded(child: Text(label)),
      Text('${value.abs().toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
    ]),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.metrics});
  final _Metrics metrics;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Synthèse TVA', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _SummaryRow(label: 'TVA collectée', value: metrics.vatCollected),
        _SummaryRow(label: 'TVA sur dépenses', value: metrics.vatOnExpenses),
        const Divider(),
        _SummaryRow(label: 'TVA nette estimée', value: metrics.netVat, bold: true),
        const SizedBox(height: 6),
        Text('Indicateur de gestion, pas un calcul fiscal officiel.', style: Theme.of(context).textTheme.bodySmall),
      ]),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.bold = false});
  final String label;
  final double value;
  final bool bold;
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: bold ? FontWeight.bold : null);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text(label, style: style)), Text('${value.toStringAsFixed(2)} DH', style: style)]));
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 10), leading: Icon(icon), title: Text('$value'), subtitle: Text(label)));
}
