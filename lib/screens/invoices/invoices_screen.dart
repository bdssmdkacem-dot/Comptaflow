import 'package:flutter/material.dart';

import '../../data/models/invoice.dart';
import '../../data/repositories/client_repo.dart';
import '../../data/repositories/invoice_repo.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repo.dart';
import '../../l10n/app_localizations.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _repository = InvoiceRepository();
  late Future<List<InvoiceModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.list();
  }

  Future<void> _createInvoice() async {
    final clients = await ClientRepository().list();
    final products = await ProductRepository().list();
    if (!mounted) return;

    final number = TextEditingController(
      text: 'FAC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    String? clientId;
    final quantity = TextEditingController(text: '1');
    final price = TextEditingController();
    final description = TextEditingController();
    final tax = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    ProductModel? selectedProduct;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle facture'),
          content: SizedBox(
            width: 480,
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
                    DropdownButtonFormField<String?>(
                      initialValue: clientId,
                      decoration: const InputDecoration(labelText: 'Client'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Client comptant')),
                        ...clients.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (v) => setDialogState(() => clientId = v),
                    ),
                    const SizedBox(height: 8),
                    if (products.isNotEmpty)
                      DropdownButtonFormField<ProductModel>(
                        initialValue: selectedProduct,
                        decoration: const InputDecoration(labelText: 'Produit / service'),
                        items: products.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} — ${p.unitPrice.toStringAsFixed(2)} DH'))).toList(),
                        onChanged: (p) {
                          setDialogState(() {
                            selectedProduct = p;
                            if (p != null) {
                              description.text = p.name;
                              price.text = p.unitPrice.toStringAsFixed(2);
                              tax.text = p.taxRate.toStringAsFixed(2);
                            }
                          });
                        },
                      ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: description,
                      decoration: const InputDecoration(labelText: 'Description'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Description requise' : null,
                    ),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Quantité'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Prix unitaire'))),
                      ],
                    ),
                    TextFormField(controller: tax, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'TVA (%)')),
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
                final q = double.tryParse(quantity.text.replaceAll(',', '.'));
                final p = double.tryParse(price.text.replaceAll(',', '.'));
                final t = double.tryParse(tax.text.replaceAll(',', '.')) ?? 0;
                if (q == null || q <= 0 || p == null || p < 0 || t < 0 || t > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valeurs numériques invalides')));
                  return;
                }
                try {
                  await _repository.create(
                    invoiceNumber: number.text,
                    clientId: clientId,
                    date: DateTime.now(),
                    taxRate: t,
                    items: [InvoiceLineInput(description: description.text, quantity: q, unitPrice: p)],
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Erreur : $error')));
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );

    number.dispose();
    quantity.dispose();
    price.dispose();
    description.dispose();
    tax.dispose();

    if (created == true && mounted) setState(() => _future = _repository.list());
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
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                    title: Text(invoice.invoiceNumber),
                    subtitle: Text('${invoice.status} • ${invoice.date.day.toString().padLeft(2, '0')}/${invoice.date.month.toString().padLeft(2, '0')}/${invoice.date.year}'),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${invoice.totalTtc.toStringAsFixed(2)} DH', style: const TextStyle(fontWeight: FontWeight.bold)), const Text('TTC')]),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _createInvoice, icon: const Icon(Icons.add), label: const Text('Nouvelle facture')),
    );
  }
}
