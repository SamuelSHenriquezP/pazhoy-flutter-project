import 'package:flutter_test/flutter_test.dart';
import 'package:pazhoy/src/models/quote.dart';
import 'package:pazhoy/src/providers/quotes_provider.dart';
import 'package:pazhoy/src/data/quotes_repository.dart';
import 'package:pazhoy/src/services/local_storage_service.dart';

// --- Manual Mocks ---

class MockQuotesRepository implements QuotesRepository {
  bool shouldThrow = false;
  List<Quote> mockQuotes = [];

  @override
  Future<List<Quote>> loadQuotes() async {
    if (shouldThrow) throw Exception('Mock Error');
    return mockQuotes;
  }
}

class MockLocalStorageService implements LocalStorageService {
  Set<int> favorites = {};
  int? lastIndex;

  @override
  Future<void> init() async {}

  @override
  Future<Set<int>> getFavorites() async => favorites;

  @override
  Future<void> setFavorites(Set<int> favs) async {
    favorites = favs;
  }

  @override
  Future<int?> getLastViewedIndex() async => lastIndex;

  @override
  Future<void> setLastViewedIndex(int index) async {
    lastIndex = index;
  }

  @override
  Future<void> clear() async {
    favorites.clear();
    lastIndex = null;
  }
}

void main() {
  late MockQuotesRepository mockRepo;
  late MockLocalStorageService mockStorage;
  late QuotesProvider provider;

  setUp(() {
    mockRepo = MockQuotesRepository();
    mockStorage = MockLocalStorageService();
    provider = QuotesProvider(repo: mockRepo, storage: mockStorage);
  });

  group('QuotesProvider Tests', () {
    test('init loads quotes and sets state to success', () async {
      mockRepo.mockQuotes = [
        Quote(
          text: 'A',
          author: 'A',
          id: 1,
          publishDate: DateTime.utc(2020, 1, 1),
        ),
      ];

      await provider.init();

      expect(provider.state, ViewState.success);
      expect(provider.quotes.length, 1);
      expect(provider.errorMessage, isNull);
    });

    test('init handles error correctly', () async {
      mockRepo.shouldThrow = true;

      await provider.init();

      expect(provider.state, ViewState.error);
      expect(provider.errorMessage, isNotNull);
      expect(provider.quotes, isEmpty);
    });

    test('Filters future quotes', () async {
      final now = DateTime.now().toUtc();
      final futureDate = now.add(const Duration(days: 365));
      final pastDate = now.subtract(const Duration(days: 365));

      mockRepo.mockQuotes = [
        Quote(text: 'Past', author: 'A', id: 1, publishDate: pastDate),
        Quote(text: 'Future', author: 'B', id: 2, publishDate: futureDate),
      ];

      await provider.init();

      expect(provider.quotes.length, 1);
      expect(provider.quotes.first.text, 'Past');
    });

    test('Search filters quotes', () async {
      mockRepo.mockQuotes = [
        Quote(text: 'Apple', author: 'Newton', id: 1),
        Quote(text: 'Banana', author: 'Minion', id: 2),
      ];
      await provider.init();

      // Simulate search (bypass debounce for test by calling internal logic or waiting)
      // Since setSearchTerm has a timer, we can't easily test it without async waiting.
      // However, we can test the getter logic if we could set the term.
      // Or we can wait.

      provider.setSearchTerm('Apple');
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Wait for debounce

      expect(provider.quotes.length, 1);
      expect(provider.quotes.first.text, 'Apple');

      provider.setSearchTerm('Minion');
      await Future.delayed(const Duration(milliseconds: 300));

      expect(provider.quotes.length, 1);
      expect(provider.quotes.first.author, 'Minion');
    });

    test('Favorites toggle updates state and storage', () async {
      mockRepo.mockQuotes = [Quote(text: 'A', author: 'A', id: 1)];
      await provider.init();

      await provider.toggleFavorite(1);
      expect(provider.favorites.contains(1), true);
      expect(mockStorage.favorites.contains(1), true);

      await provider.toggleFavorite(1);
      expect(provider.favorites.contains(1), false);
      expect(mockStorage.favorites.contains(1), false);
    });
  });
}
