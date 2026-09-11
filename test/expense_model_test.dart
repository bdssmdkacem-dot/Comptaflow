import 'package:flutter_test/flutter_test.dart';

import 'package:comptaflow/data/models/expense.dart';

void main() {
  group('ExpenseModel', () {
    test('calculates TVA and TTC from HT and rate', () {
      final expense = ExpenseModel(
        id: '1',
        userId: 'user',
        supplierName: 'Supplier',
        description: 'Office supplies',
        category: 'Achats',
        amountHt: 100,
        taxRate: 20,
        date: DateTime(2026, 9, 1),
      );

      expect(expense.taxAmount, 20);
      expect(expense.totalTtc, 120);
    });

    test('supports zero TVA', () {
      final expense = ExpenseModel(
        id: '1',
        userId: 'user',
        supplierName: 'Supplier',
        description: 'Service',
        category: 'Services',
        amountHt: 250.5,
        taxRate: 0,
        date: DateTime(2026, 9, 1),
      );

      expect(expense.taxAmount, 0);
      expect(expense.totalTtc, 250.5);
    });

    test('fromMap preserves nullable notes and expense date', () {
      final expense = ExpenseModel.fromMap({
        'id': '1',
        'user_id': 'user',
        'supplier_name': 'Supplier',
        'description': 'Service',
        'category': 'Services',
        'amount_ht': 100,
        'tax_rate': 20,
        'expense_date': '2026-09-11',
        'notes': null,
      });

      expect(expense.notes, isNull);
      expect(expense.expenseDate, DateTime(2026, 9, 11));
    });
  });
}
