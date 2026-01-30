import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pazhoy/main.dart';

void main() {
  testWidgets('La app muestra el título PazHoy', (WidgetTester tester) async {
    // Construye la app y renderiza un frame
    await tester.pumpWidget(PazHoyApp());

    // Espera algunos frames para que se inicialicen los providers
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verifica que aparece el texto del título principal
    expect(find.text('PazHoy'), findsOneWidget);

    // Verifica que hay un AppBar con el icono de favoritos
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    // Verifications for new Search Toggle
    // 1. Verify Search Icon exists
    expect(find.byIcon(Icons.search), findsOneWidget);

    // 2. Verify TextField is initially hidden (optional, but good)
    expect(find.byType(TextField), findsNothing);

    // 3. Tap Search Icon to show TextField
    // Use widgetWithIcon to target the AppBar action specifically
    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();

    // 4. Verify TextField is now visible
    expect(find.byType(TextField), findsOneWidget);
  });
}
