import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pazhoy/src/models/quote.dart';
import 'package:pazhoy/src/providers/style_provider.dart';
import 'package:pazhoy/src/widgets/advanced_style_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('home_widget'),
          (_) async => null,
        );
  });

  test(
    'advanced design survives serialization with independent author and margins',
    () {
      const style = QuoteStyle(
        aspectRatio: QuoteCardAspectRatio.portrait,
        design: QuoteDesign(
          bold: true,
          italic: true,
          underline: true,
          verticalPosition: 1,
          marginTop: 12,
          marginRight: 30,
          marginBottom: 48,
          marginLeft: 24,
          authorSize: 22,
          authorColor: Colors.blue,
          showAuthor: false,
          gradientColors: [Colors.orange, Colors.pink, Colors.purple],
          gradientAngle: 120,
          backgroundBlur: 3,
          brightness: 0.1,
          contrast: 1.2,
          saturation: 0.5,
          frameWidth: 3,
          frameColor: Colors.amber,
          cornerRadius: 24,
          divider: QuoteDivider.diamond,
        ),
      );
      expect(QuoteStyle.fromJson(style.toJson()).toJson(), style.toJson());
      expect(QuoteStyle.fromJson({}).design.showAuthor, isTrue);
      expect(
        style.design.padding(99),
        const EdgeInsets.fromLTRB(24, 12, 30, 48),
      );
      expect(style.design.customGradient!.colors.length, 3);
    },
  );

  test(
    'undo groups a drag, redo restores it, and new edits discard redo',
    () async {
      final provider = StyleProvider();
      await provider.init();
      provider.beginEdit();
      for (final radius in [15.0, 20.0, 28.0]) {
        provider.updateDesign(
          provider.style.design.copyWith(cornerRadius: radius),
        );
      }
      provider.endEdit();
      provider.undo();
      expect(provider.style.design.cornerRadius, 12);
      expect(provider.canUndo, isFalse);
      provider.redo();
      expect(provider.style.design.cornerRadius, 28);
      provider.undo();
      provider.setTextColor(Colors.red);
      expect(provider.canRedo, isFalse);
      await provider.flushPendingChanges();
      final reopened = StyleProvider();
      await reopened.init();
      expect(reopened.style.textColor.toARGB32(), Colors.red.toARGB32());
      expect(reopened.style.design.cornerRadius, 12);
      provider.dispose();
      reopened.dispose();
    },
  );

  test(
    'named styles restore all settings, update by name, and persist deletion',
    () async {
      final provider = StyleProvider();
      await provider.init();
      provider.setAspectRatio(QuoteCardAspectRatio.landscape);
      provider.updateDesign(
        provider.style.design.copyWith(bold: true, authorSize: 20),
      );
      final colors = [Colors.teal, Colors.blue];
      provider.setCustomGradient(colors, angle: 90);
      colors[0] = Colors.red;
      expect(provider.style.design.gradientColors!.first, Colors.teal);
      await provider.saveNamedStyle('  Serenidad  ');
      provider.resetStyle();
      provider.applySavedStyle(provider.savedStyles.single);
      expect(provider.style.design.bold, isTrue);
      expect(provider.style.aspectRatio, QuoteCardAspectRatio.landscape);
      provider.updateDesign(provider.style.design.copyWith(authorSize: 24));
      await provider.saveNamedStyle('Serenidad');
      expect(provider.savedStyles.length, 1);
      await provider.flushPendingChanges();
      final reopened = StyleProvider();
      await reopened.init();
      expect(reopened.savedStyles.single.style.design.authorSize, 24);
      await reopened.deleteSavedStyle(reopened.savedStyles.single.id);
      final third = StyleProvider();
      await third.init();
      expect(third.savedStyles, isEmpty);
      provider.dispose();
      reopened.dispose();
      third.dispose();
    },
  );

  test(
    'neutral background filter preserves RGB and malformed values stay usable',
    () {
      expect(const QuoteDesign().backgroundColorMatrix, [
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
      final restored = QuoteDesign.fromJson({
        'contrast': -10,
        'backgroundBlur': 500,
        'marginLeft': -1,
        'divider': 'broken',
      });
      expect(restored.contrast, 0.5);
      expect(restored.backgroundBlur, 20);
      expect(restored.marginLeft, 0);
      expect(restored.divider, QuoteDivider.none);
    },
  );

  testWidgets(
    'advanced editor updates text, undo, and all tabs on a phone-sized surface',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await (FontLoader('UiPreview')
            ..addFont(rootBundle.load('assets/google_fonts/Lato-Regular.ttf')))
          .load();
      final provider = StyleProvider();
      await provider.init();
      final key = GlobalKey();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'UiPreview'),
            home: RepaintBoundary(
              key: key,
              child: Scaffold(
                body: AdvancedStyleEditor(
                  previewQuote: Quote(
                    id: 1,
                    text: 'Respira y encuentra calma en este momento.',
                    author: 'Paz Hoy',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Negrita'));
      await tester.pumpAndSettle();
      expect(provider.style.design.bold, isTrue);
      await tester.tap(find.byTooltip('Deshacer'));
      await tester.pumpAndSettle();
      expect(provider.style.design.bold, isFalse);
      for (final tab in ['Composición', 'Fondo', 'Decoración', 'Mis estilos']) {
        await tester.ensureVisible(find.text(tab));
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.enterText(find.byType(TextField), 'Mi calma');
      await tester.pump();
      await tester.tap(find.text('Guardar estilo'));
      await tester.pumpAndSettle();
      expect(provider.savedStyles.single.name, 'Mi calma');
      await tester.tap(find.text('Decoración'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('verification')
          ..createSync(recursive: true);
        await File(
          '${directory.path}/advanced-editor-preview.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await provider.flushPendingChanges();
      provider.dispose();
      await tester.binding.setSurfaceSize(null);
    },
  );
}
