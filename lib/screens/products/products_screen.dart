import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/product.dart';
import '../../data/repositories/product_repo.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _repository = const ProductRepository();
  late Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.list();
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final price = TextEditingController();
    final description = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Produit / service'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Nom'), validator: (v) => v == null || v.trim().isEmpty ? 'Nom requis' : null),
            TextFormField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Prix unitaire (DH)'), validator: (v) => double.tryParse((v ?? '').replaceAll(',', '.')) == null ? 'Prix invalide' : null),
            TextFormField(controller: description, decoration: const InputDecoration(labelText: 'Description (optionnel)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            await _repository.create(name: name.text.trim(), unitPrice: double.parse(price.text.replaceAll(',', '.')), description: description.text.trim().isEmpty ? null : description.text.trim());
            if (context.mounted) Navigator.pop(context, true);
          }, child: const Text('Enregistrer')),
        ],
      ),
    );
    name.dispose();
    price.dispose();
    description.dispose();
    if (created == true && mounted) setState(() => _future = _repository.list());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Produits & services')),
        body: FutureBuilder<List<ProductModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Impossible de charger les produits.\n${snapshot.error}')));
            final products = snapshot.data ?? const [];
            if (products.isEmpty) return const Center(child: Text('Aucun produit ou service.\nAjoutez votre premier élément.'));
            return RefreshIndicator(onRefresh: () async => setState(() => _future = _repository.list()), child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: products.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, index) { final p = products[index]; return Card(child: ListTile(title: Text(p.name), subtitle: p.description == null ? null : Text(p.description!), trailing: Text('${p.unitPrice.toStringAsFixed(2)} DH')); }));
          },
        ),
        floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Ajouter')),
      );
}
