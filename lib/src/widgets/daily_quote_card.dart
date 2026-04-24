// lib/src/widgets/daily_quote_card.dart
import 'package:flutter/material.dart';
import '../models/quote.dart';

/// Tarjeta que muestra la frase del día de forma destacada.
///
/// Adapta sus colores al tema (claro/oscuro) y muestra:
/// - Comilla decorativa grande
/// - Texto de la frase en itálica
/// - Autor alineado a la derecha
/// - Chips de etiquetas
/// - Acciones: favorito, compartir, ver en el listado
class DailyQuoteCard extends StatelessWidget {
  final Quote quote;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onViewInFeed;

  const DailyQuoteCard({
    super.key,
    required this.quote,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onShare,
    this.onViewInFeed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = isDark
        ? [const Color(0xFF1A237E), const Color(0xFF283593)]
        : [const Color(0xFFFFF8E1), const Color(0xFFFCE4EC)];

    final quoteMarkColor = isDark
        ? cs.primary.withAlpha(100)
        : cs.primary.withAlpha(60);

    return Card(
      elevation: 8,
      shadowColor: cs.primary.withAlpha(70),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Comilla decorativa
            Text(
              '\u201C',
              style: TextStyle(
                fontSize: 80,
                height: 0.75,
                color: quoteMarkColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 4),
            // Texto de la frase
            Text(
              quote.text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    height: 1.55,
                  ),
            ),
            const SizedBox(height: 16),
            // Autor
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— ${quote.author.isNotEmpty ? quote.author : "Anónimo"}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
              ),
            ),
            // Tags
            if (quote.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: quote.tags
                    .map(
                      (tag) => Chip(
                        label: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        side: BorderSide.none,
                        backgroundColor: cs.primaryContainer.withAlpha(140),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(height: 16),
            // Acciones
            Row(
              children: [
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey(isFavorite),
                      color: isFavorite ? Colors.redAccent : null,
                    ),
                  ),
                  tooltip: isFavorite
                      ? 'Quitar de favoritos'
                      : 'Añadir a favoritos',
                  onPressed: onToggleFavorite,
                ),
                if (onShare != null)
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Compartir',
                    onPressed: onShare,
                  ),
                const Spacer(),
                if (onViewInFeed != null)
                  TextButton.icon(
                    icon: const Icon(Icons.swipe_vertical, size: 18),
                    label: const Text('Ver en el listado'),
                    onPressed: onViewInFeed,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
