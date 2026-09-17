import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/client.dart';
import '../../data/models/invoice.dart';
import '../../data/repositories/client_repo.dart';

class InvoicePdfService {
  const InvoicePdfService();

  static const _brand = PdfColor.fromInt(0xFF0B6B5B);
  static const _brandDark = PdfColor.fromInt(0xFF075447);
  static const _brandSoft = PdfColor.fromInt(0xFFEAF5F2);
  static const _ink = PdfColor.fromInt(0xFF102A29);
  static const _muted = PdfColor.fromInt(0xFF64716F);
  static const _line = PdfColor.fromInt(0xFFD9E2E0);
  static const _surface = PdfColor.fromInt(0xFFF7F9F8);

  Future<Uint8List> build({
    required InvoiceModel invoice,
    required InvoiceDetails details,
    ClientModel? client,
    String? ownerEmail,
  }) async {
    client ??= await _resolveClient(invoice);

    final document = pw.Document(
      title: 'Facture ${invoice.invoiceNumber}',
      author: invoice.sellerName?.isNotEmpty == true ? invoice.sellerName! : 'ComptaFlow',
      subject: 'Facture ${invoice.invoiceNumber}',
    );

    final date = _date(invoice.date);
    final sellerName = invoice.sellerName?.trim().isNotEmpty == true
        ? invoice.sellerName!.trim()
        : 'COMPTAFLOW';
    final sellerEmail = invoice.sellerEmail?.trim().isNotEmpty == true
        ? invoice.sellerEmail!.trim()
        : ownerEmail?.trim();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 38, 40, 42),
        maxPages: 50,
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox.shrink()
            : pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.only(bottom: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(sellerName, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _brand)),
                    pw.Text(invoice.invoiceNumber, style: const pw.TextStyle(fontSize: 8, color: _muted)),
                  ],
                ),
              ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 14),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Généré avec ComptaFlow', style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
              pw.Text('Page ${context.pageNumber} / ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
            ],
          ),
        ),
        build: (context) => [
          _header(
            invoice: invoice,
            sellerName: sellerName,
            sellerEmail: sellerEmail,
            date: date,
          ),
          pw.SizedBox(height: 24),
          _clientCard(client),
          pw.SizedBox(height: 22),
          _itemsTable(details.items),
          pw.SizedBox(height: 16),
          _totals(details),
          if (invoice.paymentTerms?.trim().isNotEmpty == true) ...[
            pw.SizedBox(height: 22),
            _sectionTitle('Conditions de paiement'),
            pw.SizedBox(height: 5),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(11),
              decoration: pw.BoxDecoration(
                color: _surface,
                border: pw.Border.all(color: _line, width: 0.6),
                borderRadius: pw.BorderRadius.circular(7),
              ),
              child: pw.Text(invoice.paymentTerms!.trim(), style: const pw.TextStyle(fontSize: 8.5, color: _ink)),
            ),
          ],
          pw.SizedBox(height: 22),
          _statusAndNote(invoice.status),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header({
    required InvoiceModel invoice,
    required String sellerName,
    required String? sellerEmail,
    required String date,
  }) {
    final legal = <String>[
      if (_has(invoice.sellerIce)) 'ICE : ${invoice.sellerIce}',
      if (_has(invoice.sellerIf)) 'IF : ${invoice.sellerIf}',
      if (_has(invoice.sellerRc)) 'RC : ${invoice.sellerRc}',
      if (_has(invoice.sellerTp)) 'TP : ${invoice.sellerTp}',
    ];

    final contact = <String>[
      if (_has(invoice.sellerAddress)) invoice.sellerAddress!.trim(),
      if (_has(invoice.sellerCity)) invoice.sellerCity!.trim(),
      if (_has(invoice.sellerPhone)) 'Tél. : ${invoice.sellerPhone!.trim()}',
      if (_has(sellerEmail)) sellerEmail!.trim(),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 15),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _brand, width: 2.2)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      sellerName,
                      style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold, color: _brandDark),
                    ),
                    if (contact.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      ...contact.map((value) => pw.Text(value, style: const pw.TextStyle(fontSize: 8.5, color: _muted))),
                    ],
                    if (legal.isNotEmpty) ...[
                      pw.SizedBox(height: 7),
                      pw.Wrap(
                        spacing: 10,
                        runSpacing: 3,
                        children: legal
                            .map((value) => pw.Text(value, style: const pw.TextStyle(fontSize: 7.5, color: _muted)))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 18),
              pw.Container(
                width: 142,
                padding: const pw.EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: pw.BoxDecoration(
                  color: _brandSoft,
                  border: pw.Border.all(color: _brand, width: 0.7),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FACTURE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _brand)),
                    pw.SizedBox(height: 4),
                    pw.Text(invoice.invoiceNumber, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _ink)),
                    pw.SizedBox(height: 6),
                    pw.Text('Date d’émission', style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
                    pw.SizedBox(height: 2),
                    pw.Text(date, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _ink)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _clientCard(ClientModel? client) {
    final name = client?.name.trim().isNotEmpty == true ? client!.name.trim() : 'Client comptant';
    final details = <String>[
      if (_has(client?.address)) client!.address!.trim(),
      if (_has(client?.city)) client!.city!.trim(),
      if (_has(client?.phone)) 'Tél. : ${client!.phone!.trim()}',
      if (_has(client?.email)) client!.email!.trim(),
    ];
    final legal = <String>[
      if (_has(client?.ice)) 'ICE : ${client!.ice!.trim()}',
      if (_has(client?.ifNumber)) 'IF : ${client!.ifNumber!.trim()}',
      if (_has(client?.rcNumber)) 'RC : ${client!.rcNumber!.trim()}',
      if (_has(client?.tpNumber)) 'TP : ${client!.tpNumber!.trim()}',
    ];

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(13),
      decoration: pw.BoxDecoration(
        color: _surface,
        border: pw.Border.all(color: _line, width: 0.7),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 45,
            decoration: pw.BoxDecoration(color: _brand, borderRadius: pw.BorderRadius.circular(2)),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('FACTURÉ À', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _brand)),
                pw.SizedBox(height: 4),
                pw.Text(name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink)),
                if (details.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  ...details.map((value) => pw.Text(value, style: const pw.TextStyle(fontSize: 8, color: _muted))),
                ],
                if (legal.isNotEmpty) ...[
                  pw.SizedBox(height: 5),
                  pw.Wrap(
                    spacing: 10,
                    runSpacing: 2,
                    children: legal
                        .map((value) => pw.Text(value, style: const pw.TextStyle(fontSize: 7.5, color: _muted)))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _itemsTable(List<InvoiceItemModel> items) {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(color: _line, width: 0.5),
        bottom: const pw.BorderSide(color: _line, width: 0.7),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.1),
        1: pw.FlexColumnWidth(1.0),
        2: pw.FlexColumnWidth(1.55),
        3: pw.FlexColumnWidth(1.15),
        4: pw.FlexColumnWidth(1.7),
      },
      children: [
        _row(['Désignation', 'Qté', 'Prix HT', 'TVA', 'Total TTC'], header: true),
        ...items.asMap().entries.map(
          (entry) => _row(
            [
              entry.value.description,
              _number(entry.value.quantity),
              '${_number(entry.value.unitPrice)} DH',
              '${_number(entry.value.taxRate)} %',
              '${_number(entry.value.totalTtc)} DH',
            ],
            zebra: entry.key.isOdd,
          ),
        ),
      ],
    );
  }

  pw.Widget _totals(InvoiceDetails details) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, right: 20),
            child: pw.Text(
              'Merci pour votre confiance.',
              style: pw.TextStyle(fontSize: 8.5, color: _muted, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ),
        pw.Container(
          width: 225,
          padding: const pw.EdgeInsets.fromLTRB(13, 11, 13, 12),
          decoration: pw.BoxDecoration(
            color: _brandSoft,
            border: pw.Border.all(color: _brand, width: 0.7),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              _totalRow('Total HT', details.calculatedHt),
              _totalRow('TVA', details.calculatedTva),
              pw.SizedBox(height: 4),
              pw.Container(height: 0.7, color: _brand),
              pw.SizedBox(height: 6),
              _totalRow('Total TTC', details.calculatedTtc, bold: true),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _statusAndNote(String status) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: pw.BoxDecoration(
            color: _brandSoft,
            borderRadius: pw.BorderRadius.circular(12),
            border: pw.Border.all(color: _brand, width: 0.5),
          ),
          child: pw.Text(
            _statusLabel(status),
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _brandDark),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Text(
            'Document commercial généré par ComptaFlow.',
            style: const pw.TextStyle(fontSize: 7.5, color: _muted),
          ),
        ),
      ],
    );
  }

  pw.TableRow _row(List<String> values, {bool header = false, bool zebra = false}) {
    return pw.TableRow(
      decoration: header
          ? const pw.BoxDecoration(color: _brandDark)
          : zebra
              ? const pw.BoxDecoration(color: _surface)
              : null,
      children: values
          .asMap()
          .entries
          .map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 8),
              child: pw.Text(
                entry.value,
                textAlign: entry.key == 0 ? pw.TextAlign.left : pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 7.8,
                  color: header ? PdfColors.white : _ink,
                  fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _totalRow(String label, double value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: bold ? 10.5 : 8.5,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: bold ? _brandDark : _muted,
            ),
          ),
          pw.Text(
            '${_number(value)} DH',
            style: pw.TextStyle(
              fontSize: bold ? 11 : 8.5,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: bold ? _brandDark : _ink,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) => pw.Text(
        title,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _ink),
      );

  Future<ClientModel?> _resolveClient(InvoiceModel invoice) async {
    final clientId = invoice.clientId;
    if (clientId == null || clientId.isEmpty) return null;
    try {
      final clients = await ClientRepository().list();
      for (final client in clients) {
        if (client.id == clientId) return client;
      }
    } catch (_) {
      // PDF generation remains available even if client lookup fails.
    }
    return null;
  }

  bool _has(String? value) => value != null && value.trim().isNotEmpty;

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _number(double value) => value.toStringAsFixed(2);

  String _statusLabel(String status) {
    switch (status) {
      case 'issued':
        return 'Émise';
      case 'paid':
        return 'Payée';
      case 'cancelled':
        return 'Annulée';
      default:
        return 'Brouillon';
    }
  }
}
