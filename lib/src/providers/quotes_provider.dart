// lib/src/providers/quotes_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
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
  List<String>? _cachedSortedAuthors;
  List<String>? _cachedSortedSources;

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

  Quote? get dailyQuote {
    final published = _publishedList;
    final nowUtc = DateTime.now().toUtc();
    final todayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    for (final q in published) {
      final pd = q.publishDate;
      if (pd == null) continue;
      final pdDate = DateTime.utc(pd.year, pd.month, pd.day);
      if (pdDate == todayUtc) return q;
    }
    return null;
  }

  int? get dailyIndexLogical {
    final dq = dailyQuote;
    if (dq == null) return null;
    // Buscamos en la lista cacheada, operación O(N) pero sobre lista en memoria
    return _publishedList.indexWhere((q) => q.id == dq.id);
  }

  // --- Getters para ExplorePage (Pre-calculados) ---

  Map<String, List<Quote>> get groupByAuthor => _cachedByAuthor ?? {};
  Map<String, List<Quote>> get groupBySource => _cachedBySource ?? {};

  /// Lista ordenada de autores para la UI
  List<String> get sortedAuthors => _cachedSortedAuthors ?? [];

  /// Lista ordenada de fuentes para la UI
  List<String> get sortedSources => _cachedSortedSources ?? [];

  // --- Lógica de Recálculo (El corazón de la optimización) ---

  void _recalculateDerivedData() {
    // 1. Calcular lista publicada (filtro de fecha)
    final nowUtc = DateTime.now().toUtc();
    final todayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);

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

    final sourcesList = mapSource.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _cachedSortedSources = List.unmodifiable(sourcesList);

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
      ]);

      _quotes = List.unmodifiable(results[0] as List<Quote>);
      _favorites = results[1] as Set<int>;
      final savedIndex = results[2] as int?;

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
    } catch (e, st) {
      debugPrint('Error en QuotesProvider.init(): $e\n$st');
      _setError(
        'No pudimos cargar las frases.\nPor favor revisa tu conexión o intenta más tarde.',
      );
    }
  }

  Future<void> retry() async {
    await init();
  }

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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _indexSaveTimer?.cancel();
    super.dispose();
  }
}
