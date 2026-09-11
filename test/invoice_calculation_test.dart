import 'package:flutter_test/flutter_test.dart';

import 'package:comptaflow/data/models/invoice.dart';
import 'package:comptaflow/data/repositories/invoice_repo.dart';

void main() {
  group('InvoiceLineInput', () {
    test('calculates HT, TVA and TTC', () {
      const line = InvoiceLineInput(
        description: 'Consulting',
        quantity: 3,
        unitPrice: 100,
        taxRate: 20,
      );

      expect(line.totalHt, 300);
      expect(line.totalTva, 60);
      expect(line.totalTtc, 360);
    });

    test('supports zero tax and decimal quantities', () {
      const line = InvoiceLineInput(
        description: 'Service',
        quantity: 1.5,
        unitPrice: 250.5,
        taxRate: 0,
      );

      expect(line.totalHt, 375.75);
      expect(line.totalTva, 0);
      expect(line.totalTtc, 375.75);
    });
  });

  test('InvoiceDetails calculates totals from immutable line values', () {
    const invoice = InvoiceModel(
      id: 'i1',
      userId: 'u1',
      invoiceNumber: 'F-001',
      date: DateTime(2026, 9, 12),
      totalHt: 0,
      totalTva: 0,
      totalTtc: 0,
      status: 'draft',
    );
    const details = InvoiceDetails(
      invoice: invoice,
      items: [
        InvoiceItemModel(
          id: 'l1',
          invoiceId: 'i1',
          description: 'A',
          quantity: 2,
          unitPrice: 100,
          taxRate: 20,
        ),
        InvoiceItemModel(
          id: 'l2',
          invoiceId: 'i1',
          description: 'B',
          quantity: 1,
          unitPrice: 50,
          taxRate: 0,
        ),
      ],
    );

    expect(details.totalHt, 250);
    expect(details.totalTva, 40);
    expect(details.totalTtc, 290);
  });
}
