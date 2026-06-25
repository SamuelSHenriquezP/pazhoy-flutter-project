import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuoteStyle {
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

  // Effects
  final Color? textShadowColor;
  final double textShadowBlur;
  final Color? textOutlineColor;
  final double textOutlineWidth;
  final double fontSize;

  const QuoteStyle({
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
  });

  QuoteStyle copyWith({
    String? fontFamily,
    Color? backgroundColor,
    Color? textColor,
    String? backgroundImagePath,
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
  }) {
    return QuoteStyle(
      fontFamily: fontFamily ?? this.fontFamily,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
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
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
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
    };
  }

  factory QuoteStyle.fromJson(Map<String, dynamic> json) {
    return QuoteStyle(
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
    );
  }
}

class StyleProvider extends ChangeNotifier {
  QuoteStyle _style = const QuoteStyle();
  final ImagePicker _picker = ImagePicker();
  static const String _styleKey = 'quote_style';

  QuoteStyle get style => _style;

  // Load persisted style on initialization
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final styleJson = prefs.getString(_styleKey);
    debugPrint('StyleProvider.init() - Loaded JSON: $styleJson');
    if (styleJson != null) {
      try {
        final map = json.decode(styleJson) as Map<String, dynamic>;
        _style = QuoteStyle.fromJson(map);
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
  Future<void> _saveStyle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final styleJson = json.encode(_style.toJson());
      await prefs.setString(_styleKey, styleJson);
      debugPrint('StyleProvider._saveStyle() - Saved: $styleJson');
      await _syncStyleToWidget();
    } catch (e) {
      debugPrint('Error saving style: $e');
    }
  }

  Future<void> _syncStyleToWidget() async {
    try {
      await HomeWidget.saveWidgetData<int>('widget_bg_color', _style.backgroundColor.toARGB32());
      await HomeWidget.saveWidgetData<int>('widget_text_color', _style.textColor.toARGB32());
      await HomeWidget.saveWidgetData<String>('widget_bg_image', _style.backgroundImagePath);
      await HomeWidget.saveWidgetData<double>('widget_bg_opacity', _style.opacity);
      await HomeWidget.saveWidgetData<double>('widget_font_size', _style.fontSize);

      int androidGravity = 17; // Gravity.CENTER
      if (_style.textAlign == TextAlign.left || _style.textAlign == TextAlign.start) {
        androidGravity = 3; // Gravity.LEFT
      } else if (_style.textAlign == TextAlign.right || _style.textAlign == TextAlign.end) {
        androidGravity = 5; // Gravity.RIGHT
      }
      await HomeWidget.saveWidgetData<int>('widget_text_align', androidGravity);

      await HomeWidget.updateWidget(
        name: 'QuoteWidgetProvider',
        androidName: 'QuoteWidgetProvider',
      );
      debugPrint('StyleProvider - Style synchronized to HomeWidget');
    } catch (e) {
      debugPrint('Error syncing style to widget: $e');
    }
  }

  // --- Text Style ---
  void setFontFamily(String? font) {
    _style = _style.copyWith(fontFamily: font);
    notifyListeners();
    _saveStyle();
  }

  void setTextColor(Color color) {
    _style = _style.copyWith(textColor: color);
    notifyListeners();
    _saveStyle();
  }

  void setTextAlign(TextAlign align) {
    _style = _style.copyWith(textAlign: align);
    notifyListeners();
    _saveStyle();
  }

  // --- Effects ---
  void setTextShadowColor(Color? color) {
    _style = _style.copyWith(
      textShadowColor: color,
      clearTextShadowColor: color == null,
    );
    notifyListeners();
    _saveStyle();
  }

  void setTextShadowBlur(double value) {
    _style = _style.copyWith(textShadowBlur: value);
    notifyListeners();
    _saveStyle();
  }

  void setTextOutlineColor(Color? color) {
    _style = _style.copyWith(
      textOutlineColor: color,
      clearTextOutlineColor: color == null,
    );
    notifyListeners();
    _saveStyle();
  }

  void setTextOutlineWidth(double value) {
    _style = _style.copyWith(textOutlineWidth: value);
    notifyListeners();
    _saveStyle();
  }

  // --- Background ---
  void setBackgroundColor(Color color) {
    _style = _style.copyWith(backgroundColor: color);
    notifyListeners();
    _saveStyle();
  }

  void setOpacity(double value) {
    _style = _style.copyWith(opacity: value);
    notifyListeners();
    _saveStyle();
  }

  Future<void> pickBackgroundImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _style = _style.copyWith(backgroundImagePath: image.path);
      notifyListeners();
      _saveStyle();
    }
  }

  void removeBackgroundImage() {
    _style = QuoteStyle(
      fontFamily: _style.fontFamily,
      backgroundColor: _style.backgroundColor,
      textColor: _style.textColor,
      backgroundImagePath: null,
      imageScale: 1.0,
      imageAlignment: Alignment.center,
      contentPadding: _style.contentPadding,
      letterSpacing: _style.letterSpacing,
      wordSpacing: _style.wordSpacing,
      lineHeight: _style.lineHeight,
      textAlign: _style.textAlign,
      opacity: _style.opacity,
      textShadowColor: _style.textShadowColor,
      textShadowBlur: _style.textShadowBlur,
      textOutlineColor: _style.textOutlineColor,
      textOutlineWidth: _style.textOutlineWidth,
      fontSize: _style.fontSize,
    );
    notifyListeners();
    _saveStyle();
  }

  // --- Image Manipulation ---
  void setImageScale(double scale) {
    _style = _style.copyWith(imageScale: scale);
    notifyListeners();
    _saveStyle();
  }

  void setImageAlignment(Alignment align) {
    _style = _style.copyWith(imageAlignment: align);
    notifyListeners();
    _saveStyle();
  }

  void resetImageSettings() {
    _style = _style.copyWith(imageScale: 1.0, imageAlignment: Alignment.center);
    notifyListeners();
    _saveStyle();
  }

  // --- Spacing ---
  void setContentPadding(double value) {
    _style = _style.copyWith(contentPadding: value);
    notifyListeners();
    _saveStyle();
  }

  void setLetterSpacing(double value) {
    _style = _style.copyWith(letterSpacing: value);
    notifyListeners();
    _saveStyle();
  }

  void setWordSpacing(double value) {
    _style = _style.copyWith(wordSpacing: value);
    notifyListeners();
    _saveStyle();
  }

  void setLineHeight(double value) {
    _style = _style.copyWith(lineHeight: value);
    notifyListeners();
    _saveStyle();
  }

  void setFontSize(double value) {
    _style = _style.copyWith(fontSize: value);
    notifyListeners();
    _saveStyle();
  }

  void resetStyle() {
    _style = const QuoteStyle();
    notifyListeners();
    _saveStyle();
  }

  void applyPreset(QuoteStyle preset) {
    _style = preset;
    notifyListeners();
    _saveStyle();
  }

  static final Map<String, QuoteStyle> presets = {
    'Zen Minimal': const QuoteStyle(
      backgroundColor: Color(0xFF1A1A2E),
      textColor: Colors.white,
      fontFamily: 'Montserrat',
      fontSize: 18.0,
      textAlign: TextAlign.center,
      lineHeight: 1.4,
    ),
    'Cristal': const QuoteStyle(
      backgroundColor: Color(0xFFE3F2FD),
      textColor: Color(0xFF0D47A1),
      fontFamily: 'Outfit',
      fontSize: 18.0,
      textAlign: TextAlign.center,
      lineHeight: 1.4,
      opacity: 0.15,
      textShadowColor: Color(0x33000000),
      textShadowBlur: 4.0,
    ),
    'Café Retro': const QuoteStyle(
      backgroundColor: Color(0xFFECE0D1),
      textColor: Color(0xFF3D251E),
      fontFamily: 'Courier Prime',
      fontSize: 18.0,
      textAlign: TextAlign.left,
      lineHeight: 1.5,
      letterSpacing: 0.5,
    ),
    'Atardecer': const QuoteStyle(
      backgroundColor: Color(0xFFFFA07A),
      textColor: Color(0xFF2F4F4F),
      fontFamily: 'Playfair Display',
      fontSize: 20.0,
      textAlign: TextAlign.center,
      lineHeight: 1.3,
    ),
    'Estoico': const QuoteStyle(
      backgroundColor: Color(0xFF0E2F20),
      textColor: Color(0xFFDFBA73),
      fontFamily: 'Cardo',
      fontSize: 19.0,
      textAlign: TextAlign.center,
      lineHeight: 1.4,
    ),
  };
}
