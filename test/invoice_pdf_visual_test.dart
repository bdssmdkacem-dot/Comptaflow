import 'dart:io';
import 'dart:typed_data';

import 'package:comptaflow/core/services/invoice_pdf_service.dart';
import 'package:flutter/widgets.dart';
import 'package:comptaflow/data/models/invoice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const service = InvoicePdfService();

  group('Invoice PDF visual smoke cases', () {
    test('Arabic invoice generates non-empty PDF with buyer snapshot', () async {
      final invoice = _invoice(
        number: 'FA-AR-2026-001',
        buyerName: 'شركة النور للتجارة',
        buyerAddress: 'شارع محمد الخامس، أكادير',
        buyerCity: 'أكادير',
        buyerIce: '001234567000089',
        paymentTerms: 'الدفع خلال 30 يومًا من تاريخ الإصدار.',
        status: 'issued',
      );
      final details = InvoiceDetails(invoice: invoice, items: _items(invoice.id, count: 3));
      final bytes = await service.build(invoice: invoice, details: details, languageCode: 'ar');
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(1000));
      expect(_pageCount(bytes), greaterThanOrEqualTo(1));
      await _save('french-invoice.pdf', bytes);
      await _save('arabic-invoice.pdf', bytes);
    });

    test('French invoice generates non-empty PDF with seller and buyer data', () async {
      final invoice = _invoice(
        number: 'FA-FR-2026-002',
        buyerName: 'Atlas Distribution SARL',
        buyerAddress: '12 avenue Mohammed V',
        buyerCity: 'Agadir',
        buyerIce: '002345678000012',
        paymentTerms: 'Paiement à 30 jours date de facture.',
        status: 'paid',
      );
      final details = InvoiceDetails(invoice: invoice, items: _items(invoice.id, count: 4));
      final bytes = await service.build(invoice: invoice, details: details, languageCode: 'fr');
      expect(bytes.length, greaterThan(1000));
      expect(_pageCount(bytes), greaterThanOrEqualTo(1));
    });

    test('long invoice spans multiple A4 pages', () async {
      final invoice = _invoice(
        number: 'FA-LONG-2026-003',
        buyerName: 'Client avec un nom suffisamment long pour tester la mise en page',
        buyerAddress: '25 boulevard Hassan II, quartier administratif',
        buyerCity: 'Casablanca',
        buyerIce: '003456789000034',
        paymentTerms: 'Paiement par virement bancaire dans les 45 jours. Merci de rappeler le numéro de facture lors du règlement.',
        status: 'issued',
      );
      final details = InvoiceDetails(invoice: invoice, items: _items(invoice.id, count: 55));
      final bytes = await service.build(invoice: invoice, details: details, languageCode: 'fr');
      expect(bytes.length, greaterThan(5000));
      expect(_pageCount(bytes), greaterThan(1));
      await _save('long-invoice.pdf', bytes);
    });
  });
}

InvoiceModel _invoice({
  required String number,
  required String buyerName,
  required String buyerAddress,
  required String buyerCity,
  required String buyerIce,
  required String paymentTerms,
  required String status,
}) {
  return InvoiceModel(
    id: 'invoice-$number',
    userId: 'user-visual-test',
    clientId: 'client-visual-test',
    invoiceNumber: number,
    date: DateTime(2026, 9, 18),
    totalHt: 0,
    totalTva: 0,
    totalTtc: 0,
    status: status,
    sellerName: 'ComptaFlow Entreprise',
    sellerIce: '000111222000033',
    sellerIf: '12345678',
    sellerRc: 'RC 12345',
    sellerTp: 'TP 987654',
    sellerAddress: '8 rue de la Liberté',
    sellerCity: 'Agadir',
    sellerPhone: '+212 6 00 00 00 00',
    sellerEmail: 'contact@comptaflow.example',
    buyerName: buyerName,
    buyerIce: buyerIce,
    buyerIf: '87654321',
    buyerRc: 'RC 67890',
    buyerTp: 'TP 456789',
    buyerAddress: buyerAddress,
    buyerCity: buyerCity,
    buyerPhone: '+212 6 11 11 11 11',
    buyerEmail: 'client@example.com',
    paymentTerms: paymentTerms,
  );
}

List<InvoiceItemModel> _items(String invoiceId, {required int count}) {
  return List.generate(
    count,
    (index) => InvoiceItemModel(
      id: 'item-$index',
      invoiceId: invoiceId,
      description: 'Produit / service ' + (index + 1).toString() + ' — description de contrôle de pagination',
      quantity: (index % 4 + 1).toDouble(),
      unitPrice: 125.50 + index,
      taxRate: index.isEven ? 20 : 10,
    ),
  );
}

int _pageCount(Uint8List bytes) {
  final text = String.fromCharCodes(bytes);
  return RegExp(r'/Type\s*/Page(?:\s|>)').allMatches(text).length;
}

Future<void> _save(String name, Uint8List bytes) async {
  final directory = Directory('test_output');
  await directory.create(recursive: true);
  await File('${directory.path}/$name').writeAsBytes(bytes, flush: true);
}
