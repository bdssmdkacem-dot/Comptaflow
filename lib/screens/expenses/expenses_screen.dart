import 'package:flutter/material.dart';

import '../../data/models/expense.dart';
import '../../data/repositories/expense_repo.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _repository = ExpenseRepository();
  late Future<List<ExpenseModel>> _future;

  static const _categories = ['Achats', 'Transport', 'Télécom', 'Loyer', 'Services', 'Salaires', 'Autre'];

  @override
  void initState() {
    super.initState();
    _future = _repository.list();
  }

  Future<void> _openForm({ExpenseModel? expense}) async {
    final formKey = GlobalKey<FormState>();
    final supplier = TextEditingController(text: expense?.supplierName ?? '');
    final description = TextEditingController(text: expense?.description ?? '');
    final amount = TextEditingController(text: expense?.amountHt.toStringAsFixed(2) ?? '');
    final tax = TextEditingController(text: expense?.taxRate.toStringAsFixed(2) ?? '0');
    final notes = TextEditingController(text: expense?.notes ?? '');
    var category = expense?.category ?? _categories.first;
    var date = expense?.date ?? DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final ht = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
          final tva = double.tryParse(tax.text.replaceAll(',', '.')) ?? 0;
          final ttc = ht + ht * tva / 100;
          return AlertDialog(
            title: Text(expense == null ? 'Nouvelle dépense' : 'Modifier la dépense'),
            content: SizedBox(
              width: 560,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(controller: supplier, autofocus: true, decoration: const InputDecoration(labelText: 'Fournisseur'), validator: (v) => v == null || v.trim().isEmpty ? 'Fournisseur requis' : null),
                      TextFormField(controller: description, decoration: const InputDecoration(labelText: 'Description'), validator: (v) => v == null || v.trim().isEmpty ? 'Description requise' : null),
                      DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'Catégorie'), items: _categories.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) setDialogState(() => category = v); }),
                      Row(children: [
                        Expanded(child: TextFormField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setDialogState(() {}), decoration: const InputDecoration(labelText: 'Montant HT (DH)'), validator: (v) { final n = double.tryParse((v ?? '').replaceAll(',', '.')); return n == null || n < 0 ? 'Montant invalide' : null; }})),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: tax, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => setDialogState(() {}), decoration: const InputDecoration(labelText: 'TVA %'), validator: (v) { final n = double.tryParse((v ?? '').replaceAll(',', '.')); return n == null || n < 0 || n > 100 ? 'TVA invalide' : null; }})),
                      ]),
                      ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today_outlined), title: const Text('Date'), subtitle: Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'), onTap: () async { final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: date); if (picked != null) setDialogState(() => date = picked); }),
                      TextFormField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (optionnel)')),
                      const Divider(),
                      _AmountRow(label: 'HT', value: ht),
                      _AmountRow(label: 'TVA', value: ht * tva / 100),
                      _AmountRow(label: 'TTC', value: ttc, bold: true),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
              FilledButton(onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final parsedAmount = double.parse(amount.text.replaceAll(',', '.'));
                  final parsedTax = double.parse(tax.text.replaceAll(',', '.'));
                  if (expense == null) {
                    await _repository.create(supplierName: supplier.text, description: description.text, category: category, amountHt: parsedAmount, taxRate: parsedTax, date: date, notes: notes.text);
                  } else {
                    await _repository.update(expense.id, supplierName: supplier.text, description: description.text, category: category, amountHt: parsedAmount, taxRate: parsedTax, date: date, notes: notes.text);
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Erreur : $error')));
                }
              }, child: const Text('Enregistrer')),
            ],
          );
        },
      ),
    );
    supplier.dispose(); description.dispose(); amount.dispose(); tax.dispose(); notes.dispose();
    if (saved == true && mounted) setState(() => _future = _repository.list());
  }

  Future<void> _delete(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Supprimer ?'), content: Text('Supprimer la dépense « ${expense.description} » ?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer'))]));
    if (confirmed == true) {
      try { await _repository.delete(expense.id); if (mounted) setState(() => _future = _repository.list()); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error'))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dépenses')),
      body: FutureBuilder<List<ExpenseModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Impossible de charger les dépenses.\n${snapshot.error}')));
          final expenses = snapshot.data ?? const <ExpenseModel>[];
          final total = expenses.fold<double>(0, (sum, item) => sum + item.totalTtc);
          if (expenses.isEmpty) return _EmptyExpenses(onAdd: () => _openForm());
          return RefreshIndicator(onRefresh: () async { setState(() => _future = _repository.list()); await _future; }, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: expenses.length + 1, separatorBuilder: (_, i) => const SizedBox(height: 8), itemBuilder: (_, i) { if (i == 0) return Card(child: ListTile(leading: const Icon(Icons.payments_outlined), title: const Text('Total dépenses'), trailing: Text('${total.toStringAsFixed(2)} DH', style: const TextStyle(fontWeight: FontWeight.bold)))); final expense = expenses[i - 1]; return Card(child: ListTile(onTap: () => _openForm(expense: expense), leading: const CircleAvatar(child: Icon(Icons.shopping_cart_outlined)), title: Text(expense.description), subtitle: Text('${expense.supplierName} • ${expense.category} • ${expense.date.day.toString().padLeft(2, '0')}/${expense.date.month.toString().padLeft(2, '0')}/${expense.date.year}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('${expense.totalTtc.toStringAsFixed(2)} DH', style: const TextStyle(fontWeight: FontWeight.bold)), PopupMenuButton<String>(onSelected: (v) { if (v == 'delete') _delete(expense); }, itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Supprimer'))])]))); }));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('Ajouter une dépense')),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value, this.bold = false});
  final String label;
  final double value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)), Text('${value.toStringAsFixed(2)} DH', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))]));
}

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.receipt_long_outlined, size: 48), const SizedBox(height: 12), const Text('Aucune dépense enregistrée.', textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Ajouter une dépense'))])));
}
