import 'package:flutter_test/flutter_test.dart';

import 'package:comptaflow/core/utils/expense_analytics.dart';
import 'package:comptaflow/data/models/expense.dart';

ExpenseModel _expense({
  required String id,
  required String category,
  required double amountHt,
  required double taxRate,
  required DateTime date,
}) {
  return ExpenseModel(
    id: id,
    userId: 'user-1',
    supplierName: 'Supplier $id',
    description: 'Expense $id',
    category: category,
    amountHt: amountHt,
    taxRate: taxRate,
    date: date,
  );
}

void main() {
  final expenses = [
    _expense(
      id: '1',
      category: 'Achats',
      amountHt: 100,
      taxRate: 20,
      date: DateTime(2026, 9, 10, 10),
    ),
    _expense(
      id: '2',
      category: 'Transport',
      amountHt: 50,
      taxRate: 10,
      date: DateTime(2026, 9, 11, 15),
    ),
    _expense(
      id: '3',
      category: 'Achats',
      amountHt: 25,
      taxRate: 0,
      date: DateTime(2026, 8, 31, 23),
    ),
  ];

  test('filters by inclusive date range and category', () {
    final result = ExpenseAnalytics.filter(
      expenses: expenses,
      from: DateTime(2026, 9, 10),
      to: DateTime(2026, 9, 11),
      category: 'Achats',
    );

    expect(result.map((e) => e.id), ['1']);
  });

  test('date boundaries are inclusive for whole days', () {
    final result = ExpenseAnalytics.filter(
      expenses: expenses,
      from: DateTime(2026, 9, 11),
      to: DateTime(2026, 9, 11),
    );

    expect(result.map((e) => e.id), ['2']);
  });

  test('calculates HT, TVA and TTC totals', () {
    expect(ExpenseAnalytics.totalHt(expenses), 175);
    expect(ExpenseAnalytics.totalTva(expenses), 25);
    expect(ExpenseAnalytics.totalTtc(expenses), 200);
  });

  test('groups TTC totals by category', () {
    expect(
      ExpenseAnalytics.totalsByCategory(expenses),
      {'Achats': 145, 'Transport': 55},
    );
  });

  test('Toutes category returns every expense', () {
    final result = ExpenseAnalytics.filter(
      expenses: expenses,
      category: 'Toutes',
    );

    expect(result.length, 3);
  });
}
