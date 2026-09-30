// lib/src/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quotes_provider.dart';
import '../services/notification_service.dart';
import '../providers/premium_provider.dart';
import 'support_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifsEnabled = false;
  TimeOfDay _notifTime = const TimeOfDay(hour: 9, minute: 0);
  bool _loading = true;
  String _widgetMode = 'daily';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final storage = context.read<QuotesProvider>().storage;
    final prefs = await NotificationService.instance.loadPrefs();
    final widgetMode = await storage.getWidgetMode();
    if (mounted) {
      setState(() {
        _notifsEnabled = prefs.enabled;
        _notifTime = prefs.time;
        _widgetMode = widgetMode;
        _loading = false;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notifTime,
    );
    if (picked == null) return;
    setState(() => _notifTime = picked);
    if (_notifsEnabled) {
      await NotificationService.instance.scheduleDailyNotification(
        hour: picked.hour,
        minute: picked.minute,
      );
    }
  }

  Future<void> _toggleNotifs(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de notificaciones denegado')),
        );
        return;
      }
      await NotificationService.instance.scheduleDailyNotification(
        hour: _notifTime.hour,
        minute: _notifTime.minute,
      );
      if (mounted) setState(() => _notifsEnabled = true);
      return;
    }

    try {
      await NotificationService.instance.cancel();
      if (mounted) setState(() => _notifsEnabled = false);
    } catch (e, st) {
      debugPrint('Error cancelando notificaciones: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo desactivar las notificaciones')),
        );
      }
    }
  }

  Future<void> _setWidgetMode(String mode) async {
    final provider = context.read<QuotesProvider>();
    await provider.storage.setWidgetMode(mode);
    setState(() => _widgetMode = mode);
    await provider.syncWidgetData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mode == 'daily'
                ? 'El widget mostrará la frase del día'
                : mode == 'favorites'
                    ? 'El widget rotará entre tus favoritos'
                    : 'Modo de frase fijada activado',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotesProvider>();
    final hasFavorites = provider.favorites.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const _PremiumCard(),
                const _SectionHeader(title: 'Apariencia'),
                const _ThemeTile(),
                const Divider(),
                const _SectionHeader(title: 'Notificaciones'),
                SwitchListTile(
                  title: const Text('Frase del día'),
                  subtitle: const Text('Recordatorio diario'),
                  value: _notifsEnabled,
                  onChanged: _toggleNotifs,
                ),
                if (_notifsEnabled)
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Hora del recordatorio'),
                    trailing: Text(
                      _notifTime.format(context),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    onTap: _pickTime,
                  ),
                const Divider(),
                const _SectionHeader(title: 'Widget de pantalla de inicio'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Elige qué mostrará el widget de PazHoy en tu pantalla de inicio.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                RadioGroup<String>(
                  groupValue: _widgetMode,
                  onChanged: (v) {
                    if (v == null) return;
                    // No permitir cambiar a 'favorites' si no hay favoritos
                    if (v == 'favorites' && !hasFavorites) return;
                    _setWidgetMode(v);
                  },
                  child: Column(
                    children: [
                      const RadioListTile<String>(
                        title: Text('Frase del día'),
                        subtitle: Text('Muestra la frase más reciente publicada'),
                        secondary: Icon(Icons.wb_sunny_outlined),
                        value: 'daily',
                      ),
                      RadioListTile<String>(
                        title: const Text('Rotar entre favoritos'),
                        subtitle: Text(
                          hasFavorites
                              ? 'Cambia automáticamente cada 30 min o con el botón del widget'
                              : 'Agrega frases a favoritos para usar este modo',
                        ),
                        secondary: const Icon(Icons.favorite_outline),
                        value: 'favorites',
                      ),
                      if (_widgetMode == 'pinned')
                        const RadioListTile<String>(
                          title: Text('Frase fijada'),
                          subtitle: Text('Fijada manualmente desde la pantalla de detalle'),
                          secondary: Icon(Icons.push_pin_outlined),
                          value: 'pinned',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard();

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PremiumProvider>().isPremium;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SupportPage()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.secondaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isPremium ? Icons.favorite : Icons.volunteer_activism,
                color: colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? 'Colaborador Premium' : 'Apoya PazHoy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPremium
                          ? 'Gracias por hacer posible esta app.'
                          : 'Conviértete en colaborador y obtén extras.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.light_mode),
      title: const Text('Modo claro fijo'),
      subtitle: const Text('La aplicación usa siempre modo claro y mantiene los colores tal como están.'),
    );
  }
}
