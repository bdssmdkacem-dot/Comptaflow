import 'package:flutter_test/flutter_test.dart';

import 'package:comptaflow/data/models/invoice.dart';

afterTest(InvoiceModel invoice, String expected) {
  expect(invoice.canonicalStatus.name, expected);
}

InvoiceModel _invoice(String status) => InvoiceModel(
      id: 'invoice-1',
      userId: 'user-1',
      invoiceNumber: 'FAC-0001',
      date: DateTime(2026, 9, 12),
      totalHt: 100,
      totalTva: 20,
      totalTtc: 120,
      status: status,
    );

void main() {
  test('maps all persisted invoice statuses to canonical statuses', () {
    afterTest(_invoice('draft'), 'draft');
    afterTest(_invoice('issued'), 'issued');
    afterTest(_invoice('paid'), 'paid');
    afterTest(_invoice('cancelled'), 'cancelled');
  });

  test('unknown status safely falls back to draft', () {
    expect(_invoice('unexpected').canonicalStatus.name, 'draft');
  });

  test('invoice item totals are calculated from quantity, price and TVA', () {
    const item = InvoiceItemModel(
      id: 'item-1',
      invoiceId: 'invoice-1',
      description: 'Service',
      quantity: 2.5,
      unitPrice: 100,
      taxRate: 20,
    );

    expect(item.totalHt, 250);
    expect(item.totalTva, 50);
    expect(item.totalTtc, 300);
  });
}
