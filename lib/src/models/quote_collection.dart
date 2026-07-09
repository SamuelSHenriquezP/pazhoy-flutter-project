// lib/src/models/quote_collection.dart
import 'package:flutter/material.dart';

class QuoteCollection {
  final String id;
  final String name;
  final Color color;
  final List<int> quoteIds;

  QuoteCollection({
    required this.id,
    required this.name,
    required this.color,
    required this.quoteIds,
  });

  factory QuoteCollection.fromJson(Map<String, dynamic> json) {
    return QuoteCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int? ?? 0xFF000000),
      quoteIds: List<int>.from(json['quoteIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
      'quoteIds': quoteIds,
    };
  }

  QuoteCollection copyWith({
    String? id,
    String? name,
    Color? color,
    List<int>? quoteIds,
  }) {
    return QuoteCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      quoteIds: quoteIds ?? this.quoteIds,
    );
  }
}
