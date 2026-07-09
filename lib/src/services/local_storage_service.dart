import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio local para almacenar datos persistentes del usuario.
/// Gestiona favoritos y el último índice de frase visualizado.
///
/// Usa [SharedPreferences] como backend de almacenamiento.
class LocalStorageService {
  static const String _favKey = 'favorites';
  static const String _lastIndexKey = 'last_quote_index';
  static const String _dailyShownKey = 'daily_shown_date';
  static const String _streakCountKey = 'streak_count';
  static const String _streakLastDateKey = 'streak_last_date';
  static const String _collectionsKey = 'user_collections';

  SharedPreferences? _prefs;

  /// Inicializa el servicio. Debe llamarse una sola vez (en `main()` idealmente).
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('LocalStorageService inicializado correctamente');
    } catch (e, st) {
      debugPrint('Error al inicializar SharedPreferences: $e\n$st');
      rethrow; // opcional: relanzar el error si quieres detener el arranque
    }
  }

  /// Obtiene los IDs de favoritos almacenados localmente.
  Future<Set<int>> getFavorites() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favKey) ?? [];
    return list
        .map((e) => int.tryParse(e))
        .whereType<int>() // descarta nulos o valores corruptos
        .toSet();
  }

  /// Guarda el conjunto de IDs favoritos.
  Future<void> setFavorites(Set<int> favorites) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final asString = favorites.map((e) => e.toString()).toList();
    final success = await prefs.setStringList(_favKey, asString);
    if (!success) debugPrint('⚠️ No se pudieron guardar los favoritos');
  }

  /// Devuelve el último índice de frase visualizado (si existe).
  Future<int?> getLastViewedIndex() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getInt(_lastIndexKey);
  }

  /// Guarda el índice de la última frase visualizada.
  Future<void> setLastViewedIndex(int index) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final success = await prefs.setInt(_lastIndexKey, index);
    if (!success) debugPrint('⚠️ No se pudo guardar el último índice visto');
  }

  /// Limpia todos los datos persistidos (útil para debug o logout futuro).
  Future<void> clear() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_favKey);
    await prefs.remove(_lastIndexKey);
    debugPrint('Datos locales limpiados');
  }

  // ── Frase del día ──────────────────────────────────────────────────────────

  /// Devuelve `true` si la pantalla de frase del día aún no se ha mostrado hoy.
  Future<bool> shouldShowDailyQuote() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final stored = prefs.getString(_dailyShownKey);
    final today = _todayString();
    return stored != today;
  }

  /// Marca la frase del día como ya mostrada en la fecha de hoy.
  Future<void> markDailyQuoteShown() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_dailyShownKey, _todayString());
  }

  String _todayString() {
    final t = DateTime.now();
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  // --- Configuraciones del Widget ---
  static const String _widgetModeKey = 'widget_mode';

  Future<String> getWidgetMode() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(_widgetModeKey) ?? 'daily';
  }

  Future<void> setWidgetMode(String mode) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_widgetModeKey, mode);
  }

  // --- Frases Personalizadas del Usuario ---
  static const String _customQuotesKey = 'user_custom_quotes';

  Future<List<Map<String, dynamic>>> getCustomQuotesRaw() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_customQuotesKey);
      if (jsonStr == null) return [];
      final list = json.decode(jsonStr) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Error loading custom quotes: $e');
      return [];
    }
  }

  Future<void> saveCustomQuotesRaw(List<Map<String, dynamic>> quotes) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final jsonStr = json.encode(quotes);
      await prefs.setString(_customQuotesKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving custom quotes: $e');
    }
  }

  // --- Rachas (Streaks) ---
  
  /// Actualiza la racha del usuario basándose en la última fecha de apertura.
  /// Devuelve un mapa con { 'streak': int, 'increased': bool }
  Future<Map<String, dynamic>> updateAndGetStreak() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final today = _todayString();
    final lastDate = prefs.getString(_streakLastDateKey);
    int currentStreak = prefs.getInt(_streakCountKey) ?? 0;
    bool increased = false;

    if (lastDate == today) {
      // Ya abrió hoy, no hacer nada
      return {'streak': currentStreak, 'increased': false};
    }

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    if (lastDate == yesterdayStr) {
      // Racha continua
      currentStreak += 1;
      increased = true;
    } else {
      // Racha perdida o es el primer día
      currentStreak = 1;
      // Si el lastDate es null, es la primera vez, consideramos que "aumentó"
      increased = (lastDate != null) ? false : true; 
    }

    await prefs.setInt(_streakCountKey, currentStreak);
    await prefs.setString(_streakLastDateKey, today);

    return {'streak': currentStreak, 'increased': increased};
  }
  
  Future<int> getStreakCount() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getInt(_streakCountKey) ?? 0;
  }

  // --- Colecciones ---

  Future<List<Map<String, dynamic>>> getCollections() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_collectionsKey);
      if (jsonStr == null) return [];
      final list = json.decode(jsonStr) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Error loading collections: $e');
      return [];
    }
  }

  Future<void> saveCollections(List<Map<String, dynamic>> collections) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final jsonStr = json.encode(collections);
      await prefs.setString(_collectionsKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving collections: $e');
    }
  }
}
