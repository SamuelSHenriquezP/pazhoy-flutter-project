// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'src/data/quotes_repository.dart';
import 'src/services/local_storage_service.dart';
import 'src/providers/style_provider.dart';
import 'src/providers/quotes_provider.dart';
import 'src/pages/home_page.dart';
import 'src/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable runtime font loading so the selected Google Fonts are actually
  // applied in the app and editor instead of falling back to the default font.
  GoogleFonts.config.allowRuntimeFetching = true;

  // CRÍTICO: registrar el ID del grupo de la app para que home_widget pueda
  // escribir en las SharedPreferences que el widget nativo de Android lee.
  // Sin esto, todos los HomeWidget.saveWidgetData son ignorados silenciosamente.
  await HomeWidget.setAppGroupId('com.example.pazhoy');

  final storage = LocalStorageService();
  try {
    await storage.init();
  } catch (e, st) {
    debugPrint('Error al inicializar LocalStorageService: $e\n$st');
  }

  // Inicializar notificaciones de forma asíncrona sin bloquear el inicio de la app
  NotificationService.instance.init().catchError((e, st) {
    debugPrint('Error al inicializar NotificationService de forma asíncrona: $e\n$st');
  });

  final repo = QuotesRepository();
  final quotesProvider = QuotesProvider(repo: repo, storage: storage)..init();

  runApp(PazHoyApp(repo: repo, storage: storage, quotesProvider: quotesProvider));
}

class PazHoyApp extends StatelessWidget {
  final QuotesRepository repo;
  final LocalStorageService storage;
  final QuotesProvider? quotesProvider;

  PazHoyApp({
    super.key,
    QuotesRepository? repo,
    LocalStorageService? storage,
    this.quotesProvider,
  }) : repo = repo ?? QuotesRepository(),
       storage = storage ?? LocalStorageService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (quotesProvider != null)
          ChangeNotifierProvider.value(value: quotesProvider!)
        else
          ChangeNotifierProvider(
            create: (_) => QuotesProvider(repo: repo, storage: storage)..init(),
          ),
        ChangeNotifierProvider(create: (_) => StyleProvider()..init()),
      ],
      child: const _LifecycleWatcher(child: MaterialAppWrapper()),
    );
  }
}

class MaterialAppWrapper extends StatelessWidget {
  const MaterialAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Colors.indigo;
    const boneColor = Color(0xFFFFFEFA);

    return MaterialApp(
      title: 'PazHoy',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: boneColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: boneColor,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _LifecycleWatcher extends StatefulWidget {
  final Widget child;
  const _LifecycleWatcher({required this.child});

  @override
  State<_LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<_LifecycleWatcher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final provider = Provider.of<QuotesProvider>(context, listen: false);
      provider.refreshPublished();
      // CRÍTICO: Sincronizar el widget cuando la app vuelve al foreground
      provider.syncWidgetData();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}



