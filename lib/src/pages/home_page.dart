// lib/src/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:ui';

import '../models/quote.dart';
import '../providers/quotes_provider.dart';
import 'details_page.dart';
import '../widgets/quote_card.dart';
import 'explore_page.dart';
import 'favorites_page.dart';
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
      // CRÍTICO: Sincronizar el widget cuando se carga la home page
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await provider.syncWidgetData();
        final streakResult = await provider.checkStreak();
        if (streakResult['increased'] == true && mounted) {
          _showStreakDialog(streakResult['streak'] as int);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _showStreakDialog(int streak) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_outlined, color: Colors.orange, size: 64),
            const SizedBox(height: 16),
            Text(
              '¡Racha de $streak día${streak > 1 ? 's' : ''}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              'Has vuelto a encontrar tu paz hoy. Sigue así.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
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
          onEdit: q.isCustom
              ? () => _showEditQuoteModal(context, provider, q)
              : null,
          onDelete: q.isCustom
              ? () => _confirmDeleteQuote(context, provider, q)
              : null,
        ),
      ),
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

  void _showEditQuoteModal(BuildContext context, QuotesProvider provider, Quote quote) {
    final formKey = GlobalKey<FormState>();
    final textController = TextEditingController(text: quote.text);
    final authorController = TextEditingController(
      text: quote.author == 'Yo' ? 'Yo' : quote.author,
    );
    final sourceController = TextEditingController(text: quote.source ?? '');

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
                        'Editar mi frase',
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

                        Navigator.pop(context);
                        textController.dispose();
                        authorController.dispose();
                        sourceController.dispose();

                        await provider.editCustomQuote(
                          id: quote.id,
                          text: text,
                          author: author.isNotEmpty ? author : null,
                          source: source.isNotEmpty ? source : null,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Frase actualizada')),
                          );
                        }
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
                      'Guardar Cambios',
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
      try { textController.dispose(); } catch (_) {}
      try { authorController.dispose(); } catch (_) {}
      try { sourceController.dispose(); } catch (_) {}
    });
  }

  Future<void> _confirmDeleteQuote(BuildContext context, QuotesProvider provider, Quote quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Eliminar frase', style: TextStyle(color: Colors.black)),
        content: Text(
          '¿Eliminar esta frase?\n\n«${quote.text.length > 80 ? '${quote.text.substring(0, 80)}...' : quote.text}»',
          style: const TextStyle(color: Colors.black87),
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
    if (confirmed == true) {
      await provider.deleteCustomQuote(quote.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Frase eliminada')),
        );
      }
    }
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

  Widget _buildFloatingIconButton(IconData icon, String tooltip, VoidCallback onPressed, {Color? color, Color? iconColor}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor ?? Colors.black87),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomDock(QuotesProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.75),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.home_outlined),
                  tooltip: 'Inicio (Frase del día)',
                  onPressed: () {
                    final idx = provider.dailyIndexLogical;
                    if (idx != null) {
                      _animateToLogicalIndex(idx, provider);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No hay frase del día disponible')),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.explore_outlined),
                  tooltip: 'Explorar / Buscar',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExplorePage()),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showCreateQuoteModal(context, provider),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  tooltip: 'Favoritos',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesPage()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Configuración',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotesProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: const Color(0xFFF3F4F6), // Base light color
      body: Stack(
        children: [
          // Dynamic elegant background layer
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Main Content Area
          GestureDetector(
            onTap: () {
              if (_isEditing) setState(() => _isEditing = false);
            },
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.only(bottom: _isEditing ? 300 : 0),
              child: _buildBody(provider),
            ),
          ),

          // Editor Overlay
          if (_isEditing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 30, // Elevated to not overlap completely
              child: ModernStyleEditor(),
            ),

          // Horizontal Action Bar for Shuffle, Save, Share, Personalize
          if (!_isEditing)
            Positioned(
              right: 0,
              left: 0,
              bottom: 100, // Just above the dock
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFloatingIconButton(Icons.shuffle, 'Aleatorio', () {
                    final list = provider.quotes;
                    if (list.isEmpty) return;
                    _animateToLogicalIndex(Random().nextInt(list.length), provider);
                  }),
                  const SizedBox(width: 16),
                  _buildFloatingIconButton(Icons.save_alt, 'Guardar', _saveImage),
                  const SizedBox(width: 16),
                  _buildFloatingIconButton(Icons.share, 'Compartir', _shareImage),
                  const SizedBox(width: 16),
                  _buildFloatingIconButton(Icons.palette_outlined, 'Personalizar estilo', () {
                    setState(() => _isEditing = true);
                  }),
                ],
              ),
            ),
            
          if (_isEditing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16, // Top right corner
              right: 20,
              child: _buildFloatingIconButton(Icons.check, 'Listo', () {
                setState(() => _isEditing = false);
              }, color: Colors.black, iconColor: Colors.white),
            ),

          // Bottom Glassmorphism Dock
          if (!_isEditing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(child: _buildBottomDock(provider)),
            ),
        ],
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
                    onEdit: q.isCustom
                        ? () => _showEditQuoteModal(context, provider, q)
                        : null,
                    onDelete: q.isCustom
                        ? () => _confirmDeleteQuote(context, provider, q)
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
