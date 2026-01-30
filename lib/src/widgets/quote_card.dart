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

  const QuoteCard({
    super.key,
    required this.quote,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onTap,
    this.screenshotController,
  });

  @override
  Widget build(BuildContext context) {
    final styleProvider = context.watch<StyleProvider>();
    final style = styleProvider.style;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        // Apply opacity to background color when there's no image
        color: style.backgroundImagePath == null ? style.backgroundColor : null,
        borderRadius: BorderRadius.circular(12),
        image: style.backgroundImagePath != null
            ? DecorationImage(
                image: FileImage(File(style.backgroundImagePath!)),
                fit: BoxFit.cover,
                scale: style.imageScale,
                alignment: style.imageAlignment,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Overlay de color/opacidad
          // When there's an image, this creates a colored overlay
          // When there's no image, this adds transparency/tint to solid background
          if (style.opacity > 0.0)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: style.backgroundImagePath != null
                      ? style.backgroundColor.withValues(alpha: style.opacity)
                      : Colors.white.withValues(alpha: style.opacity),
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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.format_quote_rounded,
                    color: Colors.grey,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                _StyledText(
                  text: quote.text,
                  style: style,
                  fontSize: style.fontSize,
                  isAuthor: false,
                ),
                const SizedBox(height: 16),
                if (quote.author.isNotEmpty)
                  _StyledText(
                    text: '— ${quote.author}',
                    style: style,
                    fontSize: 14,
                    isAuthor: true,
                    textAlign: TextAlign.right,
                  ),
                if (quote.source != null && quote.source!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      quote.source!,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: style.textColor.withValues(alpha: 0.6),
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
                    : style.textColor.withValues(alpha: 0.5),
              ),
              onPressed: onToggleFavorite,
            ),
          ),
        ],
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      ),
    );
  }
}

class _StyledText extends StatelessWidget {
  final String text;
  final QuoteStyle style;
  final double fontSize;
  final bool isAuthor;
  final TextAlign? textAlign;

  const _StyledText({
    required this.text,
    required this.style,
    required this.fontSize,
    required this.isAuthor,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.getFont(
      style.fontFamily ?? 'Lato',
      textStyle: TextStyle(
        fontSize: fontSize,
        height: style.lineHeight,
        letterSpacing: style.letterSpacing,
        wordSpacing: style.wordSpacing,
        fontStyle: isAuthor ? FontStyle.italic : FontStyle.normal,
      ),
    );

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
              color: isAuthor
                  ? style.textColor.withValues(alpha: 0.8)
                  : style.textColor,
              shadows: style.textShadowColor != null
                  ? [
                      BoxShadow(
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
        color: isAuthor
            ? style.textColor.withValues(alpha: 0.8)
            : style.textColor,
        shadows: style.textShadowColor != null
            ? [
                BoxShadow(
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
