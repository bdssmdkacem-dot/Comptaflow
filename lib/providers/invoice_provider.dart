import 'package:flutter/foundation.dart';

import '../data/models/invoice.dart';
import '../data/repositories/invoice_repo.dart';

class InvoiceProvider extends ChangeNotifier {
  InvoiceProvider(this._repository);

  final InvoiceRepository _repository;
  List<InvoiceModel> invoices = const [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      invoices = await _repository.list();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
