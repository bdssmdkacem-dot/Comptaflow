import 'package:flutter/material.dart';

import '../../data/models/client.dart';
import '../../data/models/invoice.dart';
import '../../data/repositories/client_repo.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, required this.client});

  final ClientModel client;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final _repo = ClientRepository();
  late Future<_ClientDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ClientDetailData> _load() async {
    final results = await Future.wait([
      _repo.stats(widget.client.id),
      _repo.invoices(widget.client.id),
    ]);
    return _ClientDetailData(
      stats: results[0] as ClientInvoiceStats,
      invoices: results[1] as List<InvoiceModel>,
    );
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    return Scaffold(
      appBar: AppBar(title: Text(client.name)),
      body: FutureBuilder<_ClientDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Impossible de charger le client.\n${snapshot.error}'));
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _identityCard(client),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.7,
                  children: [
                    _metric('Factures', '${data.stats.invoiceCount}', Icons.receipt_long_outlined),
                    _metric('CA HT', _money(data.stats.caHt), Icons.trending_up),
                    _metric('Encaissé TTC', _money(data.stats.encaisseTtc), Icons.payments_outlined),
                    _metric('Restant TTC', _money(data.stats.restantTtc), Icons.account_balance_wallet_outlined),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Factures du client', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (data.invoices.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Aucune facture liée à ce client.'))))
                else
                  ...data.invoices.map(_invoiceTile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _identityCard(ClientModel c) {
    final rows = <String>[
      if (c.ice != null) 'ICE : ${c.ice}',
      if (c.ifNumber != null) 'IF : ${c.ifNumber}',
      if (c.rcNumber != null) 'RC : ${c.rcNumber}',
      if (c.tpNumber != null) 'TP : ${c.tpNumber}',
      if (c.phone != null) 'Téléphone : ${c.phone}',
      if (c.email != null) 'Email : ${c.email}',
      if (c.address != null) 'Adresse : ${c.address}',
      if (c.city != null) 'Ville : ${c.city}',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (rows.isEmpty) const Text('Aucune information complémentaire.') else ...rows.map((row) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(row),
          )),
        ]),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),
      );

  Widget _invoiceTile(InvoiceModel invoice) => Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
          title: Text(invoice.invoiceNumber),
          subtitle: Text('${_date(invoice.date)} • ${_status(invoice.status)}'),
          trailing: Text(_money(invoice.totalTtc), style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );

  String _status(String value) => switch (value) {
        'draft' => 'Brouillon',
        'issued' => 'Émise',
        'paid' => 'Payée',
        'cancelled' => 'Annulée',
        _ => value,
      };

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _money(double value) => '${value.toStringAsFixed(2)} MAD';
}

class _ClientDetailData {
  const _ClientDetailData({required this.stats, required this.invoices});
  final ClientInvoiceStats stats;
  final List<InvoiceModel> invoices;
}
