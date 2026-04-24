// lib/src/pages/daily_quote_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quote.dart';
import '../providers/quotes_provider.dart';
import '../widgets/daily_quote_card.dart';

/// Pantalla completa que muestra la frase del día.
///
/// Se presenta automáticamente una vez al día al abrir la app.
/// El usuario puede favoritar la frase, compartirla o navegar
/// hasta ella en el listado principal.
class DailyQuotePage extends StatelessWidget {
  final Quote quote;

  /// Callback invocado cuando el usuario pulsa "Ver en el listado".
  /// Normalmente cierra esta página y hace scroll a la frase en el PageView.
  final VoidCallback? onViewInFeed;

  const DailyQuotePage({
    super.key,
    required this.quote,
    this.onViewInFeed,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotesProvider>();
    final isFav = provider.favorites.contains(quote.id);

    final now = DateTime.now();
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final dateStr =
        '${now.day} de ${months[now.month - 1]} de ${now.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Frase del día'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fecha
              Center(
                child: Text(
                  dateStr,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 24),
              // Tarjeta principal
              DailyQuoteCard(
                quote: quote,
                isFavorite: isFav,
                onToggleFavorite: () => provider.toggleFavorite(quote.id),
                onViewInFeed: onViewInFeed != null
                    ? () {
                        Navigator.pop(context);
                        onViewInFeed!();
                      }
                    : null,
              ),
              const SizedBox(height: 32),
              // Botón secundario para cerrar
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continuar explorando'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
