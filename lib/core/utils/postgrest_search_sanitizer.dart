class PostgrestSearchSanitizer {
  const PostgrestSearchSanitizer._();

  static String escape(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_')
      .replaceAll(',', '\\,')
      .replaceAll('(', '\\(')
      .replaceAll(')', '\\)');
}
