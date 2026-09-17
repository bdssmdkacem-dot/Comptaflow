import 'dart:async';

import 'app_error_mapper.dart';

/// Retries only operations that are explicitly safe to repeat.
///
/// Do not wrap non-idempotent creates, payments, or other mutations unless the
/// caller can prove the operation is idempotent.
class NetworkRetry {
  const NetworkRetry._();

  static Future<T> run<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 400),
  }) async {
    if (maxAttempts < 1) {
      throw ArgumentError.value(maxAttempts, 'maxAttempts');
    }

    var attempt = 0;
    while (true) {
      attempt++;
      try {
        return await operation();
      } catch (error) {
        if (attempt >= maxAttempts || !AppErrorMapper.isRetryable(error)) {
          rethrow;
        }

        final delay = initialDelay * (1 << (attempt - 1));
        await Future<void>.delayed(delay);
      }
    }
  }
}
