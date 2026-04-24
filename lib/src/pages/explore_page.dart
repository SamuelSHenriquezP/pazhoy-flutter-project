// lib/src/pages/explore_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quotes_provider.dart';
import '../models/quote.dart';
import 'details_page.dart';

/// Página "Explorar" — tres pestañas: por Autor, por Origen y por Tema.
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotesProvider>();
    final authorCount = provider.groupByAuthor.keys.length;
    final sourceCount = provider.groupBySource.keys.length;
    final tagCount = provider.groupByTag.keys.length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Explorar'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Autores ($authorCount)'),
              Tab(text: 'Origen ($sourceCount)'),
              Tab(text: 'Temas ($tagCount)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGroupedList(
              context,
              provider.groupByAuthor,
              provider.sortedAuthors,
              'No hay autores disponibles',
            ),
            _buildGroupedList(
              context,
              provider.groupBySource,
              provider.sortedSources,
              'No hay orígenes disponibles',
            ),
            _buildGroupedList(
              context,
              provider.groupByTag,
              provider.sortedTags,
              'No hay temas disponibles',
              isTag: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Método genérico para construir las listas usando claves pre-ordenadas.
  Widget _buildGroupedList(
    BuildContext context,
    Map<String, List<Quote>> data,
    List<String> sortedKeys,
    String emptyMessage, {
    bool isTag = false,
  }) {
    if (sortedKeys.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedKeys.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final list = data[key];

        if (list == null) return const SizedBox.shrink();

        return ListTile(
          leading: isTag
              ? Chip(
                  label: Text(
                    '#',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withAlpha(80),
                  side: BorderSide.none,
                )
              : null,
          title: Text(key),
          subtitle: Text('${list.length} frase${list.length > 1 ? 's' : ''}'),
          onTap: () =>
              _openListByKey(context: context, title: key, quotes: list),
        );
      },
    );
  }

  void _openListByKey({
    required BuildContext context,
    required String title,
    required List<Quote> quotes,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ListByKeyPage(title: title, quotes: quotes),
      ),
    );
  }
}

/// Página que muestra la lista de frases para una clave específica (autor u origen).
class _ListByKeyPage extends StatelessWidget {
  final String title;
  final List<Quote> quotes;
  const _ListByKeyPage({required this.title, required this.quotes});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotesProvider>();
    final favorites = provider.favorites;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: quotes.isEmpty
          ? const Center(child: Text('No hay frases.'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: quotes.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final q = quotes[i];
                final isFav = favorites.contains(q.id);
                return ListTile(
                  title: Text(
                    q.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: q.author.isNotEmpty ? Text(q.author) : null,
                  trailing: IconButton(
                    tooltip: isFav
                        ? 'Quitar de favoritos'
                        : 'Agregar a favoritos',
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.redAccent : null,
                    ),
                    onPressed: () => provider.toggleFavorite(q.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuoteDetailPage(
                          quote: q,
                          isFavorite: isFav,
                          onToggleFavorite: () => provider.toggleFavorite(q.id),
                          heroTag: 'quote-explore-${q.id}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
