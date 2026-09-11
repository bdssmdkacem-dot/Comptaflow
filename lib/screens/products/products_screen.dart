import 'package:flutter/material.dart';

import '../../data/models/product.dart';
import '../../data/repositories/product_repo.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _repository = const ProductRepository();
  final _search = TextEditingController();
  late Future<List<ProductModel>> _future;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _repository.list(search: _search.text, activeOnly: !_showArchived);
  }

  Future<void> _reload() async {
    setState(_load);
    await _future;
  }

  Future<void> _openEditor({ProductModel? product}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _ProductDialog(repository: _repository, product: product),
    );
    if (result == true && mounted) setState(_load);
  }

  Future<void> _stock(ProductModel product) async {
    if (!product.stockManaged) return;
    final quantity = TextEditingController();
    final note = TextEditingController();
    var increase = true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Stock — ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock actuel: ${product.stockQuantity.toStringAsFixed(2)} ${product.unit}'),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Entrée'), icon: Icon(Icons.add)),
                  ButtonSegment(value: false, label: Text('Sortie'), icon: Icon(Icons.remove)),
                ],
                selected: {increase},
                onSelectionChanged: (value) => setDialogState(() => increase = value.first),
              ),
              TextField(
                controller: quantity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantité'),
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note (optionnel)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final q = double.tryParse(quantity.text.replaceAll(',', '.'));
                if (q == null || q <= 0) return;
                try {
                  await _repository.adjustStock(
                    productId: product.id,
                    quantity: q,
                    increase: increase,
                    note: note.text.trim().isEmpty ? null : note.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(context, true);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur : $error')),
                    );
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    quantity.dispose();
    note.dispose();
    if (result == true && mounted) setState(_load);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Produits & services'),
          actions: [
            IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
            IconButton(
              onPressed: () => setState(() {
                _showArchived = !_showArchived;
                _load();
              }),
              icon: Icon(_showArchived ? Icons.inventory_2 : Icons.archive_outlined),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(_load),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Nom ou référence',
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(_load);
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ProductModel>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur : ${snapshot.error}'));
                  }
                  final products = snapshot.data ?? const <ProductModel>[];
                  if (products.isEmpty) {
                    return Center(
                      child: Text(
                        _showArchived
                            ? 'Aucun produit archivé.'
                            : 'Aucun produit ou service.',
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final product = products[index];
                        return Card(
                          child: ListTile(
                            onTap: () => _openEditor(product: product),
                            leading: CircleAvatar(
                              child: Icon(
                                product.isService
                                    ? Icons.design_services
                                    : Icons.inventory_2,
                              ),
                            ),
                            title: Text(product.name),
                            subtitle: Text(
                              '${product.reference == null ? product.type : '${product.type} • ${product.reference}'}\n'
                              '${product.taxRate.toStringAsFixed(0)}% TVA • ${product.unitPrice.toStringAsFixed(2)} MAD HT'
                              '${product.stockManaged ? ' • Stock ${product.stockQuantity.toStringAsFixed(2)}' : ''}',
                            ),
                            isThreeLine: true,
                            trailing: product.stockManaged
                                ? IconButton(
                                    tooltip: 'Stock',
                                    onPressed: () => _stock(product),
                                    icon: Icon(
                                      product.lowStock
                                          ? Icons.warning_amber
                                          : Icons.swap_vert,
                                    ),
                                  )
                                : const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({required this.repository, this.product});
  final ProductRepository repository;
  final ProductModel? product;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final TextEditingController name,
      reference,
      description,
      unit,
      salePrice,
      purchasePrice,
      taxRate,
      minStock,
      initialStock;
  late String type;
  late bool stockManaged, active;
  final formKey = GlobalKey<FormState>();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    name = TextEditingController(text: p?.name ?? '');
    reference = TextEditingController(text: p?.reference ?? '');
    description = TextEditingController(text: p?.description ?? '');
    unit = TextEditingController(text: p?.unit ?? 'unit');
    salePrice = TextEditingController(text: p?.unitPrice.toString() ?? '0');
    purchasePrice = TextEditingController(text: p?.purchasePrice.toString() ?? '0');
    taxRate = TextEditingController(text: p?.taxRate.toString() ?? '20');
    minStock = TextEditingController(text: p?.minStock.toString() ?? '0');
    initialStock = TextEditingController(text: p?.stockQuantity.toString() ?? '0');
    type = p?.type ?? 'product';
    stockManaged = p?.stockManaged ?? false;
    active = p?.active ?? true;
  }

  double number(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? -1;

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final sale = number(salePrice);
      final purchase = number(purchasePrice);
      final tax = number(taxRate);
      final min = number(minStock);
      final stock = number(initialStock);
      if (widget.product == null) {
        await widget.repository.create(
          name: name.text.trim(),
          unitPrice: sale,
          description: description.text.trim().isEmpty
              ? null
              : description.text.trim(),
          reference: reference.text.trim().isEmpty
              ? null
              : reference.text.trim(),
          type: type,
          unit: unit.text.trim().isEmpty ? 'unit' : unit.text.trim(),
          purchasePrice: purchase,
          taxRate: tax,
          stockManaged: stockManaged,
          stockQuantity: stock,
          minStock: min,
        );
      } else {
        await widget.repository.update(
          id: widget.product!.id,
          name: name.text.trim(),
          unitPrice: sale,
          description: description.text.trim().isEmpty
              ? null
              : description.text.trim(),
          reference: reference.text.trim().isEmpty
              ? null
              : reference.text.trim(),
          type: type,
          unit: unit.text.trim().isEmpty ? 'unit' : unit.text.trim(),
          purchasePrice: purchase,
          taxRate: tax,
          stockManaged: stockManaged,
          minStock: min,
          active: active,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      name,
      reference,
      description,
      unit,
      salePrice,
      purchasePrice,
      taxRate,
      minStock,
      initialStock,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
          widget.product == null
              ? 'Nouveau produit / service'
              : 'Modifier ${widget.product!.name}',
        ),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'product',
                        label: Text('Produit'),
                        icon: Icon(Icons.inventory_2),
                      ),
                      ButtonSegment(
                        value: 'service',
                        label: Text('Service'),
                        icon: Icon(Icons.design_services),
                      ),
                    ],
                    selected: {type},
                    onSelectionChanged: (v) => setState(() {
                      type = v.first;
                      if (type == 'service') stockManaged = false;
                    }),
                  ),
                  const SizedBox(height: 12),
                  _field(name, 'Nom', requiredField: true),
                  Row(
                    children: [
                      Expanded(child: _field(reference, 'Référence / SKU')),
                      const SizedBox(width: 8),
                      Expanded(child: _field(unit, 'Unité')),
                    ],
                  ),
                  _field(description, 'Description'),
                  Row(
                    children: [
                      Expanded(child: _numberField(salePrice, 'Prix vente HT')),
                      const SizedBox(width: 8),
                      Expanded(child: _numberField(purchasePrice, 'Prix achat HT')),
                    ],
                  ),
                  _numberField(
                    taxRate,
                    'TVA %',
                    validator: (v) {
                      final n = number(taxRate);
                      return n < 0 || n > 100 ? 'TVA invalide' : null;
                    },
                  ),
                  if (type == 'product') ...[
                    SwitchListTile(
                      title: const Text('Gérer le stock'),
                      value: stockManaged,
                      onChanged: (v) => setState(() => stockManaged = v),
                    ),
                    if (stockManaged)
                      Row(
                        children: [
                          Expanded(
                            child: _numberField(
                              initialStock,
                              widget.product == null
                                  ? 'Stock initial'
                                  : 'Stock actuel',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: _numberField(minStock, 'Stock minimum')),
                        ],
                      ),
                  ],
                  if (widget.product != null)
                    SwitchListTile(
                      title: const Text('Produit actif'),
                      value: active,
                      onChanged: (v) => setState(() => active = v),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: saving ? null : save,
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      );

  Widget _field(TextEditingController c, String label, {bool requiredField = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: c,
          validator: requiredField
              ? (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null
              : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  Widget _numberField(
    TextEditingController c,
    String label, {
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: validator ?? (v) => number(c) < 0 ? 'Valeur invalide' : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}
