import 'package:flutter/services.dart';
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

    // La app debe abrir directamente en HomePage con la barra superior de "PazHoy"
    expect(find.text('PazHoy'), findsOneWidget);

    // Debe mostrar los botones de navegación principales de HomePage
    expect(find.byTooltip('Ver favoritos'), findsOneWidget);
    expect(find.byTooltip('Configuración'), findsOneWidget);
  });
}
