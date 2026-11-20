import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quote_design.dart';
export 'quote_design.dart';

/// Formato de relación de aspecto para la vista previa y exportación de la tarjeta.
enum QuoteCardAspectRatio { auto, square, story, portrait, landscape }

extension QuoteCardFormat on QuoteCardAspectRatio {
  double? get ratio => switch (this) {
    QuoteCardAspectRatio.auto => null,
    QuoteCardAspectRatio.square => 1,
    QuoteCardAspectRatio.story => 9 / 16,
    QuoteCardAspectRatio.portrait => 4 / 5,
    QuoteCardAspectRatio.landscape => 16 / 9,
  };

  Size get exportLogicalSize => Size(360, 360 / (ratio ?? 1));
  double get exportPixelRatio =>
      this == QuoteCardAspectRatio.landscape ? 1920 / 360 : 3;
}

/// Preset visual curado de un solo toque para [QuoteStyle].
class QuoteStylePreset {
  final String id;
  final String name;
  final QuoteStyle style;

  const QuoteStylePreset({
    required this.id,
    required this.name,
    required this.style,
  });
}

class QuoteStyle {
  final QuoteDesign design;
  final String? fontFamily;
  final Color backgroundColor;
  final Color textColor;
  final String? backgroundImagePath;
  final double imageScale;
  final Alignment imageAlignment;
  final double contentPadding;
  final double letterSpacing;
  final double wordSpacing;
  final double lineHeight;
  final TextAlign textAlign;
  final double opacity;
  final int? backgroundGradient;
  final QuoteCardAspectRatio aspectRatio;

  // Effects
  final Color? textShadowColor;
  final double textShadowBlur;
  final Color? textOutlineColor;
  final double textOutlineWidth;
  final double fontSize;

  const QuoteStyle({
    this.design = const QuoteDesign(),
    this.fontFamily,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
    this.backgroundImagePath,
    this.imageScale = 1.0,
    this.imageAlignment = Alignment.center,
    this.contentPadding = 24.0,
    this.letterSpacing = 0.0,
    this.wordSpacing = 0.0,
    this.lineHeight = 1.3,
    this.textAlign = TextAlign.center,
    this.opacity = 0.0,
    this.textShadowColor,
    this.textShadowBlur = 2.0,
    this.textOutlineColor,
    this.textOutlineWidth = 1.0,
    this.fontSize = 18.0,
    this.backgroundGradient,
    this.aspectRatio = QuoteCardAspectRatio.auto,
  });

  QuoteStyle copyWith({
    QuoteDesign? design,
    String? fontFamily,
    bool clearFontFamily = false,
    Color? backgroundColor,
    Color? textColor,
    String? backgroundImagePath,
    bool clearBackgroundImage = false,
    double? imageScale,
    Alignment? imageAlignment,
    double? contentPadding,
    double? letterSpacing,
    double? wordSpacing,
    double? lineHeight,
    TextAlign? textAlign,
    double? opacity,
    Color? textShadowColor,
    bool clearTextShadowColor = false,
    double? textShadowBlur,
    Color? textOutlineColor,
    bool clearTextOutlineColor = false,
    double? textOutlineWidth,
    double? fontSize,
    int? backgroundGradient,
    bool clearBackgroundGradient = false,
    QuoteCardAspectRatio? aspectRatio,
  }) {
    return QuoteStyle(
      design: design ?? this.design,
      fontFamily: clearFontFamily ? null : (fontFamily ?? this.fontFamily),
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      backgroundImagePath: clearBackgroundImage
          ? null
          : (backgroundImagePath ?? this.backgroundImagePath),
      imageScale: imageScale ?? this.imageScale,
      imageAlignment: imageAlignment ?? this.imageAlignment,
      contentPadding: contentPadding ?? this.contentPadding,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      textAlign: textAlign ?? this.textAlign,
      opacity: opacity ?? this.opacity,
      textShadowColor: clearTextShadowColor
          ? null
          : (textShadowColor ?? this.textShadowColor),
      textShadowBlur: textShadowBlur ?? this.textShadowBlur,
      textOutlineColor: clearTextOutlineColor
          ? null
          : (textOutlineColor ?? this.textOutlineColor),
      textOutlineWidth: textOutlineWidth ?? this.textOutlineWidth,
      fontSize: fontSize ?? this.fontSize,
      backgroundGradient: clearBackgroundGradient
          ? null
          : (backgroundGradient ?? this.backgroundGradient),
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }

  static QuoteCardAspectRatio _parseAspectRatio(dynamic raw) {
    if (raw is String) {
      for (final value in QuoteCardAspectRatio.values) {
        if (value.name == raw) return value;
      }
    } else if (raw is int &&
        raw >= 0 &&
        raw < QuoteCardAspectRatio.values.length) {
      return QuoteCardAspectRatio.values[raw];
    }
    return QuoteCardAspectRatio.auto;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'design': design.toJson(),
      'fontFamily': fontFamily,
      'backgroundColor': backgroundColor.toARGB32(),
      'textColor': textColor.toARGB32(),
      'backgroundImagePath': backgroundImagePath,
      'imageScale': imageScale,
      'imageAlignmentX': imageAlignment.x,
      'imageAlignmentY': imageAlignment.y,
      'contentPadding': contentPadding,
      'letterSpacing': letterSpacing,
      'wordSpacing': wordSpacing,
      'lineHeight': lineHeight,
      'textAlign': textAlign.index,
      'opacity': opacity,
      'textShadowColor': textShadowColor?.toARGB32(),
      'textShadowBlur': textShadowBlur,
      'textOutlineColor': textOutlineColor?.toARGB32(),
      'textOutlineWidth': textOutlineWidth,
      'fontSize': fontSize,
      'backgroundGradient': backgroundGradient,
      'aspectRatio': aspectRatio.name,
    };
  }

  factory QuoteStyle.fromJson(Map<String, dynamic> json) {
    return QuoteStyle(
      design: json['design'] is Map<String, dynamic>
          ? QuoteDesign.fromJson(json['design'] as Map<String, dynamic>)
          : const QuoteDesign(),
      fontFamily: json['fontFamily'] as String?,
      backgroundColor: Color(
        json['backgroundColor'] as int? ?? Colors.white.toARGB32(),
      ),
      textColor: Color(json['textColor'] as int? ?? Colors.black87.toARGB32()),
      backgroundImagePath: json['backgroundImagePath'] as String?,
      imageScale: (json['imageScale'] as num?)?.toDouble() ?? 1.0,
      imageAlignment: Alignment(
        (json['imageAlignmentX'] as num?)?.toDouble() ?? 0.0,
        (json['imageAlignmentY'] as num?)?.toDouble() ?? 0.0,
      ),
      contentPadding: (json['contentPadding'] as num?)?.toDouble() ?? 24.0,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      wordSpacing: (json['wordSpacing'] as num?)?.toDouble() ?? 0.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.3,
      textAlign:
          TextAlign.values[json['textAlign'] as int? ?? TextAlign.center.index],
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.0,
      textShadowColor: json['textShadowColor'] != null
          ? Color(json['textShadowColor'] as int)
          : null,
      textShadowBlur: (json['textShadowBlur'] as num?)?.toDouble() ?? 2.0,
      textOutlineColor: json['textOutlineColor'] != null
          ? Color(json['textOutlineColor'] as int)
          : null,
      textOutlineWidth: (json['textOutlineWidth'] as num?)?.toDouble() ?? 1.0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18.0,
      backgroundGradient: json['backgroundGradient'] as int?,
      aspectRatio: _parseAspectRatio(json['aspectRatio']),
    );
  }
}

class StyleProvider extends ChangeNotifier {
  QuoteStyle _style = const QuoteStyle();
  final ImagePicker _picker = ImagePicker();
  static const String _styleKey = 'quote_style';
  static const String _savedStylesKey = 'quote_saved_styles';
  final List<QuoteStyle> _undo = [];
  final List<QuoteStyle> _redo = [];
  List<QuoteStylePreset> _savedStyles = [];
  Future<void> _pendingWrites = Future.value();
  bool _editing = false;
  bool _editSnapshotCaptured = false;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  List<QuoteStylePreset> get savedStyles => List.unmodifiable(_savedStyles);

  void beginEdit() {
    _editing = true;
    _editSnapshotCaptured = false;
  }

  void endEdit() {
    _editing = false;
    _editSnapshotCaptured = false;
  }

  void _rememberCurrentStyle() {
    if (_editing && _editSnapshotCaptured) return;
    _undo.add(_style);
    if (_undo.length > 80) _undo.removeAt(0);
    _redo.clear();
    if (_editing) _editSnapshotCaptured = true;
  }

  void undo() {
    endEdit();
    if (!canUndo) return;
    _redo.add(_style);
    _style = _undo.removeLast();
    notifyListeners();
    _saveStyle();
  }

  void redo() {
    endEdit();
    if (!canRedo) return;
    _undo.add(_style);
    _style = _redo.removeLast();
    notifyListeners();
    _saveStyle();
  }

  void updateDesign(QuoteDesign design) {
    _rememberCurrentStyle();
    _style = _style.copyWith(design: design);
    notifyListeners();
    _saveStyle();
  }

  void setCustomGradient(List<Color>? colors, {double? angle}) {
    _rememberCurrentStyle();
    _style = _style.copyWith(
      clearBackgroundImage: colors != null,
      clearBackgroundGradient: true,
      design: _style.design.copyWith(
        gradientColors: colors,
        clearGradient: colors == null,
        gradientAngle: angle,
      ),
    );
    notifyListeners();
    _saveStyle();
  }

  Future<void> flushPendingChanges() => _pendingWrites;

  Future<void> _queueWrite(Future<void> Function() action) {
    final result = _pendingWrites.then((_) => action());
    _pendingWrites = result.catchError((Object error, StackTrace stack) {
      debugPrint('Error saving design: $error');
    });
    return result;
  }

  Future<void> saveNamedStyle(String name) async {
    final clean = name.trim().characters.take(40).toString();
    if (clean.isEmpty) return;
    final index = _savedStyles.indexWhere(
      (preset) => preset.name.toLowerCase() == clean.toLowerCase(),
    );
    final preset = QuoteStylePreset(
      id: index < 0
          ? 'user_${DateTime.now().microsecondsSinceEpoch}'
          : _savedStyles[index].id,
      name: clean,
      style: _style,
    );
    if (index < 0) {
      _savedStyles = [..._savedStyles, preset];
    } else {
      _savedStyles = [..._savedStyles]..[index] = preset;
    }
    notifyListeners();
    await _saveNamedStyles();
  }

  void applySavedStyle(QuoteStylePreset preset) {
    _rememberCurrentStyle();
    _style = preset.style;
    notifyListeners();
    _saveStyle();
  }

  Future<void> deleteSavedStyle(String id) async {
    _savedStyles = _savedStyles.where((preset) => preset.id != id).toList();
    notifyListeners();
    await _saveNamedStyles();
  }

  Future<void> _saveNamedStyles() {
    final encoded = jsonEncode(
      _savedStyles
          .map(
            (preset) => {
              'id': preset.id,
              'name': preset.name,
              'style': preset.style.toJson(),
            },
          )
          .toList(),
    );
    return _queueWrite(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedStylesKey, encoded);
    });
  }

  static const List<LinearGradient> predefinedGradients = [
    LinearGradient(
      colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFfad0c4), Color(0xFFffd1ff)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ),
    LinearGradient(
      colors: [Color(0xFFffecd2), Color(0xFFfcb69f)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    LinearGradient(
      colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFfdfbfb), Color(0xFFebedee)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    ),
  ];

  static const List<QuoteStylePreset> presets = [
    QuoteStylePreset(
      id: 'editorial',
      name: 'Editorial',
      style: QuoteStyle(
        fontFamily: 'Merriweather',
        backgroundColor: Color(0xFFFAF8F5),
        textColor: Color(0xFF1F2937),
        contentPadding: 32.0,
        lineHeight: 1.5,
        letterSpacing: 0.2,
        textAlign: TextAlign.left,
        fontSize: 19.0,
      ),
    ),
    QuoteStylePreset(
      id: 'nocturno',
      name: 'Nocturno',
      style: QuoteStyle(
        fontFamily: 'Montserrat',
        backgroundColor: Color(0xFF161B22),
        textColor: Color(0xFFF3F4F6),
        contentPadding: 28.0,
        lineHeight: 1.4,
        letterSpacing: 0.3,
        textAlign: TextAlign.center,
        fontSize: 18.0,
      ),
    ),
    QuoteStylePreset(
      id: 'papel_calido',
      name: 'Papel cálido',
      style: QuoteStyle(
        fontFamily: 'Merriweather',
        backgroundColor: Color(0xFFF3E9D2),
        textColor: Color(0xFF3E2F23),
        contentPadding: 30.0,
        lineHeight: 1.5,
        letterSpacing: 0.1,
        textAlign: TextAlign.center,
        fontSize: 18.0,
      ),
    ),
    QuoteStylePreset(
      id: 'minimal',
      name: 'Minimal',
      style: QuoteStyle(
        fontFamily: 'Lato',
        backgroundColor: Colors.white,
        textColor: Color(0xFF111827),
        contentPadding: 24.0,
        lineHeight: 1.35,
        letterSpacing: 0.0,
        textAlign: TextAlign.center,
        fontSize: 17.5,
      ),
    ),
  ];

  QuoteStyle get style => _style;

  // Load persisted style on initialization
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString(_savedStylesKey);
    _savedStyles = [];
    if (savedJson != null) {
      try {
        final items = jsonDecode(savedJson) as List;
        for (final item in items) {
          try {
            _savedStyles.add(
              QuoteStylePreset(
                id: item['id'] as String,
                name: item['name'] as String,
                style: QuoteStyle.fromJson(
                  item['style'] as Map<String, dynamic>,
                ),
              ),
            );
          } catch (_) {
            /* Ignore a damaged preset without losing the others. */
          }
        }
      } catch (_) {}
    }
    final styleJson = prefs.getString(_styleKey);
    debugPrint('StyleProvider.init() - Loaded JSON: $styleJson');
    if (styleJson != null) {
      try {
        final map = json.decode(styleJson) as Map<String, dynamic>;
        _style = QuoteStyle.fromJson(map);
        if (_style.backgroundImagePath != null) {
          final file = File(_style.backgroundImagePath!);
          if (!file.existsSync()) {
            debugPrint(
              'StyleProvider.init() - Imagen de fondo guardada no encontrada, borrando ruta.',
            );
            _style = _style.copyWith(clearBackgroundImage: true);
            // Persistimos la corrección para que no vuelva a fallar
            final prefs2 = await SharedPreferences.getInstance();
            await prefs2.setString(_styleKey, json.encode(_style.toJson()));
          }
        }
        debugPrint('StyleProvider.init() - Style loaded successfully');
        notifyListeners();
        _syncStyleToWidget();
      } catch (e) {
        debugPrint('Error loading style: $e');
      }
    } else {
      debugPrint('StyleProvider.init() - No saved style found');
      _syncStyleToWidget();
    }
  }

  // Save style to shared preferences
  Future<void> _saveStyle() {
    final encoded = jsonEncode(_style.toJson());
    return _queueWrite(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_styleKey, encoded);
      await _syncStyleToWidget();
    });
  }

  Future<void> _syncStyleToWidget() async {
    try {
      await HomeWidget.saveWidgetData<int>(
        'widget_bg_color',
        _style.backgroundColor.toARGB32(),
      );
      await HomeWidget.saveWidgetData<int>(
        'widget_text_color',
        _style.textColor.toARGB32(),
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_bg_image',
        _style.backgroundImagePath,
      );
      await HomeWidget.saveWidgetData<double>(
        'widget_bg_opacity',
        _style.opacity,
      );
      await HomeWidget.saveWidgetData<double>(
        'widget_font_size',
        _style.fontSize,
      );

      int androidGravity = 17; // Gravity.CENTER
      if (_style.textAlign == TextAlign.left ||
          _style.textAlign == TextAlign.start) {
        androidGravity = 3; // Gravity.LEFT
      } else if (_style.textAlign == TextAlign.right ||
          _style.textAlign == TextAlign.end) {
        androidGravity = 5; // Gravity.RIGHT
      }
      await HomeWidget.saveWidgetData<int>('widget_text_align', androidGravity);

      await HomeWidget.updateWidget(
        name: 'QuoteWidgetProvider',
        androidName: 'com.inventustechstudio.pazhoy.QuoteWidgetProvider',
        qualifiedAndroidName:
            'com.inventustechstudio.pazhoy.QuoteWidgetProvider',
      );
      debugPrint('StyleProvider - Style synchronized to HomeWidget');
    } catch (e) {
      debugPrint('Error syncing style to widget: $e');
    }
  }

  // --- Text Style ---
  void setFontFamily(String? font) {
    _rememberCurrentStyle();
    _style = _style.copyWith(fontFamily: font, clearFontFamily: font == null);
    notifyListeners();
    _saveStyle();
  }

  void setTextColor(Color color) {
    _rememberCurrentStyle();
    _style = _style.copyWith(textColor: color);
    notifyListeners();
    _saveStyle();
  }

  void setTextAlign(TextAlign align) {
    _rememberCurrentStyle();
    _style = _style.copyWith(textAlign: align);
    notifyListeners();
    _saveStyle();
  }

  // --- Effects ---
  void setTextShadowColor(Color? color) {
    _rememberCurrentStyle();
    _style = _style.copyWith(
      textShadowColor: color,
      clearTextShadowColor: color == null,
    );
    notifyListeners();
    _saveStyle();
  }

  void setTextShadowBlur(double value) {
    _rememberCurrentStyle();
    _style = _style.copyWith(textShadowBlur: value);
    notifyListeners();
    _saveStyle();
  }

  void setTextOutlineColor(Color? color) {
    _rememberCurrentStyle();
    _style = _style.copyWith(
      textOutlineColor: color,
      clearTextOutlineColor: color == null,
    );
    notifyListeners();
    _saveStyle();
  }

  void setTextOutlineWidth(double value) {
    _rememberCurrentStyle();
    _style = _style.copyWith(textOutlineWidth: value);
    notifyListeners();
    _saveStyle();
  }

  // --- Background ---
  void setBackgroundColor(Color color) {
    _rememberCurrentStyle();
    _style = _style.copyWith(
      backgroundColor: color,
      clearBackgroundGradient: true,
      design: _style.design.copyWith(clearGradient: true),
    );
    notifyListeners();
    _saveStyle();
  }

  void setBackgroundGradient(int? index) {
    _rememberCurrentStyle();
    _style = _style.copyWith(
      design: _style.design.copyWith(clearGradient: true),
      backgroundGradient: index,
      clearBackgroundGradient: index == null,
    );
    notifyListeners();
    _saveStyle();
  }

  void setOpacity(double value) {
    _rememberCurrentStyle();
    _style = _style.copyWith(opacity: value);
    notifyListeners();
    _saveStyle();
  }

  Future<void> pickBackgroundImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (image != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = image.path.split('.').last.toLowerCase();
        final safeName = 'widget_bg_$timestamp.$extension';
        final newPath = '${directory.path}/$safeName';
        await File(image.path).copy(newPath);

        // Verificar que el archivo copiado realmente existe antes de usarlo
        if (await File(newPath).exists()) {
          _rememberCurrentStyle();
          _style = _style.copyWith(backgroundImagePath: newPath);
        } else {
          // Fallback: usar la ruta original si la copia falla
          debugPrint(
            'StyleProvider - Copia falló, usando ruta original: ${image.path}',
          );
          _rememberCurrentStyle();
          _style = _style.copyWith(backgroundImagePath: image.path);
        }
      } catch (e) {
        debugPrint('Error saving background image: $e');
        // Fallback: usar la ruta temporal original
        _rememberCurrentStyle();
        _style = _style.copyWith(backgroundImagePath: image.path);
      }
      notifyListeners();
      _saveStyle();
    }
  }

  void removeBackgroundImage() {
    _rememberCurrentStyle();
    _style = _style.copyWith(
      clearBackgroundImage: true,
      imageScale: 1,
      imageAlignment: Alignment.center,
    );
    notifyListeners();
    _saveStyle();
  }

  // --- Image Manipulation ---
  void setImageScale(double scale) {
    _rememberCurrentStyle();
    _style = _style.copyWith(imageScale: scale);
    notifyListeners();
    _saveStyle();
  }

  void setImageAlignment(Alignment align) {
    _rememberCurrentStyle();
    _style = _style.copyWith(imageAlignment: align);
    notifyListeners();
    _saveStyle();
  }

  void resetImageSettings() {
    _rememberCurrentStyle();
    _style = _style.copyWith(imageScale: 1.0, imageAlignment: Alignment.center);
    notifyListeners();
    _saveStyle();
  }

  // --- Spacing ---
  void setContentPadding(double value) {
    _rememberCurrentStyle();
    _style = _style.copyWith(
      contentPadding: value,
      design: _style.design.copyWith(clearMargins: true),
    );
    notifyListeners();
    _saveStyle();
  }

  void setLetterSpacing(double value) {
    _rememberCurrentStyle();
    _style = _style.copyWith(letterSpacing: value);
    notifyListeners();
    _saveStyle();
  }

  void setWordSpacing(double value) {
    _rememberCurrentStyle();
    _style = _style.copyWith(wordSpacing: value);
    notifyListeners();
    _saveStyle();
  }

  void setLineHeight(double value) {
    _rememberCurrentStyle();
    _style = _style.copyWith(lineHeight: value);
    notifyListeners();
    _saveStyle();
  }

  void setFontSize(double value) {
    _rememberCurrentStyle();
    _style = _style.copyWith(fontSize: value);
    notifyListeners();
    _saveStyle();
  }

  // --- Format & Presets ---
  void setAspectRatio(QuoteCardAspectRatio ratio) {
    if (_style.aspectRatio == ratio) return;
    _rememberCurrentStyle();
    _style = _style.copyWith(aspectRatio: ratio);
    notifyListeners();
    _saveStyle();
  }

  void applyPreset(QuoteStylePreset preset) {
    _rememberCurrentStyle();
    _style = preset.style.copyWith(aspectRatio: _style.aspectRatio);
    notifyListeners();
    _saveStyle();
  }

  void resetStyle() {
    _rememberCurrentStyle();
    _style = const QuoteStyle();
    notifyListeners();
    _saveStyle();
  }
}
