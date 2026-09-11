import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class DocumentStorageService {
  static const bucket = 'comptaflow-documents';

  const DocumentStorageService();

  SupabaseClient get _client => SupabaseClientService.client;

  Future<String> uploadInvoicePdf({
    required String invoiceId,
    required Uint8List bytes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Authentication required');

    final path = '${user.id}/invoices/$invoiceId.pdf';
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );
    return path;
  }

  Future<String> createInvoicePdfSignedUrl(
    String path, {
    int expiresIn = 3600,
  }) async {
    return _client.storage.from(bucket).createSignedUrl(path, expiresIn);
  }

  Future<void> delete(String path) async {
    await _client.storage.from(bucket).remove([path]);
  }
}
