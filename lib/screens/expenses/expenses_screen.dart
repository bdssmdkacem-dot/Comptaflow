import 'package:flutter/material.dart';

import '../../data/models/expense.dart';
import '../../data/repositories/expense_repo.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpenseRepository _repository = ExpenseRepository();
  late Future<List<ExpenseModel>> _future;

  static const List<String> _categories = <String>[
    'Achats',
    'Transport',
    'Loyer',
    'Salaires',
    'Services',
    'Télécommunications',
    'Autres',
  ];

  @override
  void initState() {
    super.initState();
    _future = _repository.list();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _repository.list();
    });
    await _future;
  }

  Future<void> _openForm({ExpenseModel? expense}) async {
    final supplierController = TextEditingController(
      text: expense?.supplierName ?? '',
    );
    final descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );
    final amountController = TextEditingController(
      text: expense?.amountHt.toStringAsFixed(2) ?? '',
    );
    final taxController = TextEditingController(
      text: expense?.taxRate.toStringAsFixed(2) ?? '20',
    );
    final notesController = TextEditingController(text: expense?.notes ?? '');

    String category = expense?.category ?? _categories.first;
    DateTime date = expense?.expenseDate ?? DateTime.now();
    String? error;

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final amount = double.tryParse(amountController.text) ?? 0;
              final tax = double.tryParse(taxController.text) ?? 0;
              final tva = amount * tax / 100;
              final ttc = amount + tva;

              return AlertDialog(
                title: Text(
                  expense == null ? 'Nouvelle dépense' : 'Modifier la dépense',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: supplierController,
                        decoration: const InputDecoration(
                          labelText: 'Fournisseur *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                        ),
                        items: _categories
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Montant HT *',
                                suffixText: 'DH',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: taxController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) => setDialogState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'TVA',
                                suffixText: '%',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('Date'),
                        subtitle: Text(
                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDate: date,
                          );
                          if (picked != null) {
                            setDialogState(() => date = picked);
                          }
                        },
                      ),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Notes'),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _AmountRow(label: 'TVA', value: tva),
                      _AmountRow(label: 'Total TTC', value: ttc),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Annuler'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text);
                      final tax = double.tryParse(taxController.text);
                      if (supplierController.text.trim().isEmpty ||
                          descriptionController.text.trim().isEmpty) {
                        setDialogState(
                          () => error = 'Veuillez remplir les champs obligatoires.',
                        );
                        return;
                      }
                      if (amount == null ||
                          tax == null ||
                          amount < 0 ||
                          tax < 0 ||
                          tax > 100) {
                        setDialogState(() => error = 'Montant ou TVA invalide.');
                        return;
                      }

                      try {
                        if (expense == null) {
                          await _repository.create(
                            supplierName: supplierController.text,
                            description: descriptionController.text,
                            category: category,
                            amountHt: amount,
                            taxRate: tax,
                            date: date,
                            notes: notesController.text,
                          );
                        } else {
                          await _repository.update(
                            expense.id,
                            supplierName: supplierController.text,
                            description: descriptionController.text,
                            category: category,
                            amountHt: amount,
                            taxRate: tax,
                            date: date,
                            notes: notesController.text,
                          );
                        }
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop(true);
                        }
                      } catch (e) {
                        setDialogState(() => error = e.toString());
                      }
                    },
                    child: Text(expense == null ? 'Ajouter' : 'Enregistrer'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (saved == true && mounted) {
        await _reload();
      }
    } finally {
      supplierController.dispose();
      descriptionController.dispose();
      amountController.dispose();
      taxController.dispose();
      notesController.dispose();
    }
  }

  Future<void> _delete(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la dépense ?'),
        content: Text('Cette action supprimera « ${expense.description} ». '),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repository.delete(expense.id);
      if (mounted) await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression impossible : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Dépense'),
      ),
      body: FutureBuilder<List<ExpenseModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text('Impossible de charger les dépenses : ${snapshot.error}'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final expenses = snapshot.data ?? <ExpenseModel>[];
          final total = expenses.fold<double>(
            0,
            (double sum, ExpenseModel item) => sum + item.totalTtc,
          );

          if (expenses.isEmpty) {
            return _EmptyExpenses(onAdd: _openForm);
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: expenses.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.payments_outlined),
                      title: const Text('Total dépenses'),
                      trailing: Text(
                        '${total.toStringAsFixed(2)} DH',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }

                final expense = expenses[index - 1];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt_long_outlined),
                    ),
                    title: Text(expense.description),
                    subtitle: Text(
                      '${expense.supplierName} · ${expense.category}\n'
                      '${expense.amountHt.toStringAsFixed(2)} DH HT · '
                      '${expense.totalTtc.toStringAsFixed(2)} DH TTC',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openForm(expense: expense);
                        } else if (value == 'delete') {
                          _delete(expense);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Modifier')),
                        PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                      ],
                    ),
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

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${value.toStringAsFixed(2)} DH',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Aucune dépense',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez votre première dépense pour commencer le suivi.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une dépense'),
            ),
          ],
        ),
      ),
    );
  }
}
