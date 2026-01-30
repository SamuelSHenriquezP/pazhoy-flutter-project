// lib/src/models/quote.dart
class Quote {
  final String text;
  final String author;
  final int id;
  final DateTime? publishDate; // UTC date (only year-month-day)
  final String? context; // descripción / notas
  final String? source; // libro, artículo, origen

  // Campos precomputados para búsqueda rápida
  late final String _textLower = text.toLowerCase();
  late final String _authorLower = author.toLowerCase();

  Quote({
    required this.text,
    required this.author,
    required this.id,
    this.publishDate,
    this.context,
    this.source,
  });

  // Constructor desde JSON
  factory Quote.fromJson(Map<String, dynamic> json, int idx) {
    DateTime? parsedDate;
    if (json.containsKey('publish_date')) {
      final raw = (json['publish_date'] ?? '').toString().trim();
      if (raw.isNotEmpty) {
        try {
          final parts = raw.split('-');
          if (parts.length >= 3) {
            final y = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            final d = int.parse(parts[2]);
            // Parseamos la fecha como UTC (sin hora)
            parsedDate = DateTime.utc(y, m, d);
          }
        } catch (_) {
          parsedDate =
              null; // si parse falla, la consideramos null (visible inmediatamente)
        }
      }
    }

    String? parseNullableString(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return Quote(
      text: (json['text'] ?? '') as String,
      author: (json['author'] ?? '') as String,
      id: idx,
      publishDate: parsedDate,
      context: parseNullableString(json['context']),
      source: parseNullableString(json['source']),
    );
  }

  // Método para exportar a JSON (útil para debug)
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'text': text, 'author': author, 'id': id};
    if (publishDate != null) {
      map['publish_date'] =
          '${publishDate!.year.toString().padLeft(4, '0')}-${publishDate!.month.toString().padLeft(2, '0')}-${publishDate!.day.toString().padLeft(2, '0')}';
    }
    if (context != null) map['context'] = context;
    if (source != null) map['source'] = source;
    return map;
  }

  // Añade este método dentro de tu clase Quote

  Quote copyWith({
    String? text,
    String? author,
    int? id,
    DateTime? publishDate,
    String? context,
    String? source,
  }) {
    return Quote(
      text: text ?? this.text,
      author: author ?? this.author,
      id: id ?? this.id,
      publishDate: publishDate ?? this.publishDate,
      context: context ?? this.context,
      source: source ?? this.source,
    );
  }

  // Getters en minúsculas (útiles para búsquedas)
  String get textLower => _textLower;
  String get authorLower => _authorLower;

  // Comparación de igualdad (importante en listas o sets)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quote &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          author == other.author &&
          id == other.id;

  @override
  int get hashCode => Object.hash(text, author, id);

  @override
  String toString() => 'Quote(id: $id, author: $author, text: $text)';
}
