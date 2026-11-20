import 'dart:io';
import 'dart:ui' as ui;
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
  final bool exportOnly;
  final QuoteStyle? styleOverride;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onTap,
    this.screenshotController,
    this.onEdit,
    this.onDelete,
    this.exportOnly = false,
    this.styleOverride,
  });

  @override
  Widget build(BuildContext context) {
    final style = styleOverride ?? context.watch<StyleProvider>().style;
    final design = style.design;
    final textColor = style.textColor;
    final ratio = style.aspectRatio.ratio;
    final padding = design.padding(style.contentPadding);
    final radius = BorderRadius.circular(design.cornerRadius);
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Icon(
            Icons.format_quote_rounded,
            color: textColor.withValues(alpha: 0.7),
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        _StyledText(
          text: quote.text,
          style: style,
          fontSize: style.fontSize,
          isAuthor: false,
          resolvedTextColor: textColor,
        ),
        if (design.divider != QuoteDivider.none) ...[
          const SizedBox(height: 12),
          Center(
            child: switch (design.divider) {
              QuoteDivider.line => SizedBox(
                width: 64,
                child: Divider(color: textColor, thickness: 1.5),
              ),
              QuoteDivider.dots => Text(
                '•  •  •',
                style: TextStyle(color: textColor),
              ),
              QuoteDivider.diamond => Icon(
                Icons.diamond_outlined,
                color: textColor,
                size: 18,
              ),
              QuoteDivider.none => const SizedBox.shrink(),
            },
          ),
        ],
        if (design.showAuthor && quote.author.isNotEmpty) ...[
          const SizedBox(height: 16),
          _StyledText(
            text: '— ${quote.author}',
            style: style,
            fontSize: design.authorSize,
            isAuthor: true,
            textAlign: TextAlign.right,
            resolvedTextColor: design.authorColor ?? textColor,
          ),
        ],
        if (design.showAuthor &&
            quote.source != null &&
            quote.source!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              quote.source!,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: (design.authorColor ?? textColor).withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );

    DecorationImage? image;
    final imagePath = style.backgroundImagePath;
    if (imagePath != null && File(imagePath).existsSync()) {
      image = DecorationImage(
        image: FileImage(File(imagePath)),
        fit: BoxFit.cover,
        scale: style.imageScale,
        alignment: style.imageAlignment,
      );
    }
    final gradientIndex = style.backgroundGradient;
    final gradient =
        design.customGradient ??
        (gradientIndex != null &&
                gradientIndex >= 0 &&
                gradientIndex < StyleProvider.predefinedGradients.length
            ? StyleProvider.predefinedGradients[gradientIndex]
            : null);
    final background = ColorFiltered(
      colorFilter: ColorFilter.matrix(design.backgroundColorMatrix),
      child: ImageFiltered(
        enabled: design.backgroundBlur > 0,
        imageFilter: ui.ImageFilter.blur(
          sigmaX: design.backgroundBlur,
          sigmaY: design.backgroundBlur,
          tileMode: TileMode.clamp,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.backgroundColor,
            gradient: image == null ? gradient : null,
            image: image,
          ),
        ),
      ),
    );

    Widget content = ClipRRect(
      borderRadius: radius,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: exportOnly ? null : onTap,
          onLongPress: !exportOnly && quote.isCustom
              ? () => _showCustomMenu(context)
              : null,
          child: Stack(
            children: [
              Positioned.fill(child: background),
              if (style.opacity > 0)
                Positioned.fill(
                  child: ColoredBox(
                    color: style.backgroundColor.withValues(
                      alpha: style.opacity,
                    ),
                  ),
                ),
              if (ratio == null)
                Padding(padding: padding, child: column)
              else
                Positioned.fill(
                  child: Padding(
                    padding: padding,
                    child: Align(
                      alignment: Alignment(0, design.verticalPosition),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: (360 - padding.horizontal).clamp(40, 360),
                          child: column,
                        ),
                      ),
                    ),
                  ),
                ),
              if (design.frameWidth > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: Border.all(
                          color: design.frameColor,
                          width: design.frameWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              if (!exportOnly)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? Colors.red
                          : textColor.withValues(alpha: 0.5),
                    ),
                    onPressed: onToggleFavorite,
                  ),
                ),
              if (quote.isCustom && !exportOnly)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Mi frase',
                      style: TextStyle(fontSize: 9.5, color: textColor),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (ratio != null) {
      content = AspectRatio(
        aspectRatio: ratio,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(width: 360, height: 360 / ratio, child: content),
        ),
      );
    }
    if (exportOnly) return content;
    if (screenshotController != null) {
      content = Screenshot(controller: screenshotController!, child: content);
    }
    if (ratio != null) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height *
                (style.aspectRatio == QuoteCardAspectRatio.story ? 0.56 : 0.52),
          ),
          child: content,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: content,
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
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.palette_outlined, size: 18),
                SizedBox(width: 10),
                Text('Personalizar estilo'),
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
      // Reuse the regular face; Flutter synthesizes emphasis without fetching
      // an extra font variant when bold or italic is toggled.
      return GoogleFonts.getFont(
        normalized,
        textStyle: textStyle.copyWith(
          fontWeight: FontWeight.normal,
          fontStyle: FontStyle.normal,
        ),
      ).copyWith(
        fontWeight: textStyle.fontWeight,
        fontStyle: textStyle.fontStyle,
      );
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
      fontWeight: !isAuthor && style.design.bold
          ? FontWeight.bold
          : FontWeight.normal,
      fontStyle: isAuthor || style.design.italic
          ? FontStyle.italic
          : FontStyle.normal,
      decoration: !isAuthor && style.design.underline
          ? TextDecoration.underline
          : TextDecoration.none,
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
              color: isAuthor && style.design.authorColor == null
                  ? textColor.withValues(alpha: 0.8)
                  : textColor,
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
        color: isAuthor && style.design.authorColor == null
            ? textColor.withValues(alpha: 0.8)
            : textColor,
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
