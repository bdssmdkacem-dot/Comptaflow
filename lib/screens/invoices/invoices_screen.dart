import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/services/invoice_pdf_service.dart';
import '../../core/services/supabase_client.dart';
import '../../data/models/client.dart';
import '../../data/models/invoice.dart';
import '../../data/models/product.dart';
import '../../data/repositories/client_repo.dart';
import '../../data/repositories/invoice_repo.dart';
import '../../data/repositories/product_repo.dart';
import '../../l10n/app_localizations.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoiceDraftLine {
  _InvoiceDraftLine();

  ProductModel? product;
  final description = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final price = TextEditingController(text: '0');
  final tax = TextEditingController(text: '0');

  double get q => double.tryParse(quantity.text.replaceAll(',', '.')) ?? 0;
  double get p => double.tryParse(price.text.replaceAll(',', '.')) ?? 0;
  double get t => double.tryParse(tax.text.replaceAll(',', '.')) ?? 0;
  double get ht => q * p;
  double get tva => ht * t / 100;

  void useProduct(ProductModel value) {
    product = value;
    description.text = value.name;
    price.text = value.unitPrice.toStringAsFixed(2);
    tax.text = value.taxRate.toStringAsFixed(2);
  }

  void dispose() {
    description.dispose();
    quantity.dispose();
    price.dispose();
    tax.dispose();
  }
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _repository = InvoiceRepository();
  final _pdfService = const InvoicePdfService();
  late Future<List<InvoiceModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.list();
  }

  String _number() {
    final now = DateTime.now();
    return 'FAC-${now.year}-${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 1000000}';
  }

  Future<void> _createInvoice() async {
    try {
      final clients = await ClientRepository().list();
      final products = await ProductRepository().list();
      if (!mounted) return;

      final number = TextEditingController(text: _number());
      String? clientId;
      final lines = <_InvoiceDraftLine>[_InvoiceDraftLine()];
      final formKey = GlobalKey<FormState>();

      final created = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            final ht = lines.fold<double>(0, (sum, line) => sum + line.ht);
            final tva = lines.fold<double>(0, (sum, line) => sum + line.tva);
            return AlertDialog(
              title: const Text('Nouvelle facture'),
              content: SizedBox(
                width: 600,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: number,
                          decoration: const InputDecoration(labelText: 'N° facture'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Numéro requis' : null,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: clientId ?? '__cash__',
                          decoration: const InputDecoration(labelText: 'Client'),
                          items: [
                            const DropdownMenuItem(value: '__cash__', child: Text('Client comptant')),
                            ...clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (v) => setDialogState(() => clientId = v == '__cash__' ? null : v),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(lines.length, (index) {
                          final line = lines[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Row(children: [
                                      Expanded(child: Text('Ligne ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      if (lines.length > 1) IconButton(onPressed: () => setDialogState(() { final removed = lines.removeAt(index); removed.dispose(); }), icon: const Icon(Icons.delete_outline)),
                                    ]),
                                    if (products.isNotEmpty)
                                      DropdownButtonFormField<ProductModel>(
                                        initialValue: line.product,
                                        decoration: const InputDecoration(labelText: 'Produit / service'),
                                        items: products.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} — ${p.unitPrice.toStringAsFixed(2)} DH'))).toList(),
                                        onChanged: (p) { if (p != null) setDialogState(() => line.useProduct(p)); },
                                      ),
                                    TextFormField(controller: line.description, decoration: const InputDecoration(labelText: 'Description'), validator: (v) => v == null || v.trim().isEmpty ? 'Description requise' : null),
                                    Row(children: [
                                      Expanded(child: TextFormField(controller: line.quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setDialogState(() {}), decoration: const InputDecoration(labelText: 'Qté'))),
                                      const SizedBox(width: 8),
                                      Expanded(child: TextFormField(controller: line.price, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setDialogState(() {}), decoration: const InputDecoration(labelText: 'Prix HT'))),
                                      const SizedBox(width: 8),
                                      Expanded(child: TextFormField(controller: line.tax, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setDialogState(() {}), decoration: const InputDecoration(labelText: 'TVA %'))),
                                    ]),
                                    Align(alignment: Alignment.centerRight, child: Text('Ligne TTC : ${(line.ht + line.tva).toStringAsFixed(2)} DH')),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(onPressed: () => setDialogState(() => lines.add(_InvoiceDraftLine())), icon: const Icon(Icons.add), label: const Text('Ajouter une ligne')),
                        ),
                        const Divider(),
                        _TotalRow(label: 'Total HT', value: ht),
                        _TotalRow(label: 'TVA', value: tva),
                        _TotalRow(label: 'Total TTC', value: ht + tva, bold: true),
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
                    if (lines.any((line) => line.q <= 0 || line.p < 0 || line.t < 0 || line.t > 100)) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Vérifiez les quantités, prix et TVA.')));
                      return;
                    }
                    try {
                      await _repository.create(
                        invoiceNumber: number.text,
                        clientId: clientId,
                        date: DateTime.now(),
                        items: lines.map((line) => InvoiceLineInput(description: line.description.text, quantity: line.q, unitPrice: line.p, taxRate: line.t)).toList(),
                      );
                      if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                    } catch (error) {
                      if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Erreur : $error')));
                    }
                  },
                  child: const Text('Créer'),
                ),
              ],
            );
          },
        ),
      );
      number.dispose();
      for (final line in lines) { line.dispose(); }
      if (created == true && mounted) setState(() => _future = _repository.list());
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error')));
    }
  }

  Future<ClientModel?> _clientFor(InvoiceModel invoice) async {
    if (invoice.clientId == null) return null;
    final clients = await ClientRepository().list();
    for (final client in clients) {
      if (client.id == invoice.clientId) return client;
    }
    return null;
  }

  Future<List<int>> _buildPdf(InvoiceDetails details, ClientModel? client) async {
    return _pdfService.build(
      details,
      client: client,
      ownerEmail: SupabaseClientService.client.auth.currentUser?.email,
    );
  }

  Future<void> _previewPdf(InvoiceDetails details, ClientModel? client) async {
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text('Facture ${details.invoice.invoiceNumber}')),
        body: PdfPreview(
          canChangePageFormat: false,
          canChangeOrientation: false,
          allowSharing: false,
          allowPrinting: false,
          build: (_) => _buildPdf(details, client),
        ),
      ),
    ));
  }

  Future<void> _sharePdf(InvoiceDetails details, ClientModel? client) async {
    try {
      final bytes = await _buildPdf(details, client);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'facture-${details.invoice.invoiceNumber}.pdf',
        subject: 'Facture ${details.invoice.invoiceNumber}',
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur PDF : $error')));
    }
  }

  Future<void> _printPdf(InvoiceDetails details, ClientModel? client) async {
    try {
      await Printing.layoutPdf(
        name: 'Facture ${details.invoice.invoiceNumber}',
        onLayout: (_) => _buildPdf(details, client),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur impression : $error')));
    }
  }

  Future<void> _openDetails(InvoiceModel invoice) async {
    try {
      final details = await _repository.getDetails(invoice.id);
      final client = await _clientFor(invoice);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(details.invoice.invoiceNumber, style: Theme.of(sheetContext).textTheme.headlineSmall),
              Text('${details.invoice.date.day.toString().padLeft(2, '0')}/${details.invoice.date.month.toString().padLeft(2, '0')}/${details.invoice.date.year} • ${details.invoice.status}'),
              if (client != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Client : ${client.name}')),
              const SizedBox(height: 12),
              ...details.items.map((item) => ListTile(contentPadding: EdgeInsets.zero, title: Text(item.description), subtitle: Text('${item.quantity} × ${item.unitPrice.toStringAsFixed(2)} DH • TVA ${item.taxRate.toStringAsFixed(2)}%'), trailing: Text('${item.totalTtc.toStringAsFixed(2)} DH'))),
              const Divider(),
              _TotalRow(label: 'Total HT', value: details.calculatedHt),
              _TotalRow(label: 'TVA', value: details.calculatedTva),
              _TotalRow(label: 'Total TTC', value: details.calculatedTtc, bold: true),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(onPressed: () { Navigator.pop(sheetContext); _previewPdf(details, client); }, icon: const Icon(Icons.picture_as_pdf), label: const Text('Aperçu PDF')),
                  OutlinedButton.icon(onPressed: () => _sharePdf(details, client), icon: const Icon(Icons.share), label: const Text('Partager')),
                  OutlinedButton.icon(onPressed: () => _printPdf(details, client), icon: const Icon(Icons.print), label: const Text('Imprimer')),
                ],
              ),
              const SizedBox(height: 8),
              if (invoice.status == 'draft')
                OutlinedButton.icon(onPressed: () async { await _repository.updateStatus(invoice.id, 'issued'); if (sheetContext.mounted) Navigator.pop(sheetContext); if (mounted) setState(() => _future = _repository.list()); }, icon: const Icon(Icons.check), label: const Text('Marquer comme émise')),
              TextButton.icon(onPressed: () async { await _repository.delete(invoice.id); if (sheetContext.mounted) Navigator.pop(sheetContext); if (mounted) setState(() => _future = _repository.list()); }, icon: const Icon(Icons.delete_outline), label: const Text('Supprimer la facture')),
            ]),
          ),
        ),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.invoices)),
      body: FutureBuilder<List<InvoiceModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Impossible de charger les factures.\n${snapshot.error}')));
          final invoices = snapshot.data ?? const <InvoiceModel>[];
          if (invoices.isEmpty) return const Center(child: Text('Aucune facture.\nCréez votre première facture.', textAlign: TextAlign.center));
          return RefreshIndicator(
            onRefresh: () async { setState(() => _future = _repository.list()); await _future; },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: invoices.length,
              separatorBuilder: (_, i) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final invoice = invoices[i];
                return Card(child: ListTile(onTap: () => _openDetails(invoice), leading: const CircleAvatar(child: Icon(Icons.receipt_long)), title: Text(invoice.invoiceNumber), subtitle: Text('${invoice.status} • ${invoice.date.day.toString().padLeft(2, '0')}/${invoice.date.month.toString().padLeft(2, '0')}/${invoice.date.year}'), trailing: Text('${invoice.totalTtc.toStringAsFixed(2)} DH', style: const TextStyle(fontWeight: FontWeight.bold))));
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _createInvoice, icon: const Icon(Icons.add), label: const Text('Nouvelle facture')),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.bold = false});
  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)), Text('${value.toStringAsFixed(2)} DH', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))]),
      );
}
