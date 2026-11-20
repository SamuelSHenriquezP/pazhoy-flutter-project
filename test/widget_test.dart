import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pazhoy/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock the home_widget method channel
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('home_widget'),
    (MethodCall methodCall) async {
      return null;
    },
  );

  testWidgets('La app abre directamente en la frase del día en la página principal', (WidgetTester tester) async {
    await tester.pumpWidget(PazHoyApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // La app debe abrir directamente en HomePage. Buscamos los tooltips de la nueva barra de navegación.
    expect(find.byTooltip('Favoritos'), findsOneWidget);
    expect(find.byTooltip('Configuración'), findsOneWidget);
  });

  testWidgets('settings have no Premium purchase entry with old premium preferences', (tester) async {
    SharedPreferences.setMockInitialValues({'is_premium': true});
    await tester.pumpWidget(PazHoyApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byTooltip('Configuración'));
    await tester.pumpAndSettle();
    expect(find.text('Colaborador Premium'), findsNothing);
    expect(find.text('Apoya PazHoy'), findsNothing);
    expect(find.textContaining('Conviértete en colaborador'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
