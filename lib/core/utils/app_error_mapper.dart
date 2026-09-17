import 'dart:async';
import 'dart:io';

/// Converts technical exceptions into short, user-safe messages.
///
/// The original exception must never be shown directly in the UI because it
/// may contain backend, SQL, Storage, or transport details.
class AppErrorMapper {
  const AppErrorMapper._();

  static String message(Object error, {bool french = true}) {
    if (_isNetwork(error)) {
      return french
          ? 'Connexion impossible. Vérifiez votre connexion Internet puis réessayez.'
          : 'تعذر الاتصال. تحقق من اتصال الإنترنت ثم أعد المحاولة.';
    }

    final text = error.toString().toLowerCase();
    if (text.contains('timeout') || text.contains('timed out')) {
      return french
          ? 'La connexion a pris trop de temps. Réessayez dans un instant.'
          : 'استغرق الاتصال وقتًا طويلًا. أعد المحاولة بعد قليل.';
    }

    if (text.contains('unauthorized') ||
        text.contains('not authenticated') ||
        text.contains('jwt') ||
        text.contains('invalid login credentials')) {
      return french
          ? 'Votre session a expiré. Reconnectez-vous puis réessayez.'
          : 'انتهت جلسة الدخول. سجّل الدخول من جديد ثم أعد المحاولة.';
    }

    if (text.contains('storage') ||
        text.contains('object not found') ||
        text.contains('bucket')) {
      return french
          ? 'Le document n’est pas disponible pour le moment. Réessayez.'
          : 'المستند غير متاح حاليًا. أعد المحاولة.';
    }

    if (text.contains('duplicate') ||
        text.contains('unique constraint') ||
        text.contains('already exists')) {
      return french
          ? 'Cet élément existe déjà.'
          : 'هذا العنصر موجود بالفعل.';
    }

    if (text.contains('permission denied') ||
        text.contains('row-level security') ||
        text.contains('forbidden')) {
      return french
          ? 'Cette opération n’est pas autorisée.'
          : 'هذه العملية غير مسموح بها.';
    }

    return french
        ? 'Une erreur est survenue. Réessayez dans un instant.'
        : 'حدث خطأ. أعد المحاولة بعد قليل.';
  }

  static bool isRetryable(Object error) {
    if (_isNetwork(error)) return true;
    if (error is TimeoutException) return true;

    final text = error.toString().toLowerCase();
    return text.contains('timeout') ||
        text.contains('timed out') ||
        text.contains('connection reset') ||
        text.contains('connection closed') ||
        text.contains('temporarily unavailable') ||
        text.contains('service unavailable') ||
        text.contains('503') ||
        text.contains('502') ||
        text.contains('504');
  }

  static bool _isNetwork(Object error) {
    return error is SocketException || error is HttpException;
  }
}
