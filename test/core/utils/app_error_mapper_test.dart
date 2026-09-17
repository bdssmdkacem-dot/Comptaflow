import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/utils/app_error_mapper.dart';

void main() {
  group('AppErrorMapper', () {
    test('maps network errors without exposing technical details', () {
      final message = AppErrorMapper.message(
        const SocketException('secret backend address'),
      );

      expect(message, contains('Connexion impossible'));
      expect(message, isNot(contains('secret backend address')));
    });

    test('maps duplicate errors safely', () {
      final message = AppErrorMapper.message(
        Exception('duplicate key value violates unique constraint'),
      );

      expect(message, 'Cet élément existe déjà.');
    });

    test('maps auth errors safely', () {
      final message = AppErrorMapper.message(
        Exception('JWT expired'),
      );

      expect(message, contains('session a expiré'));
    });

    test('supports Arabic messages', () {
      final message = AppErrorMapper.message(
        const SocketException('network failure'),
        french: false,
      );

      expect(message, contains('تعذر الاتصال'));
    });

    test('marks transient network errors as retryable', () {
      expect(
        AppErrorMapper.isRetryable(const SocketException('offline')),
        isTrue,
      );
      expect(
        AppErrorMapper.isRetryable(Exception('HTTP 503 service unavailable')),
        isTrue,
      );
    });

    test('does not retry validation or permission errors', () {
      expect(
        AppErrorMapper.isRetryable(Exception('permission denied')),
        isFalse,
      );
      expect(
        AppErrorMapper.isRetryable(Exception('invalid amount')),
        isFalse,
      );
    });
  });
}
