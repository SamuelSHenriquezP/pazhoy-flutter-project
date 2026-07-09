import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import '../models/quote.dart';
import '../providers/style_provider.dart';

class QuoteCard extends StatelessWidget {
  final Quote quote;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onTap;
  final ScreenshotController? screenshotController;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onTap,
    this.screenshotController,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final styleProvider = context.watch<StyleProvider>();
    final style = styleProvider.style;
    // Usa el color de texto tal como lo definió el usuario, sin modificaciones
    final effectiveTextColor = style.textColor;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        // Apply opacity to background color when there's no image
        color: style.backgroundImagePath == null ? style.backgroundColor : null,
        borderRadius: BorderRadius.circular(12),
        image: (() {
          if (style.backgroundImagePath == null) return null;
          try {
            final file = File(style.backgroundImagePath!);
            if (!file.existsSync()) return null;
            return DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
              scale: style.imageScale,
              alignment: style.imageAlignment,
            );
          } catch (e) {
            debugPrint('Error loading background image: $e');
            return null;
          }
        })(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: quote.isCustom ? () => _showCustomMenu(context) : null,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Overlay de color/opacidad:
              // Con imagen: tinta de backgroundColor encima de la imagen
              // Sin imagen: tinta adicional sobre el color sólido (oscurecer/aclarar)
              if (style.opacity > 0.0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: style.backgroundColor.withValues(
                        alpha: style.opacity,
                      ),
                    ),
                  ),
                ),

              // Contenido
              Padding(
                padding: EdgeInsets.all(style.contentPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.format_quote_rounded,
                        color: effectiveTextColor.withValues(alpha: 0.7),
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StyledText(
                      text: quote.text,
                      style: style,
                      fontSize: style.fontSize,
                      isAuthor: false,
                      resolvedTextColor: effectiveTextColor,
                    ),
                    const SizedBox(height: 16),
                    if (quote.author.isNotEmpty)
                      _StyledText(
                        text: '— ${quote.author}',
                        style: style,
                        fontSize: 14,
                        isAuthor: true,
                        textAlign: TextAlign.right,
                        resolvedTextColor: effectiveTextColor,
                      ),
                    if (quote.source != null && quote.source!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          quote.source!,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color: effectiveTextColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Botón de favoritos
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite
                        ? Colors.red
                        : effectiveTextColor.withValues(alpha: 0.5),
                  ),
                  onPressed: onToggleFavorite,
                ),
              ),
              // Badge de frase propia
              if (quote.isCustom)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: effectiveTextColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 11,
                          color: effectiveTextColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Mi frase',
                          style: TextStyle(
                            fontSize: 9,
                            color: effectiveTextColor.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // Si tenemos controlador, envolvemos en Screenshot
    if (screenshotController != null) {
      cardContent = Screenshot(
        controller: screenshotController!,
        child: cardContent,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: cardContent,
    );
  }

  void _showCustomMenu(BuildContext context) {
    // Encontrar la posición del widget para el menú
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + size.width / 2,
        offset.dy + size.height / 2,
        offset.dx + size.width,
        offset.dy + size.height,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 10),
              Text('Editar'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 10),
              Text('Eliminar', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') onEdit?.call();
      if (value == 'delete') onDelete?.call();
    });
  }
}

class _StyledText extends StatelessWidget {
  final String text;
  final QuoteStyle style;
  final double fontSize;
  final bool isAuthor;
  final TextAlign? textAlign;
  final Color resolvedTextColor;

  const _StyledText({
    required this.text,
    required this.style,
    required this.fontSize,
    required this.isAuthor,
    this.textAlign,
    required this.resolvedTextColor,
  });

  static String? _normalizeFontFamily(String? family) {
    final normalized = family?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    switch (normalized.toLowerCase()) {
      case 'lato':
        return 'Lato';
      case 'roboto':
        return 'Roboto';
      case 'merriweather':
        return 'Merriweather';
      case 'montserrat':
        return 'Montserrat';
      case 'oswald':
        return 'Oswald';
      case 'playfair display':
        return 'Playfair Display';
      case 'dancing script':
        return 'Dancing Script';
      case 'pacifico':
        return 'Pacifico';
      case 'anton':
        return 'Anton';
      case 'lobster':
        return 'Lobster';
      default:
        return normalized;
    }
  }

  static TextStyle _safeGetFont(String family, TextStyle textStyle) {
    final normalized = _normalizeFontFamily(family);
    if (normalized == null) return textStyle;
    try {
      return GoogleFonts.getFont(normalized, textStyle: textStyle);
    } catch (_) {
      return textStyle.copyWith(fontFamily: normalized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTextStyle = TextStyle(
      fontSize: fontSize,
      height: style.lineHeight,
      letterSpacing: style.letterSpacing,
      wordSpacing: style.wordSpacing,
      fontStyle: isAuthor ? FontStyle.italic : FontStyle.normal,
    );
    final baseStyle = style.fontFamily != null
        ? _safeGetFont(style.fontFamily!, baseTextStyle)
        : baseTextStyle;
    final textColor = resolvedTextColor;

    // Si hay contorno, usamos Stack para dibujarlo detrás
    if (style.textOutlineColor != null && style.textOutlineWidth > 0) {
      return Stack(
        children: [
          // Contorno (Stroke)
          Text(
            text,
            textAlign: textAlign ?? style.textAlign,
            style: baseStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth =
                    style.textOutlineWidth *
                    2 // x2 porque el stroke crece hacia adentro y afuera
                ..color = style.textOutlineColor!,
            ),
          ),
          // Relleno (Fill) + Sombra
          Text(
            text,
            textAlign: textAlign ?? style.textAlign,
            style: baseStyle.copyWith(
              color: isAuthor ? textColor.withValues(alpha: 0.8) : textColor,
              shadows: style.textShadowColor != null
                  ? [
                      Shadow(
                        color: style.textShadowColor!,
                        blurRadius: style.textShadowBlur,
                        offset: const Offset(2, 2),
                      ),
                    ]
                  : [],
            ),
          ),
        ],
      );
    }

    // Sin contorno, renderizado normal con sombra opcional
    return Text(
      text,
      textAlign: textAlign ?? style.textAlign,
      style: baseStyle.copyWith(
        color: isAuthor ? textColor.withValues(alpha: 0.8) : textColor,
        shadows: style.textShadowColor != null
            ? [
                Shadow(
                  color: style.textShadowColor!,
                  blurRadius: style.textShadowBlur,
                  offset: const Offset(2, 2),
                ),
              ]
            : [],
      ),
    );
  }
}
