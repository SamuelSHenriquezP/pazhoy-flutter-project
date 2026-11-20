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
    final eventsCount = provider.events.length;
    final authorCount = provider.groupByAuthor.keys.length;
    final sourceCount = provider.groupBySource.keys.length;
    final tagCount = provider.groupByTag.keys.length;

    final collectionsCount = provider.collections.length;

    return DefaultTabController(
      length: 5,
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
              Tab(text: 'Eventos ($eventsCount)'),
              Tab(text: 'Carpetas ($collectionsCount)'),
              Tab(text: 'Autores ($authorCount)'),
              Tab(text: 'Origen ($sourceCount)'),
              Tab(text: 'Temas ($tagCount)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildEventsList(context, provider),
            _buildCollectionsGrid(context, provider),
            _buildAuthorsList(context, provider.groupByAuthor, provider.sortedAuthors),
            _buildSourcesList(context, provider.groupBySource, provider.sortedSources),
            _buildTagsGrid(context, provider.groupByTag, provider.sortedTags),
          ],
        ),
      ),
    );
  }

  IconData _eventIconFromKey(String key) {
    switch (key) {
      case 'auto_stories':
        return Icons.auto_stories_outlined;
      case 'favorite':
        return Icons.favorite_outline_rounded;
      case 'explore':
        return Icons.explore_outlined;
      case 'wb_twilight':
        return Icons.wb_twilight_rounded;
      case 'psychology':
        return Icons.psychology_outlined;
      case 'spa':
        return Icons.spa_outlined;
      case 'shield':
        return Icons.shield_outlined;
      case 'self_improvement':
        return Icons.self_improvement_outlined;
      case 'filter_vintage':
        return Icons.filter_vintage_outlined;
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'eco':
        return Icons.eco_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  String _formatShortDate(DateTime d) {
    const months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  Widget _buildEventsList(BuildContext context, QuotesProvider provider) {
    final events = provider.events;
    if (events.isEmpty) {
      return const EmptyStateWidget(
        title: 'Eventos',
        message: 'No hay temporadas programadas aún.',
        icon: Icons.event_outlined,
      );
    }

    final activeEvents = events.where((e) => e.isActive).toList();
    final upcomingEvents = events.where((e) => e.isUpcoming).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final completedEvents = events.where((e) => e.isCompleted).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final currentCycleUpcoming = upcomingEvents.take(12).toList();
    final futureCycleEvents = upcomingEvents.skip(12).toList();

    // Group future years cleanly so the primary list stays focused
    final futureByYear = <int, List<QuoteSeasonEvent>>{};
    for (final ev in futureCycleEvents) {
      futureByYear.putIfAbsent(ev.startDate.year, () => []).add(ev);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        if (activeEvents.isNotEmpty) ...[
          _buildEventsSectionTitle('EN CURSO AHORA'),
          const SizedBox(height: 10),
          for (final ev in activeEvents) _buildEventCard(context, ev, isHero: true),
          const SizedBox(height: 18),
        ],
        if (currentCycleUpcoming.isNotEmpty) ...[
          _buildEventsSectionTitle('PRÓXIMAS TEMPORADAS'),
          const SizedBox(height: 10),
          for (final ev in currentCycleUpcoming) _buildEventCard(context, ev),
        ],
        if (completedEvents.isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildEventsSectionTitle('TEMPORADAS COMPLETADAS'),
          const SizedBox(height: 10),
          for (final ev in completedEvents) _buildEventCard(context, ev),
        ],
        if (futureByYear.isNotEmpty) ...[
          const SizedBox(height: 14),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.only(top: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              title: Text(
                'Calendario futuro (${futureCycleEvents.length} temporadas)',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              children: [
                for (final entry in futureByYear.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildEventsSectionTitle('AÑO ${entry.key}'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        for (final ev in entry.value) _buildEventCard(context, ev),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEventsSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    QuoteSeasonEvent ev, {
    bool isHero = false,
  }) {
    final accent = ev.accentColor;
    final statusLabel = ev.isActive
        ? 'EN CURSO'
        : ev.isCompleted
            ? 'COMPLETADO'
            : 'PRÓXIMO';
    final dateRange = '${_formatShortDate(ev.startDate)} – ${_formatShortDate(ev.endDate)}';
    final progress = ev.allQuotes.isEmpty
        ? 0.0
        : (ev.unlockedQuotes.length / ev.allQuotes.length).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ev.isActive ? accent.withValues(alpha: 0.5) : Colors.grey.shade200,
          width: isHero ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: ev.isActive ? 0.06 : 0.03),
            blurRadius: isHero ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EventDetailPage(event: ev)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_eventIconFromKey(ev.iconKey), color: accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ev.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateRange,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ev.isActive
                            ? accent
                            : ev.isCompleted
                                ? Colors.grey.shade200
                                : accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          color: ev.isActive
                              ? Colors.white
                              : ev.isCompleted
                                  ? Colors.grey.shade700
                                  : accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Text(
                  ev.subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                if (ev.isActive || ev.isCompleted) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ev.isUpcoming
                          ? '${ev.allQuotes.length} días programados'
                          : '${ev.unlockedQuotes.length} de ${ev.allQuotes.length} días disponibles',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
                  ],
                ),
              ],
            ),
          ),
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
                                if (provider.hasReflection(q.id))
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10, top: 2),
                                    child: Tooltip(
                                      message: 'Tiene reflexión privada',
                                      child: Icon(
                                        Icons.edit_note_rounded,
                                        size: 19,
                                        color: Colors.blueGrey.shade400,
                                      ),
                                    ),
                                  ),
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

class EventDetailPage extends StatelessWidget {
  final QuoteSeasonEvent event;
  const EventDetailPage({super.key, required this.event});

  String _formatDate(DateTime d) {
    const months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotesProvider>();
    final favorites = provider.favorites;
    final accent = event.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: const Color(0xFFF9FAFB),
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: event.allQuotes.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.isActive
                        ? 'TEMPORADA EN CURSO'
                        : event.isCompleted
                            ? 'TEMPORADA COMPLETADA'
                            : 'PRÓXIMA TEMPORADA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.subtitle,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Del ${_formatDate(event.startDate)} al ${_formatDate(event.endDate)} · ${event.unlockedQuotes.length}/${event.allQuotes.length} disponibles',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: event.allQuotes.isEmpty
                          ? 0.0
                          : (event.unlockedQuotes.length / event.allQuotes.length).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      color: accent,
                    ),
                  ),
                ],
              ),
            );
          }

          final q = event.allQuotes[index - 1];
          final pd = q.publishDate;
          final isUnlocked = pd == null ||
              !DateTime.utc(pd.year, pd.month, pd.day).isAfter(event.todayUtc);
          final dayNum = index;

          if (!isUnlocked) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Día $dayNum de la temporada',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Disponible el ${_formatDate(pd)}',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final isFav = favorites.contains(q.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
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
                      builder: (_) => QuoteDetailPage(quote: q, heroTag: 'quote-event-${q.id}'),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Día $dayNum',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: accent),
                            ),
                          ),
                          if (provider.hasReflection(q.id)) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Tiene reflexión privada',
                              child: Icon(
                                Icons.edit_note_rounded,
                                size: 18,
                                color: accent.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
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
                      const SizedBox(height: 10),
                      Text(
                        q.text,
                        style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                      ),
                      if (q.author.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          '— ${q.author}${q.source != null ? ' · ${q.source}' : ''}',
                          style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                      ],
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
