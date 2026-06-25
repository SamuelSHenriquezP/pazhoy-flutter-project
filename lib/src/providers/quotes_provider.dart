// lib/src/providers/quotes_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../data/quotes_repository.dart';
import '../models/quote.dart';
import '../services/local_storage_service.dart';

enum ViewState { idle, loading, success, error }

class QuotesProvider with ChangeNotifier {
  final QuotesRepository repo;
  final LocalStorageService storage;

  List<Quote> _quotes = []; // todas cargadas desde JSON (orden en archivo)
  Set<int> _favorites = {};
  int _currentIndex = 0; // índice lógico dentro de la lista publicada

  ViewState _state = ViewState.idle;
  String? _errorMessage;
  String _searchTerm = '';

  // --- Caches (Memoización) ---
  List<Quote>? _cachedPublished;
  Map<String, List<Quote>>? _cachedByAuthor;
  Map<String, List<Quote>>? _cachedBySource;
  Map<String, List<Quote>>? _cachedByTag;
  List<String>? _cachedSortedAuthors;
  List<String>? _cachedSortedSources;
  List<String>? _cachedSortedTags;

  Quote? _cachedDailyQuote;

  // Cache de búsqueda
  String? _lastSearchTerm;
  List<Quote>? _lastFiltered;

  Timer? _searchDebounce;
  Timer? _indexSaveTimer;

  QuotesProvider({required this.repo, required this.storage});

  // --- Getters de estado ---
  ViewState get state => _state;
  bool get isLoading => _state == ViewState.loading;
  Set<int> get favorites => Set.unmodifiable(_favorites);
  int get currentIndex => _currentIndex;
  String get searchTerm => _searchTerm;
  String? get errorMessage => _errorMessage;

  // --- Getters optimizados (usan cache) ---

  /// Lista de frases publicadas (ya filtrada por fecha y ordenada).
  /// Se calcula una sola vez en _recalculateDerivedData().
  List<Quote> get _publishedList => _cachedPublished ?? [];

  /// Getter público (aplica búsqueda sobre la lista cacheada)
  List<Quote> get quotes {
    final term = _searchTerm.trim().toLowerCase();
    final published = _publishedList;

    if (term.isEmpty) return List.unmodifiable(published);

    // Si el término de búsqueda no cambió, devolvemos el resultado anterior
    if (_lastFiltered != null && _lastSearchTerm == term) return _lastFiltered!;

    final filtered = published
        .where(
          (q) => q.textLower.contains(term) || q.authorLower.contains(term),
        )
        .toList(growable: false);

    _lastSearchTerm = term;
    _lastFiltered = filtered;
    return filtered;
  }

  int get totalPublished => _publishedList.length;

  Quote? get dailyQuote => _cachedDailyQuote;

  int? get dailyIndexLogical {
    final dq = _cachedDailyQuote;
    if (dq == null) return null;
    return _publishedList.indexWhere((q) => q.id == dq.id);
  }

  // --- Getters para ExplorePage (Pre-calculados) ---

  Map<String, List<Quote>> get groupByAuthor => _cachedByAuthor ?? {};
  Map<String, List<Quote>> get groupBySource => _cachedBySource ?? {};

  /// Lista ordenada de autores para la UI
  List<String> get sortedAuthors => _cachedSortedAuthors ?? [];


  Map<String, List<Quote>> get groupByTag => _cachedByTag ?? {};
  List<String> get sortedTags => _cachedSortedTags ?? [];

  /// Lista ordenada de fuentes para la UI
  List<String> get sortedSources => _cachedSortedSources ?? [];

  // --- Lógica de Recálculo (El corazón de la optimización) ---

  void _recalculateDerivedData() {
    // 1. Calcular lista publicada (filtro de fecha)
    final nowLocal = DateTime.now();
    final todayUtc = DateTime.utc(nowLocal.year, nowLocal.month, nowLocal.day);

    final published = _quotes
        .where((q) {
          final pd = q.publishDate;
          if (pd == null) return true;
          final pdDate = DateTime.utc(pd.year, pd.month, pd.day);
          return !pdDate.isAfter(todayUtc);
        })
        .toList(growable: false);

    // 2. Ordenar
    published.sort((a, b) {
      if (a.publishDate == null && b.publishDate == null) {
        return a.id.compareTo(b.id);
      }
      if (a.publishDate == null) return 1;
      if (b.publishDate == null) return -1;
      final cmp = a.publishDate!.compareTo(b.publishDate!);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });

    _cachedPublished = List.unmodifiable(published);

    // Cachear frase del día: la que tenga publish_date == hoy,
    // o si no hay, la más reciente (última publicada hasta hoy).
    Quote? daily;
    for (final q in published) {
      final pd = q.publishDate;
      if (pd == null) continue;
      final pdDate = DateTime.utc(pd.year, pd.month, pd.day);
      if (pdDate == todayUtc) {
        daily = q;
        break;
      }
    }
    if (daily == null) {
      // Tomar la última frase con fecha (la lista ya está ordenada por fecha asc)
      for (final q in published.reversed) {
        if (q.publishDate != null) {
          daily = q;
          break;
        }
      }
      // Si ninguna tiene fecha, usar la última de la lista
      daily ??= published.isNotEmpty ? published.last : null;
    }
    _cachedDailyQuote = daily;

    // 3. Agrupar por Autor
    final mapAuthor = <String, List<Quote>>{};
    for (final q in published) {
      final key = q.author.isNotEmpty ? q.author : 'Anónimo';
      mapAuthor.putIfAbsent(key, () => []).add(q);
    }
    _cachedByAuthor = Map.unmodifiable(mapAuthor);

    // 4. Agrupar por Fuente
    final mapSource = <String, List<Quote>>{};
    for (final q in published) {
      final key = (q.source != null && q.source!.trim().isNotEmpty)
          ? q.source!
          : 'Sin origen';
      mapSource.putIfAbsent(key, () => []).add(q);
    }
    _cachedBySource = Map.unmodifiable(mapSource);

    // 5. Listas ordenadas de claves (para evitar sort en UI)
    final authorsList = mapAuthor.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _cachedSortedAuthors = List.unmodifiable(authorsList);

    // 5b. Listas ordenadas de fuentes
    final sourcesList = mapSource.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _cachedSortedSources = List.unmodifiable(sourcesList);

    // 6. Agrupar por Tag
    final mapTag = <String, List<Quote>>{};
    for (final q in published) {
      for (final tag in q.tags) {
        mapTag.putIfAbsent(tag, () => []).add(q);
      }
      if (q.tags.isEmpty) {
        mapTag.putIfAbsent('sin categoría', () => []).add(q);
      }
    }
    _cachedByTag = Map.unmodifiable(mapTag);
    final tagsList = mapTag.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _cachedSortedTags = List.unmodifiable(tagsList);

    // Limpiar cache de búsqueda
    _invalidateSearchCache();
  }

  // --- Init ---
  Future<void> init() async {
    _setState(ViewState.loading);
    try {
      final results = await Future.wait([
        repo.loadQuotes(),
        storage.getFavorites(),
        storage.getLastViewedIndex(),
        storage.getCustomQuotesRaw(),
      ]);

      final baseQuotes = results[0] as List<Quote>;
      _favorites = results[1] as Set<int>;
      final savedIndex = results[2] as int?;
      final customRaw = results[3] as List<Map<String, dynamic>>;

      // Parsear frases personalizadas
      final customQuotes = List<Quote>.generate(
        customRaw.length,
        (i) => Quote.fromJson(customRaw[i], 100000 + i),
      );

      _quotes = List.unmodifiable([...baseQuotes, ...customQuotes]);

      // Calculamos todo una sola vez aquí
      _recalculateDerivedData();

      final published = _publishedList;
      final n = published.length;
      if (n == 0) {
        _currentIndex = 0;
      } else if (savedIndex != null && savedIndex >= 0 && savedIndex < n) {
        _currentIndex = savedIndex;
      } else {
        _currentIndex = 0;
      }

      _setState(ViewState.success);
      syncWidgetData();
    } catch (e, st) {
      debugPrint('Error en QuotesProvider.init(): $e\n$st');
      _setError(
        'No pudimos cargar las frases.\nPor favor revisa tu conexión o intenta más tarde.',
      );
    }
  }

  Future<void> addCustomQuote({required String text, String? author, String? source}) async {
    try {
      final customRaw = await storage.getCustomQuotesRaw();

      // Usar el ID más alto existente + 1 para evitar colisiones si se borran frases
      final existingIds = customRaw
          .map((e) => e['id'] as int? ?? 100000)
          .toList();
      final newQuoteId = existingIds.isEmpty
          ? 100000
          : existingIds.reduce((a, b) => a > b ? a : b) + 1;
      final newQuoteMap = {
        'id': newQuoteId,
        'text': text,
        'author': author ?? 'Yo',
        'source': source ?? '',
      };
      
      customRaw.add(newQuoteMap);
      await storage.saveCustomQuotesRaw(customRaw);
      
      final newQuote = Quote.fromJson(newQuoteMap, newQuoteId);
      final newQuotesList = List<Quote>.from(_quotes)..add(newQuote);
      _quotes = List.unmodifiable(newQuotesList);
      
      _recalculateDerivedData();
      
      final newLogicalIdx = _publishedList.indexWhere((q) => q.id == newQuoteId);
      if (newLogicalIdx != -1) {
        _currentIndex = newLogicalIdx;
        await storage.setLastViewedIndex(_currentIndex);
      }
      
      notifyListeners();
      await syncWidgetData();
    } catch (e) {
      debugPrint('Error adding custom quote: $e');
    }
  }

  Future<void> retry() async {
    await init();
  }

  // ── Frase del día ──────────────────────────────────────────────────────────

  /// `true` si la pantalla de frase del día no se ha mostrado hoy todavía.
  Future<bool> shouldShowDailyQuote() => storage.shouldShowDailyQuote();

  /// Marca la pantalla de frase del día como mostrada hoy.
  Future<void> markDailyQuoteShown() => storage.markDailyQuoteShown();

  // --- Favoritos ---
  Future<void> toggleFavorite(int id) async {
    final wasFav = _favorites.contains(id);
    if (wasFav) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    notifyListeners();
    try {
      await storage.setFavorites(_favorites);
      syncWidgetData();
    } catch (e) {
      if (wasFav) {
        _favorites.add(id);
      } else {
        _favorites.remove(id);
      }
      notifyListeners();
      debugPrint('Error guardando favoritos: $e');
    }
  }

  // --- Búsqueda ---
  void setSearchTerm(String term) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      final normalized = term.trim();
      if (_searchTerm == normalized) return;
      _searchTerm = normalized;
      _invalidateSearchCache();
      notifyListeners();
    });
  }

  // --- Índice actual ---
  void setCurrentIndex(int index, {bool persist = true}) {
    final published = _publishedList;
    final n = published.length;
    if (n == 0) return;
    final clamped = index.clamp(0, n - 1);
    if (_currentIndex == clamped) return;
    _currentIndex = clamped;
    notifyListeners();
    if (persist) {
      _indexSaveTimer?.cancel();
      _indexSaveTimer = Timer(const Duration(milliseconds: 400), () {
        storage
            .setLastViewedIndex(_currentIndex)
            .catchError((e) => debugPrint('Err save idx: $e'));
      });
    }
  }

  /// Recalcula publicadas (útil al volver de background por si cambió el día).
  Future<void> refreshPublished() async {
    final before = _publishedList;
    final currentId = (before.isNotEmpty && _currentIndex < before.length)
        ? before[_currentIndex].id
        : null;

    // Recalculamos caches
    _recalculateDerivedData();

    final after = _publishedList;
    if (after.isEmpty) {
      _currentIndex = 0;
      await storage.setLastViewedIndex(_currentIndex);
      notifyListeners();
      return;
    }
    if (currentId != null) {
      final newIdx = after.indexWhere((q) => q.id == currentId);
      _currentIndex = newIdx != -1 ? newIdx : 0;
    } else {
      _currentIndex = 0;
    }
    await storage.setLastViewedIndex(_currentIndex);
    notifyListeners();
  }

  // --- Utils privados ---
  void _invalidateSearchCache() {
    _lastFiltered = null;
    _lastSearchTerm = null;
  }

  void _setState(ViewState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _state = ViewState.error;
    _errorMessage = message;
    notifyListeners();
  }

  // --- Sincronización del Widget ---
  Future<void> syncWidgetData() async {
    try {
      final mode = await storage.getWidgetMode();
      final daily = dailyQuote;

      await HomeWidget.saveWidgetData<String>('widget_mode', mode);

      if (daily != null) {
        await HomeWidget.saveWidgetData<String>('widget_daily_text', daily.text);
        await HomeWidget.saveWidgetData<String>('widget_daily_author', daily.author.isNotEmpty ? daily.author : 'Anónimo');
      }

      final favList = _quotes
          .where((q) => _favorites.contains(q.id))
          .map((q) => {
                'text': q.text,
                'author': q.author.isNotEmpty ? q.author : 'Anónimo',
              })
          .toList();

      await HomeWidget.saveWidgetData<String>('widget_favorites_json', jsonEncode(favList));

      await HomeWidget.updateWidget(
        name: 'QuoteWidgetProvider',
        androidName: 'QuoteWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error syncing widget data: $e');
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _indexSaveTimer?.cancel();
    super.dispose();
  }
}
