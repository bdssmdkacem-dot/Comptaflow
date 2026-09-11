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
  final List<ExpenseModel> expenses;
  final int clientCount;
  final int productCount;

  _DashboardPeriodData forPeriod(_DashboardPeriod period, DateTime now) {
    final currentRange = _range(period, now);
    final previousRange = _range(period, _previousAnchor(period, now));
    return _DashboardPeriodData(current: _metrics(currentRange), previous: _metrics(previousRange));
  }

  _Metrics _metrics(_DateRange range) {
    final periodInvoices = invoices.where((i) => _inRange(i.date, range));
    final periodExpenses = expenses.where((e) => _inRange(e.date, range));
    return _Metrics(
      invoiced: periodInvoices.where((i) => i.status != 'cancelled').fold(0.0, (sum, i) => sum + i.totalTtc),
      collected: periodInvoices.where((i) => i.status == 'paid').fold(0.0, (sum, i) => sum + i.totalTtc),
      receivable: periodInvoices.where((i) => i.status == 'issued').fold(0.0, (sum, i) => sum + i.totalTtc),
      expenses: periodExpenses.fold(0.0, (sum, e) => sum + e.totalTtc),
      vatCollected: periodInvoices.where((i) => i.status != 'cancelled').fold(0.0, (sum, i) => sum + i.totalTva),
      vatOnExpenses: periodExpenses.fold(0.0, (sum, e) => sum + e.taxAmount),
    );
  }

  List<_MonthPoint> monthlyPoints(DateTime now) {
    return List.generate(6, (index) {
      final month = DateTime(now.year, now.month - 5 + index, 1);
      final next = DateTime(month.year, month.month + 1, 1);
      final invoicesInMonth = invoices.where((i) => !i.date.isBefore(month) && i.date.isBefore(next) && i.status != 'cancelled');
      final expensesInMonth = expenses.where((e) => !e.date.isBefore(month) && e.date.isBefore(next));
      return _MonthPoint(
        label: '${month.month}/${month.year % 100}',
        invoiced: invoicesInMonth.fold(0.0, (sum, i) => sum + i.totalTtc),
        expenses: expensesInMonth.fold(0.0, (sum, e) => sum + e.totalTtc),
      );
    });
  }

  static bool _inRange(DateTime date, _DateRange range) => !date.isBefore(range.start) && date.isBefore(range.end);

  static DateTime _previousAnchor(_DashboardPeriod period, DateTime now) {
    switch (period) {
      case _DashboardPeriod.month:
        final previousMonthLastDay = DateTime(now.year, now.month, 0).day;
        return DateTime(now.year, now.month - 1, now.day.clamp(1, previousMonthLastDay) as int);
      case _DashboardPeriod.quarter:
        final previousQuarterLastDay = DateTime(now.year, now.month - 2, 0).day;
        return DateTime(now.year, now.month - 3, now.day.clamp(1, previousQuarterLastDay) as int);
      case _DashboardPeriod.year:
        final previousYearLastDay = DateTime(now.year - 1, now.month + 1, 0).day;
        return DateTime(now.year - 1, now.month, now.day.clamp(1, previousYearLastDay) as int);
    }
  }

  static _DateRange _range(_DashboardPeriod period, DateTime anchor) {
    switch (period) {
      case _DashboardPeriod.month:
        return _DateRange(DateTime(anchor.year, anchor.month, 1), DateTime(anchor.year, anchor.month + 1, 1));
      case _DashboardPeriod.quarter:
        final quarterStartMonth = ((anchor.month - 1) ~/ 3) * 3 + 1;
        return _DateRange(DateTime(anchor.year, quarterStartMonth, 1), DateTime(anchor.year, quarterStartMonth + 3, 1));
      case _DashboardPeriod.year:
        return _DateRange(DateTime(anchor.year, 1, 1), DateTime(anchor.year + 1, 1, 1));
    }
  }
}

class _DateRange {
  const _DateRange(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

class _DashboardPeriodData {
  const _DashboardPeriodData({required this.current, required this.previous});
  final _Metrics current;
  final _Metrics previous;
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

class _MonthPoint {
  const _MonthPoint({required this.label, required this.invoiced, required this.expenses});
  final String label;
  final double invoiced;
  final double expenses;
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

  String _periodLabel() {
    switch (_period) {
      case _DashboardPeriod.month:
        return 'Ce mois';
      case _DashboardPeriod.quarter:
        return 'Ce trimestre';
      case _DashboardPeriod.year:
        return 'Cette année';
    }
  }

  String _comparisonLabel() {
    switch (_period) {
      case _DashboardPeriod.month:
        return 'vs mois précédent';
      case _DashboardPeriod.quarter:
        return 'vs trimestre précédent';
      case _DashboardPeriod.year:
        return 'vs année précédente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, size: 48), const SizedBox(height: 12), Text('Impossible de charger le tableau de bord.\n${snapshot.error}', textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Réessayer'))])));
        final data = snapshot.data!;
        final periodData = data.forPeriod(_period, DateTime.now());
        final points = data.monthlyPoints(DateTime.now());
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
                childAspectRatio: 1.55,
                children: [
                  _MetricCard(icon: Icons.trending_up, label: 'CA facturé', value: periodData.current.invoiced),
                  _MetricCard(icon: Icons.account_balance_wallet_outlined, label: 'Encaissé', value: periodData.current.collected),
                  _MetricCard(icon: Icons.schedule, label: 'À encaisser', value: periodData.current.receivable),
                  _MetricCard(icon: Icons.payments_outlined, label: 'Dépenses', value: periodData.current.expenses),
                ],
              ),
              const SizedBox(height: 10),
              _ComparisonCard(current: periodData.current, previous: periodData.previous, label: _comparisonLabel()),
              const SizedBox(height: 16),
              _MonthlyChart(points: points),
              const SizedBox(height: 16),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('Synthèse TVA', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 10), _SummaryRow(label: 'TVA collectée', value: periodData.current.vatCollected), _SummaryRow(label: 'TVA sur dépenses', value: periodData.current.vatOnExpenses), const Divider(), _SummaryRow(label: 'TVA nette estimée', value: periodData.current.netVat, bold: true), const SizedBox(height: 6), Text('Indicateur de gestion, pas un calcul fiscal officiel.', style: Theme.of(context).textTheme.bodySmall)]))),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: _CountCard(icon: Icons.receipt_long, label: 'Factures', value: data.invoices.length)), const SizedBox(width: 10), Expanded(child: _CountCard(icon: Icons.people_outline, label: 'Clients', value: data.clientCount)), const SizedBox(width: 10), Expanded(child: _CountCard(icon: Icons.inventory_2_outlined, label: 'Produits', value: data.productCount))]),
              const SizedBox(height: 16),
              Card(child: ListTile(leading: const Icon(Icons.insights_outlined), title: const Text('Solde opérationnel'), subtitle: const Text('Encaissé − dépenses'), trailing: Text('${periodData.current.operatingBalance.toStringAsFixed(2)} DH', style: const TextStyle(fontWeight: FontWeight.bold)))),
            ],
          ),
        );
      },
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.current, required this.previous, required this.label});
  final _Metrics current;
  final _Metrics previous;
  final String label;

  double _change(double current, double previous) => previous == 0 ? (current == 0 ? 0 : 100) : ((current - previous) / previous) * 100;

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('Évolution $label', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 10), _ChangeRow(label: 'CA facturé', change: _change(current.invoiced, previous.invoiced)), _ChangeRow(label: 'Encaissé', change: _change(current.collected, previous.collected)), _ChangeRow(label: 'Dépenses', change: _change(current.expenses, previous.expenses))])));
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.label, required this.change});
  final String label;
  final double change;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Icon(change >= 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 16), const SizedBox(width: 6), Expanded(child: Text(label)), Text('${change.abs().toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold))]));
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.points});
  final List<_MonthPoint> points;
  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(0, (max, point) => max > point.invoiced ? max : point.invoiced);
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('6 derniers mois', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 14), if (maxValue == 0) const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('Aucune donnée sur les 6 derniers mois.'))) else ...points.map((point) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [SizedBox(width: 44, child: Text(point.label, style: Theme.of(context).textTheme.bodySmall)), Expanded(child: _Bar(value: point.invoiced, maxValue: maxValue, label: 'CA')), const SizedBox(width: 8), SizedBox(width: 84, child: Text('${point.invoiced.toStringAsFixed(0)} DH', textAlign: TextAlign.end, style: Theme.of(context).textTheme.bodySmall))])), const SizedBox(height: 8), Text('CA facturé par mois. Les dépenses restent visibles dans les indicateurs.', style: Theme.of(context).textTheme.bodySmall)])));
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.maxValue, required this.label});
  final double value;
  final double maxValue;
  final String label;
  @override
  Widget build(BuildContext context) {
    final factor = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0).toDouble();
    return Tooltip(message: '$label: ${value.toStringAsFixed(2)} DH', child: Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: factor, child: Container(height: 18, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Theme.of(context).colorScheme.primaryContainer)))));
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
