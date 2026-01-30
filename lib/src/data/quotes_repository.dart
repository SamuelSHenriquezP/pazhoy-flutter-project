// lib/src/data/quotes_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/quote.dart';

class QuotesRepository {
  Future<List<Quote>> loadQuotes() async {
    try {
      final raw = await rootBundle.loadString('assets/data/quotes.json');
      final parsed = json.decode(raw) as List<dynamic>;
      return List<Quote>.generate(
        parsed.length,
        (i) => Quote.fromJson(parsed[i] as Map<String, dynamic>, i),
      );
    } catch (e) {
      // Lanzamos una excepción limpia para que el Provider la capture
      throw Exception('Error al cargar las frases: $e');
    }
  }
}
