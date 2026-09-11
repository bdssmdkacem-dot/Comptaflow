import 'dart:typed_data';

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

  Future<void> _createInvoice() async {
    try {
      final clients = await ClientRepository().list();
      final products = await ProductRepository().list();
      if (!mounted) return;
      final result = await _invoiceDialog(clients: clients, products: products);
      if (result != null && mounted) setState(() => _future = _repository.list());
    } catch (error) {
      if (mounted) _showError('Erreur : $error');
    }
  }

  Future<void> _editDraft(InvoiceModel invoice) async {
    if (invoice.status != 'draft') return;
    try {
      final details = await _repository.getDetails(invoice.id);
      final clients = await ClientRepository().list();
      final products = await ProductRepository().list();
      if (!mounted) return;
      final result = await _invoiceDialog(
        invoice: invoice,
        details: details,
        clients: clients,
        products: products,
      );
      if (result != null && mounted) setState(() => _future = _repository.list());
    } catch (error) {
      if (mounted) _showError('Erreur : $error');
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _repository.list());
  }

  Future<void> _showInvoice(InvoiceModel invoice) async {
    try {
      final details = await _repository.getDetails(invoice.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _InvoiceDetailsSheet(
          invoice: invoice,
          details: details,
          onEdit: invoice.status == 'draft' ? () => _editDraft(invoice) : null,
          onDelete: invoice.status == 'draft' ? () => _deleteDraft(invoice) : null,
          onIssue: invoice.status == 'draft' ? () => _issueDraft(invoice) : null,
          onPreview: () => _previewPdf(invoice, details),
          onShare: () => _sharePdf(invoice, details),
          onPrint: () => _printPdf(invoice, details),
        ),
      );
    } catch (error) {
      if (mounted) _showError('Erreur : $error');
    }
  }

  Future<void> _issueDraft(InvoiceModel invoice) async {
    try {
      await _repository.issue(invoice.id);
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _future = _repository.list());
      }
    } catch (error) {
      if (mounted) _showError('Impossible d’émettre la facture : $error');
    }
  }

  Future<void> _deleteDraft(InvoiceModel invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la facture ?'),
        content: Text('La facture ${invoice.invoiceNumber} sera supprimée définitivement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.delete(invoice.id);
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _future = _repository.list());
      }
    } catch (error) {
      if (mounted) _showError('Impossible de supprimer la facture : $error');
    }
  }

  Future<void> _previewPdf(InvoiceModel invoice, InvoiceDetails details) async {
    try {
      final bytes = await _pdfService.build(invoice: invoice, details: details);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: SizedBox(
            width: 900,
            height: 700,
            child: PdfPreview(
              build: (format) async => bytes,
              allowPrinting: false,
              allowSharing: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showError('Erreur PDF : $error');
    }
  }

  Future<void> _sharePdf(InvoiceModel invoice, InvoiceDetails details) async {
    try {
      final bytes = await _pdfService.build(invoice: invoice, details: details);
      await Printing.sharePdf(bytes: bytes, filename: '${invoice.invoiceNumber}.pdf');
    } catch (error) {
      if (mounted) _showError('Erreur PDF : $error');
    }
  }

  Future<void> _printPdf(InvoiceModel invoice, InvoiceDetails details) async {
    try {
      final bytes = await _pdfService.build(invoice: invoice, details: details);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (error) {
      if (mounted) _showError('Erreur impression : $error');
    }
  }

  Future<bool?> _invoiceDialog({
    InvoiceModel? invoice,
    InvoiceDetails? details,
    required List<ClientModel> clients,
    required List<ProductModel> products,
  }) async {
    final editing = invoice != null;
    final number = TextEditingController(text: editing ? invoice.invoiceNumber : '');
    final selectedClientId = ValueNotifier<String?>(editing ? invoice.clientId : null);
    final lines = <_InvoiceDraftLine>[];

    if (details != null) {
      for (final item in details.items) {
        final line = _InvoiceDraftLine();
        line.description.text = item.description;
        line.quantity.text = item.quantity.toString();
        line.price.text = item.unitPrice.toStringAsFixed(2);
        line.tax.text = item.taxRate.toStringAsFixed(2);
        lines.add(line);
      }
    }
    if (lines.isEmpty) lines.add(_InvoiceDraftLine());

    try {
      return await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            double totalHt() => lines.fold(0, (sum, line) => sum + line.ht);
            double totalTva() => lines.fold(0, (sum, line) => sum + line.tva);

            return AlertDialog(
              title: Text(editing ? 'Modifier la facture' : 'Nouvelle facture'),
              content: SizedBox(
                width: 900,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: number,
                        readOnly: editing,
                        decoration: InputDecoration(
                          labelText: 'N° facture',
                          hintText: editing ? null : 'Laisser vide pour numérotation automatique',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<String?>(
                        valueListenable: selectedClientId,
                        builder: (context, value, _) => DropdownButtonFormField<String>(
                          value: value,
                          decoration: const InputDecoration(labelText: 'Client'),
                          items: clients
                              .map((client) => DropdownMenuItem(value: client.id, child: Text(client.name)))
                              .toList(),
                          onChanged: (value) => selectedClientId.value = value,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...lines.asMap().entries.map((entry) {
                        final index = entry.key;
                        final line = entry.value;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text('Ligne ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    if (lines.length > 1)
                                      IconButton(
                                        onPressed: () {
                                          line.dispose();
                                          setDialogState(() => lines.removeAt(index));
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                  ],
                                ),
                                DropdownButtonFormField<ProductModel>(
                                  value: line.product,
                                  decoration: const InputDecoration(labelText: 'Produit / service'),
                                  items: products
                                      .map((product) => DropdownMenuItem(value: product, child: Text(product.name)))
                                      .toList(),
                                  onChanged: (product) {
                                    if (product == null) return;
                                    setDialogState(() => line.useProduct(product));
                                  },
                                ),
                                TextField(controller: line.description, decoration: const InputDecoration(labelText: 'Description')),
                                Row(
                                  children: [
                                    Expanded(child: TextField(controller: line.quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Qté'))),
                                    const SizedBox(width: 8),
                                    Expanded(child: TextField(controller: line.price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Prix HT'))),
                                    const SizedBox(width: 8),
                                    Expanded(child: TextField(controller: line.tax, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'TVA %'))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: () => setDialogState(() => lines.add(_InvoiceDraftLine())),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter une ligne'),
                      ),
                      const Divider(),
                      Text('Total HT : ${totalHt().toStringAsFixed(2)} MAD'),
                      Text('TVA : ${totalTva().toStringAsFixed(2)} MAD'),
                      Text('Total TTC : ${(totalHt() + totalTva()).toStringAsFixed(2)} MAD', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                FilledButton(
                  onPressed: () async {
                    try {
                      if (selectedClientId.value == null) throw Exception('Sélectionnez un client.');
                      final inputs = lines
                          .map((line) => InvoiceItemInput(
                                description: line.description.text.trim(),
                                quantity: line.q,
                                unitPrice: line.p,
                                taxRate: line.t,
                              ))
                          .toList();
                      if (inputs.any((item) => item.description.isEmpty || item.quantity <= 0 || item.unitPrice < 0 || item.taxRate < 0 || item.taxRate > 100)) {
                        throw Exception('Vérifiez les lignes de facture.');
                      }

                      if (editing) {
                        await _repository.updateDraft(
                          invoice!.id,
                          invoiceNumber: number.text.trim(),
                          clientId: selectedClientId.value!,
                          date: invoice.date,
                          items: inputs,
                        );
                      } else {
                        await _repository.create(
                          invoiceNumber: number.text.trim(),
                          clientId: selectedClientId.value!,
                          date: DateTime.now(),
                          items: inputs,
                        );
                      }
                      if (context.mounted) Navigator.pop(context, true);
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error')));
                      }
                    }
                  },
                  child: Text(editing ? 'Enregistrer' : 'Créer'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      number.dispose();
      selectedClientId.dispose();
      for (final line in lines) {
        line.dispose();
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invoices),
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createInvoice,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle facture'),
      ),
      body: FutureBuilder<List<InvoiceModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Erreur : ${snapshot.error}'));
          final invoices = snapshot.data ?? [];
          if (invoices.isEmpty) return const Center(child: Text('Aucune facture.'));
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return Card(
                  child: ListTile(
                    onTap: () => _showInvoice(invoice),
                    title: Text(invoice.invoiceNumber),
                    subtitle: Text('${invoice.status} • ${invoice.totalTtc.toStringAsFixed(2)} MAD'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceDetailsSheet extends StatelessWidget {
  const _InvoiceDetailsSheet({
    required this.invoice,
    required this.details,
    this.onEdit,
    this.onDelete,
    this.onIssue,
    required this.onPreview,
    required this.onShare,
    required this.onPrint,
  });

  final InvoiceModel invoice;
  final InvoiceDetails details;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onIssue;
  final VoidCallback onPreview;
  final VoidCallback onShare;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(invoice.invoiceNumber, style: Theme.of(context).textTheme.headlineSmall),
              Text('Statut : ${invoice.status}'),
              const SizedBox(height: 12),
              ...details.items.map((item) => ListTile(
                    title: Text(item.description),
                    subtitle: Text('${item.quantity} × ${item.unitPrice.toStringAsFixed(2)} MAD • TVA ${item.taxRate}%'),
                    trailing: Text('${item.totalTtc.toStringAsFixed(2)} MAD'),
                  )),
              const Divider(),
              Text('Total HT : ${details.totalHt.toStringAsFixed(2)} MAD'),
              Text('TVA : ${details.totalTva.toStringAsFixed(2)} MAD'),
              Text('Total TTC : ${details.totalTtc.toStringAsFixed(2)} MAD', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (onEdit != null) FilledButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit), label: const Text('Modifier la facture')),
              if (onIssue != null) FilledButton.icon(onPressed: onIssue, icon: const Icon(Icons.check_circle_outline), label: const Text('Émettre')),
              if (onDelete != null) OutlinedButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline), label: const Text('Supprimer')),
              OutlinedButton.icon(onPressed: onPreview, icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('Aperçu PDF')),
              OutlinedButton.icon(onPressed: onShare, icon: const Icon(Icons.share_outlined), label: const Text('Partager PDF')),
              OutlinedButton.icon(onPressed: onPrint, icon: const Icon(Icons.print_outlined), label: const Text('Imprimer')),
            ],
          ),
        ),
      ),
    );
  }
}
