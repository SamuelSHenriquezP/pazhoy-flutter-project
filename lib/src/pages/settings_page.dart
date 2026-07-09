// lib/src/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quotes_provider.dart';
import '../services/notification_service.dart';

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
    } else {
      await NotificationService.instance.cancel();
    }
    if (mounted) setState(() => _notifsEnabled = value);
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
