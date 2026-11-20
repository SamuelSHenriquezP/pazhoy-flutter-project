import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quotes_provider.dart';
import 'details_page.dart';

class ReflectionHistoryPage extends StatelessWidget {
  const ReflectionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotesProvider>();
    final entries = provider.reflectionHistory.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reflexiones')),
      body: entries.isEmpty
          ? const Center(
              child: Text('Tus reflexiones diarias aparecerán aquí.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 28),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final parts = entry.key.split(':');
                final id = int.tryParse(parts.last);
                final quote = provider.quotes
                    .where((q) => q.id == id)
                    .firstOrNull;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_outline),
                  title: Text(entry.value),
                  subtitle: Text(
                    '${parts.first}${quote == null ? '' : '\n${quote.text}'}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: quote == null
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => QuoteDetailPage(
                              quote: quote,
                              heroTag: 'reflection-${entry.key}',
                            ),
                          ),
                        ),
                );
              },
            ),
    );
  }
}
