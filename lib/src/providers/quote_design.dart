import 'dart:math' as math;
import 'package:flutter/material.dart';

enum QuoteDivider { none, line, dots, diamond }

/// Extra design settings, serialized independently for older saved styles.
class QuoteDesign {
  final bool bold;
  final bool italic;
  final bool underline;
  final double verticalPosition;
  final double? marginTop;
  final double? marginRight;
  final double? marginBottom;
  final double? marginLeft;
  final double authorSize;
  final Color? authorColor;
  final bool showAuthor;
  final List<Color>? gradientColors;
  final double gradientAngle;
  final double backgroundBlur;
  final double brightness;
  final double contrast;
  final double saturation;
  final double frameWidth;
  final Color frameColor;
  final double cornerRadius;
  final QuoteDivider divider;

  const QuoteDesign({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.verticalPosition = 0,
    this.marginTop,
    this.marginRight,
    this.marginBottom,
    this.marginLeft,
    this.authorSize = 14,
    this.authorColor,
    this.showAuthor = true,
    this.gradientColors,
    this.gradientAngle = 45,
    this.backgroundBlur = 0,
    this.brightness = 0,
    this.contrast = 1,
    this.saturation = 1,
    this.frameWidth = 0,
    this.frameColor = const Color(0xFFD1B88C),
    this.cornerRadius = 12,
    this.divider = QuoteDivider.none,
  });

  QuoteDesign copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    double? verticalPosition,
    double? marginTop,
    double? marginRight,
    double? marginBottom,
    double? marginLeft,
    double? authorSize,
    Color? authorColor,
    bool? showAuthor,
    List<Color>? gradientColors,
    double? gradientAngle,
    double? backgroundBlur,
    double? brightness,
    double? contrast,
    double? saturation,
    double? frameWidth,
    Color? frameColor,
    double? cornerRadius,
    QuoteDivider? divider,
    bool clearMargins = false,
    bool clearAuthorColor = false,
    bool clearGradient = false,
  }) => QuoteDesign(
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    underline: underline ?? this.underline,
    verticalPosition: verticalPosition ?? this.verticalPosition,
    marginTop: clearMargins ? null : (marginTop ?? this.marginTop),
    marginRight: clearMargins ? null : (marginRight ?? this.marginRight),
    marginBottom: clearMargins ? null : (marginBottom ?? this.marginBottom),
    marginLeft: clearMargins ? null : (marginLeft ?? this.marginLeft),
    authorSize: authorSize ?? this.authorSize,
    authorColor: clearAuthorColor ? null : (authorColor ?? this.authorColor),
    showAuthor: showAuthor ?? this.showAuthor,
    gradientColors: clearGradient
        ? null
        : (gradientColors == null
              ? this.gradientColors
              : List.unmodifiable(gradientColors)),
    gradientAngle: gradientAngle ?? this.gradientAngle,
    backgroundBlur: backgroundBlur ?? this.backgroundBlur,
    brightness: brightness ?? this.brightness,
    contrast: contrast ?? this.contrast,
    saturation: saturation ?? this.saturation,
    frameWidth: frameWidth ?? this.frameWidth,
    frameColor: frameColor ?? this.frameColor,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    divider: divider ?? this.divider,
  );

  Map<String, dynamic> toJson() => {
    'bold': bold,
    'italic': italic,
    'underline': underline,
    'verticalPosition': verticalPosition,
    'marginTop': marginTop,
    'marginRight': marginRight,
    'marginBottom': marginBottom,
    'marginLeft': marginLeft,
    'authorSize': authorSize,
    'authorColor': authorColor?.toARGB32(),
    'showAuthor': showAuthor,
    'gradientColors': gradientColors?.map((color) => color.toARGB32()).toList(),
    'gradientAngle': gradientAngle,
    'backgroundBlur': backgroundBlur,
    'brightness': brightness,
    'contrast': contrast,
    'saturation': saturation,
    'frameWidth': frameWidth,
    'frameColor': frameColor.toARGB32(),
    'cornerRadius': cornerRadius,
    'divider': divider.name,
  };

  static double _number(
    Map<String, dynamic> json,
    String key,
    double fallback,
    double min,
    double max,
  ) {
    final value = json[key];
    if (value is! num || !value.isFinite) return fallback;
    return value.toDouble().clamp(min, max);
  }

  factory QuoteDesign.fromJson(Map<String, dynamic> json) {
    final rawColors = json['gradientColors'];
    final colors = rawColors is List
        ? rawColors.whereType<int>().take(3).map(Color.new).toList()
        : <Color>[];
    return QuoteDesign(
      bold: json['bold'] is bool ? json['bold'] as bool : false,
      italic: json['italic'] is bool ? json['italic'] as bool : false,
      underline: json['underline'] is bool ? json['underline'] as bool : false,
      verticalPosition: _number(json, 'verticalPosition', 0, -1, 1),
      marginTop: json['marginTop'] is num
          ? _number(json, 'marginTop', 24, 0, 80)
          : null,
      marginRight: json['marginRight'] is num
          ? _number(json, 'marginRight', 24, 0, 80)
          : null,
      marginBottom: json['marginBottom'] is num
          ? _number(json, 'marginBottom', 24, 0, 80)
          : null,
      marginLeft: json['marginLeft'] is num
          ? _number(json, 'marginLeft', 24, 0, 80)
          : null,
      authorSize: _number(json, 'authorSize', 14, 8, 30),
      authorColor: json['authorColor'] is int
          ? Color(json['authorColor'] as int)
          : null,
      showAuthor: json['showAuthor'] is bool
          ? json['showAuthor'] as bool
          : true,
      gradientColors: colors.length >= 2 ? List.unmodifiable(colors) : null,
      gradientAngle: _number(json, 'gradientAngle', 45, 0, 360),
      backgroundBlur: _number(json, 'backgroundBlur', 0, 0, 20),
      brightness: _number(json, 'brightness', 0, -0.5, 0.5),
      contrast: _number(json, 'contrast', 1, 0.5, 1.5),
      saturation: _number(json, 'saturation', 1, 0, 2),
      frameWidth: _number(json, 'frameWidth', 0, 0, 8),
      frameColor: json['frameColor'] is int
          ? Color(json['frameColor'] as int)
          : const Color(0xFFD1B88C),
      cornerRadius: _number(json, 'cornerRadius', 12, 0, 40),
      divider: QuoteDivider.values.firstWhere(
        (value) => value.name == json['divider'],
        orElse: () => QuoteDivider.none,
      ),
    );
  }

  EdgeInsets padding(double fallback) => EdgeInsets.fromLTRB(
    marginLeft ?? fallback,
    marginTop ?? fallback,
    marginRight ?? fallback,
    marginBottom ?? fallback,
  );

  LinearGradient? get customGradient {
    final colors = gradientColors;
    if (colors == null || colors.length < 2) return null;
    final radians = gradientAngle * math.pi / 180;
    final direction = Alignment(math.cos(radians), math.sin(radians));
    return LinearGradient(colors: colors, begin: -direction, end: direction);
  }

  List<double> get backgroundColorMatrix {
    final inverse = 1 - saturation;
    final r = 0.2126 * inverse;
    final g = 0.7152 * inverse;
    final b = 0.0722 * inverse;
    final offset = (1 - contrast) * 127.5 + brightness * 255;
    return [
      contrast * (r + saturation),
      contrast * g,
      contrast * b,
      0,
      offset,
      contrast * r,
      contrast * (g + saturation),
      contrast * b,
      0,
      offset,
      contrast * r,
      contrast * g,
      contrast * (b + saturation),
      0,
      offset,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}
