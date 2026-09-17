import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/utils/postgrest_search_sanitizer.dart';

void main() {
  group('PostgrestSearchSanitizer', () {
    test('escapes PostgREST filter syntax and LIKE wildcards', () {
      expect(
        PostgrestSearchSanitizer.escape(r"a%,b_(c)\\"),
        r"a\%,b\_\(c\)\\\\",
      );
    });

    test('keeps normal Arabic and French search text unchanged', () {
      expect(PostgrestSearchSanitizer.escape('محمد Casablanca'), 'محمد Casablanca');
    });
  });
}
