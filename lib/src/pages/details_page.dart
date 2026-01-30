// lib/src/pages/details_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quote.dart';

class QuoteDetailPage extends StatelessWidget {
  final Quote quote;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final String heroTag;

  const QuoteDetailPage({
    super.key,
    required this.quote,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width * 0.92;

    return Scaffold(
      appBar: AppBar(
        // El AppBar ahora está más limpio, solo con el título.
        title: const Text('Frase'),
      ),
      // REFACTOR: Añadimos un FloatingActionButton para unificar las acciones.
      floatingActionButton: FloatingActionButton(
        tooltip: 'Acciones',
        onPressed: () => _showActionsModal(context),
        child: const Icon(Icons.more_horiz_rounded),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            28,
            20,
            80,
          ), // Más padding inferior por el FAB
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Hero(
                    tag: heroTag,
                    child: Material(
                      color: Colors.transparent,
                      child: SelectableText(
                        quote.text,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontSize: _responsiveFontSize(media, base: 24),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (quote.author.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '— ${quote.author}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24), // Espacio extra
                  // La información de contexto y fuente se queda igual.
                  if (quote.context != null) ...[
                    Text('Contexto', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(quote.context!, style: textTheme.bodyMedium),
                    const SizedBox(height: 18),
                  ],
                  if (quote.source != null) ...[
                    Text('Fuente', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      quote.source!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  // REFACTOR: La fila de botones de aquí se ha eliminado.
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// REFACTOR: Nuevo método que muestra un panel con todas las acciones.
  void _showActionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Builder(
            builder: (innerContext) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: const Text('Compartir'),
                    onTap: () {
                      Navigator.pop(context);
                      _shareQuote();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.copy_outlined),
                    title: const Text('Copiar al portapapeles'),
                    onTap: () {
                      Navigator.pop(context);
                      _copyQuote(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.redAccent : null,
                    ),
                    title: Text(
                      isFavorite
                          ? 'Quitar de favoritos'
                          : 'Agregar a favoritos',
                    ),
                    onTap: () {
                      onToggleFavorite();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  double _responsiveFontSize(MediaQueryData media, {double base = 20}) {
    final width = media.size.width;
    if (width >= 800) return base + 6;
    if (width >= 600) return base + 3;
    return base;
  }

  // Se simplifica la firma, ya no necesita el context.
  void _shareQuote() {
    final content =
        '"${quote.text}"'
        '${quote.author.isNotEmpty ? '\n— ${quote.author}' : ''}'
        '${quote.source != null ? '\n\nFuente: ${quote.source}' : ''}';
    SharePlus.instance.share(
      ShareParams(text: content.trim(), subject: 'Frase de PazHoy'),
    );
  }

  Future<void> _copyQuote(BuildContext context) async {
    final content =
        '"${quote.text}"'
        '${quote.author.isNotEmpty ? '\n— ${quote.author}' : ''}'
        '${quote.source != null ? '\n\nFuente: ${quote.source}' : ''}';
    try {
      await Clipboard.setData(ClipboardData(text: content.trim()));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Frase copiada al portapapeles')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo copiar: ${e.toString()}')),
        );
      }
    }
  }
}
