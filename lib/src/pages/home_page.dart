// lib/src/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../models/quote.dart';
import '../providers/quotes_provider.dart';
import 'details_page.dart';
import '../widgets/quote_card.dart';
import 'explore_page.dart'; // importa si lo añadiste

import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import '../widgets/modern_style_editor.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PageController? _pageController;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<QuotesProvider>();
    if (!provider.isLoading && _pageController == null) {
      final initial = provider.currentIndex;
      _pageController = PageController(initialPage: initial);
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _animateToLogicalIndex(int desiredLogical, QuotesProvider provider) {
    final controller = _pageController;
    final n = provider.quotes.length;
    if (controller == null || n == 0) return;
    final target = desiredLogical.clamp(0, n - 1);
    controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOut,
    );
    provider.setCurrentIndex(target);
  }

  void _openDetail(BuildContext context, Quote q, QuotesProvider provider) {
    final isFav = provider.favorites.contains(q.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuoteDetailPage(
          quote: q,
          isFavorite: isFav,
          onToggleFavorite: () => provider.toggleFavorite(q.id),
          heroTag: 'quote-${q.id}',
        ),
      ),
    );
  }

  void _showFavoritesModal(BuildContext context, QuotesProvider provider) {
    final favIds = provider.favorites;
    final favQuotes = provider.quotes
        .where((q) => favIds.contains(q.id))
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) {
        if (favQuotes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No tienes favoritos aún.'),
          );
        }
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: favQuotes.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final q = favQuotes[i];
              return ListTile(
                title: Text(
                  q.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: q.author.isNotEmpty ? Text(q.author) : null,
                onTap: () {
                  Navigator.pop(context);
                  final provider = context.read<QuotesProvider>();
                  final idx = provider.quotes.indexWhere(
                    (item) => item.id == q.id,
                  );
                  if (idx != -1) _animateToLogicalIndex(idx, provider);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _saveImage() async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = await _screenshotController.captureAndSave(
        directory.path,
        fileName: 'quote_save.png',
      );

      if (imagePath != null) {
        await Gal.putImage(imagePath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagen guardada en la galería')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar imagen: $e')));
      }
    }
  }

  Future<void> _shareImage() async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = await _screenshotController.captureAndSave(
        directory.path,
        fileName: 'quote_share.png',
      );

      if (imagePath != null) {
        await SharePlus.instance.share(
          ShareParams(
            text: '¡Mira esta frase en PazHoy!',
            files: [XFile(imagePath)],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sharing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al compartir imagen')),
        );
      }
    }
  }

  bool _isEditing = false;
  bool _showSearch = false; // New state for search toggle

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PazHoy'),
        // Inherits backgroundColor, surfaceTintColor, scrolledUnderElevation from Theme
        actions: [
          IconButton(
            icon: const Icon(Icons.search), // New Search Toggle
            tooltip: 'Buscar',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Frase del día',
            onPressed: () {
              final idx = provider.dailyIndexLogical;
              if (idx != null) {
                _animateToLogicalIndex(idx, provider);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No hay frase del día disponible'),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.explore),
            tooltip: 'Explorar',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExplorePage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Aleatorio',
            onPressed: () {
              final list = provider.quotes;
              if (list.isEmpty) return;
              final randomIndex = Random().nextInt(list.length);
              _animateToLogicalIndex(randomIndex, provider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Ver favoritos',
            onPressed: () => _showFavoritesModal(context, provider),
          ),
        ],
        bottom:
            _showSearch // Conditionally show search bar
            ? PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: _SearchField(),
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (_isEditing) {
                setState(() {
                  _isEditing = false;
                });
              }
            },
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.only(bottom: _isEditing ? 300 : 0),
              child: Column(children: [Expanded(child: _buildBody(provider))]),
            ),
          ),
          if (_isEditing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: ModernStyleEditor(),
            ),
        ],
      ),
      floatingActionButton: _isEditing
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'fab_save',
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 6,
                    tooltip: 'Guardar imagen',
                    onPressed: _saveImage,
                    child: const Icon(Icons.save_alt),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton(
                    heroTag: 'fab_share',
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 6,
                    tooltip: 'Compartir',
                    onPressed: _shareImage,
                    child: const Icon(Icons.share),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton(
                    heroTag: 'fab_edit',
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 6,
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                      });
                    },
                    child: Icon(
                      _isEditing ? Icons.check : Icons.palette_outlined,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBody(QuotesProvider provider) {
    if (provider.state == ViewState.error) {
      return _ErrorView(
        message: provider.errorMessage ?? 'Error desconocido',
        onRetry: provider.retry,
      );
    }

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildPageView(provider);
  }

  Widget _buildPageView(QuotesProvider provider) {
    final list = provider.quotes;
    if (list.isEmpty) {
      return const Center(child: Text('No hay frases para mostrar.'));
    }

    if (_pageController == null) {
      final initial = provider.currentIndex.clamp(0, list.length - 1);
      _pageController = PageController(initialPage: initial);
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: _pageController,
      itemCount: list.length,
      onPageChanged: provider.setCurrentIndex,
      itemBuilder: (context, index) {
        final q = list[index];
        final isFav = provider.favorites.contains(q.id);
        final isCurrent = index == provider.currentIndex;

        return Align(
          // Changed from Center to Align for visual positioning
          alignment: const Alignment(0.0, -0.2), // Shift slightly up
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 32,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Hero(
                tag: 'quote-${q.id}',
                child: Material(
                  color: Colors.transparent,
                  child: QuoteCard(
                    quote: q,
                    isFavorite: isFav,
                    onToggleFavorite: () => provider.toggleFavorite(q.id),
                    onTap: () => _openDetail(context, q, provider),
                    screenshotController: isCurrent
                        ? _screenshotController
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<QuotesProvider>();

    return TextField(
      onChanged: provider.setSearchTerm,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar frase o autor...',
        prefixIcon: const Icon(Icons.search),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '¡Ups! Algo salió mal',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
