import 'package:flutter_test/flutter_test.dart';
import 'package:pazhoy/src/models/quote.dart';

void main() {
  group('Quote Model Tests', () {
    test('fromJson parses valid JSON correctly', () {
      final json = {
        'text': 'Test quote',
        'author': 'Test Author',
        'publish_date': '2023-10-27',
        'context': 'Test context',
        'source': 'Test source',
      };

      final quote = Quote.fromJson(json, 1);

      expect(quote.id, 1);
      expect(quote.text, 'Test quote');
      expect(quote.author, 'Test Author');
      expect(quote.publishDate, DateTime.utc(2023, 10, 27));
      expect(quote.context, 'Test context');
      expect(quote.source, 'Test source');
    });

    test('fromJson handles missing optional fields', () {
      final json = {'text': 'Minimal quote', 'author': 'Unknown'};

      final quote = Quote.fromJson(json, 2);

      expect(quote.id, 2);
      expect(quote.text, 'Minimal quote');
      expect(quote.author, 'Unknown');
      expect(quote.publishDate, isNull);
      expect(quote.context, isNull);
      expect(quote.source, isNull);
    });

    test('fromJson handles invalid date gracefully', () {
      final json = {
        'text': 'Bad date quote',
        'author': 'Me',
        'publish_date': 'invalid-date-format',
      };

      final quote = Quote.fromJson(json, 3);

      expect(quote.publishDate, isNull);
    });

    test('Search helpers normalize text correctly', () {
      final quote = Quote(
        text: '  HeLLo World  ',
        author: '  JoHn DoE  ',
        id: 4,
      );

      // Note: The Quote constructor doesn't trim, but the fromJson does if we added logic there.
      // However, the getters _textLower and _authorLower use .toLowerCase() on the input.
      // Let's verify what the class actually does.

      expect(quote.textLower, contains('hello world'));
      expect(quote.authorLower, contains('john doe'));
    });
  });
}
