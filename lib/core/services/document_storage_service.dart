import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

class DocumentStorageService {
  static const bucket = 'invoice-pdfs';

  const DocumentStorageService();

  SupabaseClient get _client => SupabaseClientService.client;

  Future<String> uploadInvoicePdf({
    required String invoiceId,
    required Uint8List bytes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Authentication required');
    if (bytes.isEmpty) throw ArgumentError.value(bytes, 'bytes', 'PDF cannot be empty');
    if (bytes.length > 10 * 1024 * 1024) {
      throw ArgumentError.value(bytes.length, 'bytes', 'PDF exceeds 10 MB limit');
    }

    final path = '${user.id}/invoices/$invoiceId.pdf';
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );

    final updated = await _client
        .from('invoices')
        .update({'pdf_url': path})
        .eq('id', invoiceId)
        .eq('user_id', user.id)
        .select('id')
        .maybeSingle();

    if (updated == null) {
      await _client.storage.from(bucket).remove([path]);
      throw StateError('Invoice not found or not owned by current user');
    }

    return path;
  }

  Future<Uint8List> downloadInvoicePdf(String path) async {
    _assertOwnPath(path);
    return _client.storage.from(bucket).download(path);
  }

  Future<String> createInvoicePdfSignedUrl(
    String path, {
    int expiresIn = 3600,
  }) async {
    _assertOwnPath(path);
    if (expiresIn <= 0 || expiresIn > 86400) {
      throw ArgumentError.value(expiresIn, 'expiresIn', 'Must be between 1 second and 24 hours');
    }
    return _client.storage.from(bucket).createSignedUrl(path, expiresIn);
  }

  Future<void> delete(String path) async {
    _assertOwnPath(path);
    await _client.storage.from(bucket).remove([path]);
  }

  void _assertOwnPath(String path) {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Authentication required');
    final expectedPrefix = '${user.id}/';
    if (!path.startsWith(expectedPrefix) || path.contains('..')) {
      throw ArgumentError.value(path, 'path', 'Storage path is not owned by current user');
    }
  }
}
