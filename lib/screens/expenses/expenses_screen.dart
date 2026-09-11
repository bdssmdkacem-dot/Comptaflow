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
    'Télécom',
    'Loyer',
    'Services',
    'Salaires',
    'Autre',
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
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController supplier = TextEditingController(
      text: expense?.supplierName ?? '',
    );
    final TextEditingController description = TextEditingController(
      text: expense?.description ?? '',
    );
    final TextEditingController amount = TextEditingController(
      text: expense?.amountHt.toStringAsFixed(2) ?? '',
    );
    final TextEditingController tax = TextEditingController(
      text: expense?.taxRate.toStringAsFixed(2) ?? '0',
    );
    final TextEditingController notes = TextEditingController(
      text: expense?.notes ?? '',
    );

    String category = expense?.category ?? _categories.first;
    DateTime date = expense?.date ?? DateTime.now();

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext formContext, StateSetter setDialogState) {
            final double ht =
                double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
            final double tva =
                double.tryParse(tax.text.replaceAll(',', '.')) ?? 0;
            final double tvaAmount = ht * tva / 100;
            final double ttc = ht + tvaAmount;

            return AlertDialog(
              title: Text(
                expense == null
                    ? 'Nouvelle dépense'
                    : 'Modifier la dépense',
              ),
              content: SizedBox(
                width: 560,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          controller: supplier,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Fournisseur',
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Fournisseur requis';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: description,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Description requise';
                            }
                            return null;
                          },
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: const InputDecoration(
                            labelText: 'Catégorie',
                          ),
                          items: _categories
                              .map(
                                (String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setDialogState(() {
                                category = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: amount,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                onChanged: (_) => setDialogState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Montant HT (DH)',
                                ),
                                validator: (String? value) {
                                  final double? parsed = double.tryParse(
                                    (value ?? '').replaceAll(',', '.'),
                                  );
                                  if (parsed == null || parsed < 0) {
                                    return 'Montant invalide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: tax,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                onChanged: (_) => setDialogState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'TVA %',
                                ),
                                validator: (String? value) {
                                  final double? parsed = double.tryParse(
                                    (value ?? '').replaceAll(',', '.'),
                                  );
                                  if (parsed == null ||
                                      parsed < 0 ||
                                      parsed > 100) {
                                    return 'TVA invalide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today_outlined),
                          title: const Text('Date'),
                          subtitle: Text(_formatDate(date)),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: formContext,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDate: date,
                            );
                            if (picked != null) {
                              setDialogState(() {
                                date = picked;
                              });
                            }
                          },
                        ),
                        TextFormField(
                          controller: notes,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optionnel)',
                          ),
                        ),
                        const Divider(height: 24),
                        _AmountRow(label: 'HT', value: ht),
                        _AmountRow(label: 'TVA', value: tvaAmount),
                        _AmountRow(label: 'TTC', value: ttc, bold: true),
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    try {
                      final double parsedAmount = double.parse(
                        amount.text.replaceAll(',', '.'),
                      );
                      final double parsedTax = double.parse(
                        tax.text.replaceAll(',', '.'),
                      );

                      if (expense == null) {
                        await _repository.create(
                          supplierName: supplier.text,
                          description: description.text,
                          category: category,
                          amountHt: parsedAmount,
                          taxRate: parsedTax,
                          date: date,
                          notes: notes.text,
                        );
                      } else {
                        await _repository.update(
                          expense.id,
                          supplierName: supplier.text,
                          description: description.text,
                          category: category,
                          amountHt: parsedAmount,
                          taxRate: parsedTax,
                          date: date,
                          notes: notes.text,
                        );
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (error) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Erreur : $error')),
                        );
                      }
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    supplier.dispose();
    description.dispose();
    amount.dispose();
    tax.dispose();
    notes.dispose();

    if (saved == true && mounted) {
      setState(() {
        _future = _repository.list();
      });
    }
  }

  Future<void> _delete(ExpenseModel expense) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer ?'),
          content: Text(
            'Supprimer la dépense « ${expense.description} » ?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.delete(expense.id);
      if (mounted) {
        await _reload();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses'),
      ),
      body: FutureBuilder<List<ExpenseModel>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<ExpenseModel>> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Impossible de charger les dépenses.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<ExpenseModel> expenses =
              snapshot.data ?? const <ExpenseModel>[];
          final double total = expenses.fold<double>(
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
              separatorBuilder: (_, __) => const SizedBox(height: 8),
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

                final ExpenseModel expense = expenses[index - 1];
                return Card(
                  child: ListTile(
                    onTap: () => _openForm(expense: expense),
                    leading: const CircleAvatar(
                      child: Icon(Icons.shopping_cart_outlined),
                    ),
                    title: Text(expense.description),
                    subtitle: Text(
                      '${expense.supplierName} • ${expense.category} • ${_formatDate(expense.date)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '${expense.totalTtc.toStringAsFixed(2)} DH',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (String value) {
                            if (value == 'delete') {
                              _delete(expense);
                            }
                          },
                          itemBuilder: (_) => const <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Supprimer'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une dépense'),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: style),
          Text('${value.toStringAsFixed(2)} DH', style: style),
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
          children: <Widget>[
            const Icon(Icons.receipt_long_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Aucune dépense enregistrée.',
              textAlign: TextAlign.center,
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
