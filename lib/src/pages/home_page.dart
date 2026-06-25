// lib/src/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../models/quote.dart';
import '../providers/quotes_provider.dart';
import 'details_page.dart';
import '../widgets/quote_card.dart';
import 'explore_page.dart'; // importa si lo añadiste
import 'settings_page.dart';

import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import '../widgets/modern_style_editor.dart';
import '../widgets/empty_state.dart';

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
    final n = provider.quotes.length;
    if (!provider.isLoading && _pageController == null && n > 0) {
      final initial = (provider.dailyIndexLogical ?? provider.currentIndex).clamp(0, n - 1);
      _pageController = PageController(initialPage: initial);
      if (provider.currentIndex != initial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.setCurrentIndex(initial, persist: false);
        });
      }
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuoteDetailPage(
          quote: q,
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

  void _showCreateQuoteModal(BuildContext context, QuotesProvider provider) {
    final formKey = GlobalKey<FormState>();
    final textController = TextEditingController();
    final authorController = TextEditingController(text: 'Yo');
    final sourceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Crear mi propia frase',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: textController,
                    maxLines: 3,
                    maxLength: 250,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Frase o reflexión',
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintText: 'Escribe tu frase aquí...',
                      hintStyle: const TextStyle(color: Colors.black26),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Por favor escribe una frase';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: authorController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Autor',
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintText: 'Yo, Anónimo, Marco Aurelio...',
                      hintStyle: const TextStyle(color: Colors.black26),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sourceController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Origen / Libro (Opcional)',
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintText: 'Meditaciones, Diario 2026...',
                      hintStyle: const TextStyle(color: Colors.black26),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        final text = textController.text.trim();
                        final author = authorController.text.trim();
                        final source = sourceController.text.trim();

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);

                        // Liberar controladores al cerrar
                        textController.dispose();
                        authorController.dispose();
                        sourceController.dispose();

                        // Crear la frase
                        await provider.addCustomQuote(
                          text: text,
                          author: author.isNotEmpty ? author : null,
                          source: source.isNotEmpty ? source : null,
                        );

                        // Diferir la animación hasta que Flutter reconstruya el PageView
                        // con el nuevo elemento ya incluido
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final newIdx = provider.totalPublished - 1;
                          if (newIdx >= 0) {
                            _animateToLogicalIndex(newIdx, provider);
                          }
                        });

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('¡Frase creada con éxito! Desliza hasta el final para verla.'),
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Guardar Frase',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      // Liberar controladores si el usuario cierra sin guardar
      try { textController.dispose(); } catch (_) {}
      try { authorController.dispose(); } catch (_) {}
      try { sourceController.dispose(); } catch (_) {}
    });
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
            icon: const Icon(Icons.add_comment_rounded),
            tooltip: 'Crear frase',
            onPressed: () => _showCreateQuoteModal(context, provider),
          ),
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
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
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
      return const EmptyStateWidget(
        title: 'Sin frases',
        message: 'No hay frases disponibles en este momento.',
        icon: Icons.format_quote_rounded,
      );
    }

    if (_pageController == null && list.isNotEmpty) {
      final initial = (provider.dailyIndexLogical ?? provider.currentIndex).clamp(0, list.length - 1);
      _pageController = PageController(initialPage: initial);
      if (provider.currentIndex != initial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.setCurrentIndex(initial, persist: false);
        });
      }
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

class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    context.read<QuotesProvider>().setSearchTerm('');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<QuotesProvider>();
    // Keep controller in sync if term was cleared externally
    final term = context.select<QuotesProvider, String>((p) => p.searchTerm);
    if (_controller.text != term && term.isEmpty) {
      _controller.clear();
    }

    return TextField(
      controller: _controller,
      onChanged: provider.setSearchTerm,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar frase o autor...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: term.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Limpiar',
                onPressed: _clear,
              )
            : null,
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
