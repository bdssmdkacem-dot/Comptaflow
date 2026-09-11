import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/client.dart';
import '../../data/models/invoice.dart';

class InvoicePdfService {
  const InvoicePdfService();

  Future<Uint8List> build(
    InvoiceDetails details, {
    ClientModel? client,
    String? ownerEmail,
  }) async {
    final invoice = details.invoice;
    final document = pw.Document(title: 'Facture ${invoice.invoiceNumber}', author: 'ComptaFlow');
    final date = '${invoice.date.day.toString().padLeft(2, '0')}/${invoice.date.month.toString().padLeft(2, '0')}/${invoice.date.year}';

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text('Généré par ComptaFlow • ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(invoice.sellerName?.isNotEmpty == true ? invoice.sellerName! : 'COMPTAFLOW', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                  if (invoice.sellerAddress?.isNotEmpty == true) pw.Text(invoice.sellerAddress!, style: const pw.TextStyle(fontSize: 9)),
                  if (invoice.sellerCity?.isNotEmpty == true) pw.Text(invoice.sellerCity!, style: const pw.TextStyle(fontSize: 9)),
                  if (invoice.sellerPhone?.isNotEmpty == true) pw.Text('Tél. : ${invoice.sellerPhone}', style: const pw.TextStyle(fontSize: 9)),
                  if (invoice.sellerEmail?.isNotEmpty == true) pw.Text(invoice.sellerEmail!, style: const pw.TextStyle(fontSize: 9)),
                  if (ownerEmail != null && ownerEmail.isNotEmpty && invoice.sellerEmail == null) pw.Text(ownerEmail, style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 5),
                  if (invoice.sellerIce?.isNotEmpty == true) pw.Text('ICE : ${invoice.sellerIce}', style: const pw.TextStyle(fontSize: 8)),
                  if (invoice.sellerIf?.isNotEmpty == true) pw.Text('IF : ${invoice.sellerIf}', style: const pw.TextStyle(fontSize: 8)),
                  if (invoice.sellerRc?.isNotEmpty == true) pw.Text('RC : ${invoice.sellerRc}', style: const pw.TextStyle(fontSize: 8)),
                  if (invoice.sellerTp?.isNotEmpty == true) pw.Text('TP : ${invoice.sellerTp}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blueGrey200), borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('FACTURE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(invoice.invoiceNumber, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 3),
                    pw.Text(date, style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 28),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CLIENT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 5),
                pw.Text(client?.name ?? 'Client comptant', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                if (client?.ice != null && client!.ice!.isNotEmpty) pw.Text('ICE : ${client.ice}', style: const pw.TextStyle(fontSize: 9)),
                if (client?.phone != null && client!.phone!.isNotEmpty) pw.Text('Tél. : ${client.phone}', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
            columnWidths: const {0: pw.FlexColumnWidth(4.2), 1: pw.FlexColumnWidth(1.1), 2: pw.FlexColumnWidth(1.7), 3: pw.FlexColumnWidth(1.2), 4: pw.FlexColumnWidth(1.8)},
            children: [
              _row(['Désignation', 'Qté', 'Prix HT', 'TVA', 'Total TTC'], header: true),
              ...details.items.map((item) => _row([item.description, _number(item.quantity), '${_number(item.unitPrice)} DH', '${_number(item.taxRate)} %', '${_number(item.totalTtc)} DH'])),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 230,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Column(children: [_totalRow('Total HT', details.calculatedHt), _totalRow('TVA', details.calculatedTva), pw.Divider(color: PdfColors.grey300), _totalRow('Total TTC', details.calculatedTtc, bold: true)]),
            ),
          ),
          if (invoice.paymentTerms?.isNotEmpty == true) ...[
            pw.SizedBox(height: 20),
            pw.Text('Conditions de paiement', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(invoice.paymentTerms!, style: const pw.TextStyle(fontSize: 9)),
          ],
          pw.SizedBox(height: 24),
          pw.Text('Statut : ${_statusLabel(invoice.status)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Merci pour votre confiance.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );

    return document.save();
  }

  pw.TableRow _row(List<String> values, {bool header = false}) => pw.TableRow(
        decoration: header ? const pw.BoxDecoration(color: PdfColors.blueGrey900) : null,
        children: values.map((value) => pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 8), child: pw.Text(value, style: pw.TextStyle(fontSize: 8, color: header ? PdfColors.white : PdfColors.black, fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal)))).toList(),
      );

  pw.Widget _totalRow(String label, double value, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(label, style: pw.TextStyle(fontSize: bold ? 11 : 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)), pw.Text('${_number(value)} DH', style: pw.TextStyle(fontSize: bold ? 11 : 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal))]),
      );

  String _number(double value) => value.toStringAsFixed(2);

  String _statusLabel(String status) {
    switch (status) {
      case 'issued': return 'Émise';
      case 'paid': return 'Payée';
      case 'cancelled': return 'Annulée';
      default: return 'Brouillon';
    }
  }
}
