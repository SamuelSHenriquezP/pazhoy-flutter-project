// lib/src/pages/details_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quote.dart';
import '../providers/quotes_provider.dart';
import '../widgets/quote_card.dart';
import '../widgets/modern_style_editor.dart';

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

    // Obtenemos reactivamente la frase actualizada del provider
    final provider = context.watch<QuotesProvider>();
    final currentQuote = provider.quotes.firstWhere(
      (q) => q.id == quote.id,
      orElse: () => quote,
    );
    final isFav = provider.favorites.contains(currentQuote.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Detalles de la frase',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFFF9FAFB),
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Botón para personalizar el diseño visual de la tarjeta
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Personalizar tarjeta',
            onPressed: () => _openVisualEditor(context, currentQuote),
          ),
          if (currentQuote.isCustom)
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Más opciones',
              onPressed: () => _showCustomActions(context, provider, currentQuote),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (currentQuote.eventTitle != null) ...[
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF32505A).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF32505A).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_outlined, size: 14, color: Color(0xFF32505A)),
                        const SizedBox(width: 6),
                        Text(
                          currentQuote.eventTitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF32505A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // Main Quote Card
              Hero(
                tag: heroTag,
                child: Material(
                  color: Colors.transparent,
                  child: QuoteCard(
                    quote: currentQuote,
                    isFavorite: isFav,
                    onToggleFavorite: () => provider.toggleFavorite(currentQuote.id),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons Row (Favorito, Guardar, Estilo, Copiar, Compartir)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: isFav ? Icons.favorite : Icons.favorite_border,
                    label: 'Favorito',
                    color: isFav ? Colors.redAccent : Colors.black87,
                    onTap: () => provider.toggleFavorite(currentQuote.id),
                  ),
                  _buildActionButton(
                    icon: Icons.folder_outlined,
                    label: 'Guardar',
                    onTap: () => _showCollectionsModal(context, provider, currentQuote),
                  ),
                  _buildActionButton(
                    icon: Icons.palette_outlined,
                    label: 'Estilo',
                    color: theme.colorScheme.primary,
                    onTap: () => _openVisualEditor(context, currentQuote),
                  ),
                  _buildActionButton(
                    icon: Icons.copy_rounded,
                    label: 'Copiar',
                    onTap: () => _copyQuote(context, currentQuote),
                  ),
                  _buildActionButton(
                    icon: Icons.share_rounded,
                    label: 'Compartir',
                    onTap: () => _shareQuote(currentQuote),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Context & Source Details
              if (currentQuote.context != null || currentQuote.source != null)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentQuote.context != null) ...[
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Contexto Histórico',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentQuote.context!,
                          style: textTheme.bodyMedium?.copyWith(height: 1.6, color: Colors.black87),
                        ),
                        if (currentQuote.source != null) const Divider(height: 32),
                      ],
                      if (currentQuote.source != null) ...[
                        Row(
                          children: [
                            Icon(Icons.menu_book, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Fuente Literaria',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentQuote.source!,
                          style: textTheme.bodyMedium?.copyWith(color: Colors.black54, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Pin Widget Button
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    try {
                      await provider.storage.setWidgetMode('pinned');
                      await provider.savePinnedQuoteToWidget(
                        text: currentQuote.text,
                        author: currentQuote.author,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Frase fijada en el widget de la pantalla de inicio')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo fijar: $e')));
                      }
                    }
                  },
                  icon: const Icon(Icons.push_pin_outlined, size: 18),
                  label: const Text('Fijar en el widget'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }

  // --- Editor Visual de la Tarjeta (sin modificar el texto de la frase) ---
  void _openVisualEditor(BuildContext context, Quote q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF3F4F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final provider = context.watch<QuotesProvider>();
        final isFav = provider.favorites.contains(q.id);
        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.88,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 12, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Personalizar tarjeta',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_rounded),
                        tooltip: 'Listo',
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: QuoteCard(
                        quote: q,
                        isFavorite: isFav,
                        onToggleFavorite: () => provider.toggleFavorite(q.id),
                      ),
                    ),
                  ),
                ),
                const ModernStyleEditor(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCollectionsModal(BuildContext context, QuotesProvider provider, Quote q) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              final collections = provider.collections;

              if (collections.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_off_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No tienes carpetas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        'Crea carpetas en Explorar para organizar tus frases.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.check),
                        label: const Text('Entendido'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Guardar en...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: collections.length,
                      itemBuilder: (context, index) {
                        final c = collections[index];
                        final hasQuote = c.quoteIds.contains(q.id);
                        return ListTile(
                          leading: Icon(Icons.folder, color: c.color),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: hasQuote
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.circle_outlined, color: Colors.grey),
                          onTap: () async {
                            await provider.toggleQuoteInCollection(c.id, q.id);
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(hasQuote ? 'Frase eliminada de ${c.name}' : 'Frase guardada en ${c.name}')),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showCustomActions(BuildContext context, QuotesProvider provider, Quote q) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Personalizar tarjeta'),
                onTap: () {
                  Navigator.pop(context);
                  _openVisualEditor(context, q);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Eliminar frase', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteCustomQuote(context, provider, q);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteCustomQuote(BuildContext context, QuotesProvider provider, Quote q) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar frase'),
        content: const Text('¿Seguro que quieres eliminar esta frase? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await provider.deleteCustomQuote(q.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Frase eliminada')));
      }
    }
  }

  void _shareQuote(Quote q) {
    final content = '"${q.text}"${q.author.isNotEmpty ? '\n— ${q.author}' : ''}${q.source != null ? '\n\nFuente: ${q.source}' : ''}';
    SharePlus.instance.share(ShareParams(text: content.trim(), subject: 'Frase de PazHoy'));
  }

  Future<void> _copyQuote(BuildContext context, Quote q) async {
    final content = '"${q.text}"${q.author.isNotEmpty ? '\n— ${q.author}' : ''}${q.source != null ? '\n\nFuente: ${q.source}' : ''}';
    try {
      await Clipboard.setData(ClipboardData(text: content.trim()));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Frase copiada al portapapeles')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo copiar: ${e.toString()}')));
      }
    }
  }
}
