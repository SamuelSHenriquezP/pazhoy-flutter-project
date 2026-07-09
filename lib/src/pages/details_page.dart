// lib/src/pages/details_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quote.dart';
import '../providers/quotes_provider.dart';

class QuoteDetailPage extends StatelessWidget {
  final Quote quote;
  final String heroTag;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const QuoteDetailPage({
    super.key,
    required this.quote,
    required this.heroTag,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width * 0.92;

    // Reactively watch the provider so the favorite icon and state rebuilds automatically
    final provider = context.watch<QuotesProvider>();
    final isFav = provider.favorites.contains(quote.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Frase')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Acciones',
        onPressed: () => _showActionsModal(context, provider, isFav),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showActionsModal(
    BuildContext context,
    QuotesProvider provider,
    bool isFav,
  ) {
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
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.redAccent : null,
                    ),
                    title: Text(
                      isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
                    ),
                    onTap: () {
                      provider.toggleFavorite(quote.id);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.push_pin_outlined),
                    title: const Text('Fijar en el widget'),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await provider.storage.setWidgetMode('pinned');
                        await provider.savePinnedQuoteToWidget(
                          text: quote.text,
                          author: quote.author,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Frase fijada en el widget de la pantalla de inicio',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'No se pudo fijar en el widget: $e',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  // Opciones exclusivas para frases propias
                  if (quote.isCustom) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Editar mi frase'),
                      onTap: () {
                        Navigator.pop(context); // Cierra bottom sheet
                        Navigator.of(context).pop(); // Cierra details_page
                        // Pequeño delay para que el modal se abra sobre la home_page sin conflicto
                        Future.delayed(const Duration(milliseconds: 300), () {
                          onEdit?.call();
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: const Text('Eliminar frase', style: TextStyle(color: Colors.red)),
                      onTap: () async {
                        Navigator.pop(context); // Cierra bottom sheet solamente
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text('Eliminar frase', style: TextStyle(color: Colors.black)),
                            content: const Text(
                              '¿Seguro que quieres eliminar esta frase? Esta acción no se puede deshacer.',
                              style: TextStyle(color: Colors.black87),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                style: TextButton.styleFrom(foregroundColor: Colors.black54),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await provider.deleteCustomQuote(quote.id);
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Volver a home_page
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Frase eliminada')),
                            );
                          }
                        }
                      },
                    ),
                  ],
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
