// lib/src/pages/explore_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quotes_provider.dart';
import '../models/quote.dart';
import '../models/quote_collection.dart';
import 'details_page.dart';
import '../widgets/empty_state.dart';

/// Página "Explorar" — tres pestañas: por Autor, por Origen y por Tema.
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotesProvider>();
    final authorCount = provider.groupByAuthor.keys.length;
    final sourceCount = provider.groupBySource.keys.length;
    final tagCount = provider.groupByTag.keys.length;

    final collectionsCount = provider.collections.length;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text('Explorar', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFF9FAFB),
          scrolledUnderElevation: 0,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Carpetas ($collectionsCount)'),
              Tab(text: 'Autores ($authorCount)'),
              Tab(text: 'Origen ($sourceCount)'),
              Tab(text: 'Temas ($tagCount)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCollectionsGrid(context, provider),
            _buildAuthorsList(context, provider.groupByAuthor, provider.sortedAuthors),
            _buildSourcesList(context, provider.groupBySource, provider.sortedSources),
            _buildTagsGrid(context, provider.groupByTag, provider.sortedTags),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorsList(BuildContext context, Map<String, List<Quote>> data, List<String> sortedKeys) {
    if (sortedKeys.isEmpty) return const EmptyStateWidget(title: 'Explorar', message: 'No hay autores', icon: Icons.person_off);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final list = data[key]!;
        // Generate a stable color based on author name
        final colorHue = (key.hashCode % 360).toDouble();
        final avatarColor = HSLColor.fromAHSL(1.0, colorHue, 0.6, 0.8).toColor();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: avatarColor,
              child: Text(
                key.isNotEmpty ? key.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            title: Text(key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            subtitle: Text('${list.length} frase${list.length > 1 ? 's' : ''}', style: TextStyle(color: Colors.grey.shade600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black26),
            onTap: () => _openListByKey(context: context, title: key, quotes: list),
          ),
        );
      },
    );
  }

  Widget _buildSourcesList(BuildContext context, Map<String, List<Quote>> data, List<String> sortedKeys) {
    if (sortedKeys.isEmpty) return const EmptyStateWidget(title: 'Explorar', message: 'No hay orígenes', icon: Icons.menu_book);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final list = data[key]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.menu_book_rounded, color: Colors.blueGrey.shade700),
            ),
            title: Text(key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            subtitle: Text('${list.length} frase${list.length > 1 ? 's' : ''}', style: TextStyle(color: Colors.grey.shade600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black26),
            onTap: () => _openListByKey(context: context, title: key, quotes: list),
          ),
        );
      },
    );
  }

  Widget _buildTagsGrid(BuildContext context, Map<String, List<Quote>> data, List<String> sortedKeys) {
    if (sortedKeys.isEmpty) return const EmptyStateWidget(title: 'Explorar', message: 'No hay temas', icon: Icons.tag);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final list = data[key]!;
        final colorHue = ((key.hashCode * 13) % 360).toDouble();
        final cardColor = HSLColor.fromAHSL(1.0, colorHue, 0.7, 0.9).toColor();
        final textColor = HSLColor.fromAHSL(1.0, colorHue, 0.8, 0.3).toColor();

        return InkWell(
          onTap: () => _openListByKey(context: context, title: '#$key', quotes: list),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: cardColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tag, color: textColor.withValues(alpha: 0.5), size: 28),
                const Spacer(),
                Text(
                  key,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${list.length} frase${list.length > 1 ? 's' : ''}',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: textColor.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openListByKey({required BuildContext context, required String title, required List<Quote> quotes}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _ListByKeyPage(title: title, quotes: quotes)));
  }

  Widget _buildCollectionsGrid(BuildContext context, QuotesProvider provider) {
    final collections = provider.collections;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: collections.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildCreateCollectionCard(context, provider);
        }
        
        final collection = collections[index - 1];
        final quotes = provider.quotes.where((q) => collection.quoteIds.contains(q.id)).toList();
        
        return InkWell(
          onTap: () => _openListByKey(
            context: context, 
            title: collection.name, 
            quotes: quotes,
          ),
          onLongPress: () => _showCollectionOptions(context, provider, collection),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: collection.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: collection.color.withValues(alpha: 0.3), 
                  blurRadius: 8, 
                  offset: const Offset(0, 4)
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_outlined, color: Colors.white70, size: 32),
                const Spacer(),
                Text(
                  collection.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${quotes.length} frase${quotes.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreateCollectionCard(BuildContext context, QuotesProvider provider) {
    return InkWell(
      onTap: () => _showCreateCollectionModal(context, provider),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.grey.shade400, size: 36),
            const SizedBox(height: 8),
            Text(
              'Nueva',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCollectionModal(BuildContext context, QuotesProvider provider) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    Color selectedColor = Colors.blueGrey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Nueva Carpeta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa un nombre' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Color de la carpeta', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Colors.blueGrey, Colors.indigo, Colors.teal, 
                          Colors.brown, Colors.deepOrange, Colors.pink
                        ].map((c) => GestureDetector(
                          onTap: () => setState(() => selectedColor = c),
                          child: Container(
                            width: 40, height: 40,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == c ? Colors.black : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          provider.createCollection(nameController.text.trim(), selectedColor);
                          Navigator.pop(ctx);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Crear'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }

  void _showCollectionOptions(BuildContext context, QuotesProvider provider, QuoteCollection collection) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Eliminar carpeta', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('¿Eliminar carpeta?'),
                      content: const Text('Las frases no se eliminarán, solo se borrará la carpeta.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                        FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    provider.deleteCollection(collection.id);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Página que muestra la lista de frases para una clave específica.
class _ListByKeyPage extends StatelessWidget {
  final String title;
  final List<Quote> quotes;
  const _ListByKeyPage({required this.title, required this.quotes});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotesProvider>();
    final favorites = provider.favorites;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF9FAFB),
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: quotes.isEmpty
          ? const EmptyStateWidget(title: 'Vacío', message: 'No hay frases para mostrar.', icon: Icons.format_quote_rounded)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: quotes.length,
              itemBuilder: (context, i) {
                final q = quotes[i];
                final isFav = favorites.contains(q.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuoteDetailPage(quote: q, heroTag: 'quote-explore-${q.id}'),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.format_quote_rounded, color: Colors.black12, size: 32),
                                const Spacer(),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
                                  icon: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    color: isFav ? Colors.redAccent : Colors.black26,
                                  ),
                                  onPressed: () => provider.toggleFavorite(q.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              q.text,
                              style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (q.author.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                '— ${q.author}',
                                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54, fontWeight: FontWeight.w500),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
