import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio local para almacenar datos persistentes del usuario.
/// Gestiona favoritos y el último índice de frase visualizado.
///
/// Usa [SharedPreferences] como backend de almacenamiento.
class LocalStorageService {
  static const String _favKey = 'favorites';
  static const String _lastIndexKey = 'last_quote_index';

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
}
