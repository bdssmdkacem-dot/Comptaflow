import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_shell.dart';
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

    return AppShell(
      index: _index,
      onIndexChanged: (value) => setState(() => _index = value),
      body: pages[_index],
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.invoices,
    required this.expenses,
    required this.clientCount,
    required this.productCount,
  });

  final List<InvoiceModel> invoices;
  final List<ExpenseModel> expenses;
  final int clientCount;
  final int productCount;

  _Metrics metrics(_DashboardPeriod period, DateTime now) {
    final range = _range(period, now);
    final periodInvoices = invoices.where(
      (i) => !i.date.isBefore(range.start) && i.date.isBefore(range.end),
    );
    final periodExpenses = expenses.where(
      (e) => !e.date.isBefore(range.start) && e.date.isBefore(range.end),
    );
    return _Metrics(
      invoiced: periodInvoices
          .where((i) => i.status != 'cancelled')
          .fold(0.0, (s, i) => s + i.totalTtc),
      collected: periodInvoices
          .where((i) => i.status == 'paid')
          .fold(0.0, (s, i) => s + i.totalTtc),
      receivable: periodInvoices
          .where((i) => i.status == 'issued')
          .fold(0.0, (s, i) => s + i.totalTtc),
      expenses: periodExpenses.fold(0.0, (s, e) => s + e.totalTtc),
      vatCollected: periodInvoices
          .where((i) => i.status != 'cancelled')
          .fold(0.0, (s, i) => s + i.totalTva),
      vatOnExpenses: periodExpenses.fold(0.0, (s, e) => s + e.taxAmount),
    );
  }

  static _Range _range(_DashboardPeriod period, DateTime now) {
    switch (period) {
      case _DashboardPeriod.month:
        return _Range(
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 1),
        );
      case _DashboardPeriod.quarter:
        final startMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return _Range(
          DateTime(now.year, startMonth, 1),
          DateTime(now.year, startMonth + 3, 1),
        );
      case _DashboardPeriod.year:
        return _Range(
          DateTime(now.year, 1, 1),
          DateTime(now.year + 1, 1, 1),
        );
    }
  }
}

class _Range {
  const _Range(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

class _Metrics {
  const _Metrics({
    required this.invoiced,
    required this.collected,
    required this.receivable,
    required this.expenses,
    required this.vatCollected,
    required this.vatOnExpenses,
  });

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
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Impossible de charger le tableau de bord.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: Text(widget.l10n.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final now = DateTime.now();
        final current = data.metrics(_period, now);
        final previous = data.metrics(_period, _previousAnchor(now));

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              _DashboardHeader(
                userPhone: user?.phone,
                welcome: widget.l10n.welcomeDashboard,
              ),
              const SizedBox(height: 20),
              _PeriodSelector(
                period: _period,
                onChanged: (period) => setState(() => _period = period),
              ),
              const SizedBox(height: 20),
              _HeroRevenueCard(metrics: current, period: _period),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 760 ? 4 : 2;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 4 ? 1.35 : 1.42,
                    children: [
                      _MetricCard(
                        icon: Icons.account_balance_wallet_outlined,
                        label: widget.l10n.cashCollected,
                        value: current.collected,
                        accent: AppColors.accent,
                      ),
                      _MetricCard(
                        icon: Icons.schedule_rounded,
                        label: widget.l10n.toCollect,
                        value: current.receivable,
                        accent: AppColors.warning,
                      ),
                      _MetricCard(
                        icon: Icons.payments_outlined,
                        label: widget.l10n.expenses,
                        value: current.expenses,
                        accent: AppColors.error,
                      ),
                      _MetricCard(
                        icon: Icons.insights_outlined,
                        label: widget.l10n.balance,
                        value: current.operatingBalance,
                        accent: AppColors.success,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              _ComparisonCard(current: current, previous: previous),
              const SizedBox(height: 14),
              _QuickStatsCard(data: data),
              const SizedBox(height: 14),
              _SummaryCard(metrics: current),
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
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.userPhone, required this.welcome});

  final String? userPhone;
  final String welcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          child: const Center(
            child: Text(
              'C',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).appName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                welcome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (userPhone != null) ...[
                const SizedBox(height: 2),
                Text(
                  userPhone!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.period, required this.onChanged});

  final _DashboardPeriod period;
  final ValueChanged<_DashboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: SegmentedButton<_DashboardPeriod>(
        showSelectedIcon: false,
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: WidgetStatePropertyAll(
            Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        segments: [
          ButtonSegment(
            value: _DashboardPeriod.month,
            label: Text(AppLocalizations.of(context).dashboardPeriodMonth),
            icon: Icon(Icons.calendar_month_outlined, size: 18),
          ),
          ButtonSegment(
            value: _DashboardPeriod.quarter,
            label: Text(AppLocalizations.of(context).dashboardPeriodQuarter),
            icon: Icon(Icons.date_range_outlined, size: 18),
          ),
          ButtonSegment(
            value: _DashboardPeriod.year,
            label: Text(AppLocalizations.of(context).dashboardPeriodYear),
            icon: Icon(Icons.calendar_today_outlined, size: 18),
          ),
        ],
        selected: {period},
        onSelectionChanged: (value) => onChanged(value.first),
      ),
    );
  }
}

class _HeroRevenueCard extends StatelessWidget {
  const _HeroRevenueCard({required this.metrics, required this.period});

  final _Metrics metrics;
  final _DashboardPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.deep,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up_rounded, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).caInvoiced,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _periodLabel(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${metrics.invoiced.toStringAsFixed(2)} DH',
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 17, color: AppColors.accent),
              const SizedBox(width: 7),
              Text(
                '${metrics.collected.toStringAsFixed(2)} DH encaissés',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _periodLabel() {
    switch (period) {
      case _DashboardPeriod.month:
        return widget.l10n.dashboardPeriodMonth;
      case _DashboardPeriod.quarter:
        return widget.l10n.dashboardPeriodQuarter;
      case _DashboardPeriod.year:
        return widget.l10n.dashboardPeriodYear;
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: accent),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                '${value.toStringAsFixed(2)} DH',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.current, required this.previous});

  final _Metrics current;
  final _Metrics previous;

  double _change(double current, double previous) =>
      previous == 0 ? (current == 0 ? 0 : 100) : ((current - previous) / previous) * 100;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.compare_arrows_rounded, size: 19, color: AppColors.accent),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context).evolution,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppLocalizations.of(context).vsPreviousPeriod,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ChangeRow(label: AppLocalizations.of(context).caInvoiced, value: _change(current.invoiced, previous.invoiced)),
              _ChangeRow(label: AppLocalizations.of(context).cashCollected, value: _change(current.collected, previous.collected)),
              _ChangeRow(label: AppLocalizations.of(context).expenses, value: _change(current.expenses, previous.expenses)),
            ],
          ),
        ),
      );
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    final color = positive ? AppColors.success : AppColors.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 15,
              color: color,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(label)),
          Text(
            '${value.abs().toStringAsFixed(1)}%',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).yourActivity,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CountItem(
                    icon: Icons.receipt_long_rounded,
                    label: AppLocalizations.of(context).invoicesCount,
                    value: data.invoices.length,
                  ),
                ),
                Expanded(
                  child: _CountItem(
                    icon: Icons.people_alt_outlined,
                    label: 'Clients',
                    value: data.clientCount,
                  ),
                ),
                Expanded(
                  child: _CountItem(
                    icon: Icons.inventory_2_outlined,
                    label: AppLocalizations.of(context).productsServices,
                    value: data.productCount,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountItem extends StatelessWidget {
  const _CountItem({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 21, color: AppColors.accent),
          const SizedBox(height: 7),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.metrics});

  final _Metrics metrics;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_outlined, size: 19, color: AppColors.accent),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context).vatSummary,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryRow(label: 'TVA collectée', value: metrics.vatCollected),
              _SummaryRow(label: 'TVA sur dépenses', value: metrics.vatOnExpenses),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 7),
                child: Divider(height: 1),
              ),
              _SummaryRow(label: 'TVA nette estimée', value: metrics.netVat, bold: true),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).vatManagementNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
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
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: bold ? FontWeight.w800 : null,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('${value.toStringAsFixed(2)} DH', style: style),
        ],
      ),
    );
  }
}
