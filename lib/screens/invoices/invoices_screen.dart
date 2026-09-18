import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/services/document_storage_service.dart';
import '../../core/services/invoice_pdf_service.dart';
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
  final _storageService = const DocumentStorageService();
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
      if (result == true && mounted) setState(() => _future = _repository.list());
    } catch (error) {
      if (mounted) _showError('${AppLocalizations.of(context).errorPrefix} : $error');
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
      if (result == true && mounted) setState(() => _future = _repository.list());
    } catch (error) {
      if (mounted) _showError('${AppLocalizations.of(context).errorPrefix} : $error');
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
        builder: (_) => _InvoiceDetailsSheet(
          invoice: invoice,
          details: details,
          onEdit: invoice.status == 'draft' ? () => _editDraft(invoice) : null,
          onDelete: invoice.status == 'draft' ? () => _deleteDraft(invoice) : null,
          onIssue: invoice.status == 'draft' ? () => _issueDraft(invoice) : null,
          onPreview: () => _previewPdf(invoice, details),
          onShare: () => _sharePdf(invoice, details),
          onPrint: () => _printPdf(invoice, details),
          onSavePdf: () => _savePdf(invoice, details),
        ),
      );
    } catch (error) {
      if (mounted) _showError('${AppLocalizations.of(context).errorPrefix} : $error');
    }
  }

  Future<void> _issueDraft(InvoiceModel invoice) async {
    try {
      await _repository.issue(invoice.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _future = _repository.list());
    } catch (error) {
      if (mounted) _showError('${AppLocalizations.of(context).issueInvoiceError} : $error');
    }
  }

  Future<void> _deleteDraft(InvoiceModel invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteInvoiceTitle),
        content: Text(AppLocalizations.of(context).deleteInvoiceMessage(invoice.invoiceNumber)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context).cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context).delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.delete(invoice.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _future = _repository.list());
    } catch (error) {
      if (mounted) _showError('${AppLocalizations.of(context).deleteInvoiceError} : $error');
    }
  }

  Future<void> _previewPdf(InvoiceModel invoice, InvoiceDetails details) async {
    try {
      final bytes = await _pdfService.build(
        invoice: invoice,
        details: details,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: SizedBox(
            width: 900,
            height: 700,
            child: PdfPreview(
              build: (_) async => bytes,
              allowPrinting: false,
              allowSharing: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showError('${AppLocalizations.of(context).pdfError} : $error');
    }
  }

  Future<void> _sharePdf(InvoiceModel invoice, InvoiceDetails details) async {
    try {
      final bytes = await _pdfService.build(
        invoice: invoice,
        details: details,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      await Printing.sharePdf(bytes: bytes, filename: '${invoice.invoiceNumber}.pdf');
    } catch (error) {
      if (mounted) _showError('${AppLocalizations.of(context).pdfError} : $error');
    }
  }

  Future<void> _savePdf(InvoiceModel invoice, InvoiceDetails details) async {
    try {
      final bytes = await _pdfService.build(
        invoice: invoice,
        details: details,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      final path = await _storageService.uploadInvoicePdf(invoiceId: invoice.id, bytes: bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).savePdfSecure(path))),
      );
    } catch (error) {
      if (mounted) _showError('${AppLocalizations.of(context).savePdfError} : $error');
    }
  }

  Future<void> _printPdf(InvoiceModel invoice, InvoiceDetails details) async {
    try {
      final bytes = await _pdfService.build(
        invoice: invoice,
        details: details,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (error) {
      if (mounted) _showError('${AppLocalizations.of(context).printError} : $error');
    }
  }

  Future<bool?> _invoiceDialog({
    InvoiceModel? invoice,
    InvoiceDetails? details,
    required List<ClientModel> clients,
    required List<ProductModel> products,
  }) async {
    final editing = invoice != null;
    final currentInvoice = invoice;
    final number = TextEditingController(text: currentInvoice?.invoiceNumber ?? '');
    final selectedClientId = ValueNotifier<String?>(currentInvoice?.clientId);
    final lines = <_InvoiceDraftLine>[];

    if (details != null) {
      for (final item in details.items) {
        final line = _InvoiceDraftLine();
        line.product = item.productId == null ? null : products.where((p) => p.id == item.productId).isEmpty ? null : products.firstWhere((p) => p.id == item.productId);
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
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            double totalHt() => lines.fold(0, (sum, line) => sum + line.ht);
            double totalTva() => lines.fold(0, (sum, line) => sum + line.tva);

            return AlertDialog(
              title: Text(editing ? AppLocalizations.of(context).editInvoice : AppLocalizations.of(context).newInvoice),
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
                          labelText: AppLocalizations.of(context).invoiceNumber,
                          hintText: editing ? null : AppLocalizations.of(context).autoInvoiceNumber,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<String?>(
                        valueListenable: selectedClientId,
                        builder: (context, value, _) => DropdownButtonFormField<String>(
                          initialValue: value,
                          decoration: InputDecoration(labelText: AppLocalizations.of(context).client),
                          items: clients
                              .map((client) => DropdownMenuItem(value: client.id, child: Text(client.name)))
                              .toList(),
                          onChanged: (next) => selectedClientId.value = next,
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
                                    Expanded(child: Text(AppLocalizations.of(context).line(index + 1), style: const TextStyle(fontWeight: FontWeight.bold))),
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
                                  initialValue: line.product,
                                  decoration: InputDecoration(labelText: AppLocalizations.of(context).productService),
                                  items: products
                                      .map((product) => DropdownMenuItem(value: product, child: Text(product.name)))
                                      .toList(),
                                  onChanged: (product) {
                                    if (product == null) return;
                                    setDialogState(() => line.useProduct(product));
                                  },
                                ),
                                TextField(
                                  controller: line.description,
                                  decoration: InputDecoration(labelText: AppLocalizations.of(context).description),
                                ),
                                Row(
                                  children: [
                                    Expanded(child: TextField(controller: line.quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: AppLocalizations.of(context).quantityShort))),
                                    const SizedBox(width: 8),
                                    Expanded(child: TextField(controller: line.price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: AppLocalizations.of(context).unitPriceHt))),
                                    const SizedBox(width: 8),
                                    Expanded(child: TextField(controller: line.tax, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: AppLocalizations.of(context).taxPercent))),
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
                        label: Text(AppLocalizations.of(context).addLine),
                      ),
                      const Divider(),
                      Text('${AppLocalizations.of(context).totalHt} : ${totalHt().toStringAsFixed(2)} MAD'),
                      Text('${AppLocalizations.of(context).totalTva} : ${totalTva().toStringAsFixed(2)} MAD'),
                      Text('${AppLocalizations.of(context).totalTtc} : ${(totalHt() + totalTva()).toStringAsFixed(2)} MAD', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(AppLocalizations.of(context).cancel)),
                FilledButton(
                  onPressed: () async {
                    try {
                      final clientId = selectedClientId.value;
                      if (clientId == null) throw Exception(AppLocalizations.of(context).selectClient);
                      final inputs = lines
                          .map((line) => InvoiceItemInput(
                                description: line.description.text.trim(),
                                quantity: line.q,
                                unitPrice: line.p,
                                taxRate: line.t,
                                productId: line.product?.id,
                              ))
                          .toList();
                      if (inputs.any((item) => item.description.isEmpty || item.quantity <= 0 || item.unitPrice < 0 || item.taxRate < 0 || item.taxRate > 100)) {
                        throw Exception(AppLocalizations.of(context).checkInvoiceLines);
                      }

                      if (editing && currentInvoice != null) {
                        await _repository.updateDraft(
                          currentInvoice.id,
                          invoiceNumber: number.text.trim(),
                          clientId: clientId,
                          date: currentInvoice.date,
                          items: inputs,
                        );
                      } else {
                        await _repository.create(
                          invoiceNumber: number.text.trim(),
                          clientId: clientId,
                          date: DateTime.now(),
                          items: inputs,
                        );
                      }
                      if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                    } catch (error) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context).errorPrefix} : $error')));
                      }
                    }
                  },
                  child: Text(editing ? AppLocalizations.of(context).save : AppLocalizations.of(context).createInvoice),
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
        label: Text(AppLocalizations.of(context).newInvoice),
      ),
      body: FutureBuilder<List<InvoiceModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('${AppLocalizations.of(context).errorPrefix} : ${snapshot.error}'));
          final invoices = snapshot.data ?? [];
          if (invoices.isEmpty) return Center(child: Text(AppLocalizations.of(context).noInvoices));
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

String _statusLabel(BuildContext context, String status) { final l10n = AppLocalizations.of(context); switch(status){case 'draft': return l10n.statusDraft; case 'issued': return l10n.statusIssued; case 'paid': return l10n.statusPaid; case 'cancelled': return l10n.statusCancelled; default: return l10n.invoiceStatusUnknown;} }

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
    required this.onSavePdf,
  });

  final InvoiceModel invoice;
  final InvoiceDetails details;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onIssue;
  final VoidCallback onPreview;
  final VoidCallback onShare;
  final VoidCallback onPrint;
  final VoidCallback onSavePdf;

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
              Text('${AppLocalizations.of(context).status} : ${_statusLabel(context, invoice.status)}'),
              const SizedBox(height: 12),
              ...details.items.map((item) => ListTile(
                    title: Text(item.description),
                    subtitle: Text('${item.quantity} × ${item.unitPrice.toStringAsFixed(2)} MAD • TVA ${item.taxRate}%'),
                    trailing: Text('${item.totalTtc.toStringAsFixed(2)} MAD'),
                  )),
              const Divider(),
              Text('${AppLocalizations.of(context).totalHt} : ${details.totalHt.toStringAsFixed(2)} MAD'),
              Text('${AppLocalizations.of(context).totalTva} : ${details.totalTva.toStringAsFixed(2)} MAD'),
              Text('${AppLocalizations.of(context).totalTtc} : ${details.totalTtc.toStringAsFixed(2)} MAD', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (onEdit != null) FilledButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit), label: Text(AppLocalizations.of(context).editInvoice)),
              if (onIssue != null) FilledButton.icon(onPressed: onIssue, icon: const Icon(Icons.check_circle_outline), label: Text(AppLocalizations.of(context).issue)),
              if (onDelete != null) OutlinedButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline), label: Text(AppLocalizations.of(context).delete)),
              OutlinedButton.icon(onPressed: onPreview, icon: const Icon(Icons.picture_as_pdf_outlined), label: Text(AppLocalizations.of(context).previewPdf)),
              OutlinedButton.icon(onPressed: onShare, icon: const Icon(Icons.share_outlined), label: Text(AppLocalizations.of(context).sharePdf)),
              OutlinedButton.icon(onPressed: onPrint, icon: const Icon(Icons.print_outlined), label: Text(AppLocalizations.of(context).print)),
              OutlinedButton.icon(onPressed: onSavePdf, icon: const Icon(Icons.cloud_upload_outlined), label: Text(AppLocalizations.of(context).savePdf)),
            ],
          ),
        ),
      ),
    );
  }
}
