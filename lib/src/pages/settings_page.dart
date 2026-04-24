// lib/src/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadNotifPrefs();
  }

  Future<void> _loadNotifPrefs() async {
    final prefs = await NotificationService.instance.loadPrefs();
    if (mounted) {
      setState(() {
        _notifsEnabled = prefs.enabled;
        _notifTime = prefs.time;
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
          const SnackBar(
            content: Text('Permiso de notificaciones denegado'),
          ),
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const _SectionHeader(title: 'Apariencia'),
                _ThemeTile(themeProvider: themeProvider),
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
  final ThemeProvider themeProvider;
  const _ThemeTile({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioListTile<ThemeMode>(
          title: const Text('Sistema (automático)'),
          value: ThemeMode.system,
          groupValue: themeProvider.themeMode,
          onChanged: (v) => themeProvider.setThemeMode(v!),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Claro'),
          value: ThemeMode.light,
          groupValue: themeProvider.themeMode,
          onChanged: (v) => themeProvider.setThemeMode(v!),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Oscuro'),
          value: ThemeMode.dark,
          groupValue: themeProvider.themeMode,
          onChanged: (v) => themeProvider.setThemeMode(v!),
        ),
      ],
    );
  }
}
