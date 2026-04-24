// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'src/data/quotes_repository.dart';
import 'src/services/local_storage_service.dart';
import 'src/providers/style_provider.dart';
import 'src/providers/quotes_provider.dart';
import 'src/providers/theme_provider.dart';
import 'src/pages/home_page.dart';
import 'src/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = LocalStorageService();
  await storage.init();

  await NotificationService.instance.init();

  // Preload the fonts used in the app so the first frame renders correctly
  await GoogleFonts.pendingFonts([
    GoogleFonts.lato(),
    GoogleFonts.roboto(),
    GoogleFonts.merriweather(),
    GoogleFonts.montserrat(),
    GoogleFonts.oswald(),
    GoogleFonts.playfairDisplay(),
    GoogleFonts.dancingScript(),
    GoogleFonts.pacifico(),
    GoogleFonts.anton(),
    GoogleFonts.lobster(),
  ]);

  final repo = QuotesRepository();
  runApp(PazHoyApp(repo: repo, storage: storage));
}

class PazHoyApp extends StatelessWidget {
  final QuotesRepository repo;
  final LocalStorageService storage;

  PazHoyApp({super.key, QuotesRepository? repo, LocalStorageService? storage})
    : repo = repo ?? QuotesRepository(),
      storage = storage ?? LocalStorageService();
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => QuotesProvider(repo: repo, storage: storage)..init(),
        ),
        ChangeNotifierProvider(create: (_) => StyleProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
      ],
      child: const _LifecycleWatcher(child: MaterialAppWrapper()),
    );
  }
}

class MaterialAppWrapper extends StatelessWidget {
  const MaterialAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;

    const seedColor = Colors.indigo;
    const boneColor = Color(0xFFFFFEFA);

    return MaterialApp(
      title: 'PazHoy',
      themeMode: themeMode,
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
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
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
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
