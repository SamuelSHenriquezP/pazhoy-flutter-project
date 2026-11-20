import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pazhoy/src/models/quote.dart';
import 'package:pazhoy/src/providers/style_provider.dart';
import 'package:pazhoy/src/widgets/quote_card.dart';

void main() {
  testWidgets(
    'all four export formats preserve advanced design and fit long text',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final loader = FontLoader('ExportPreview')
        ..addFont(rootBundle.load('assets/google_fonts/Lato-Regular.ttf'));
      await loader.load();
      final boundaryKey = GlobalKey();
      for (final item in [
        (
          ratio: QuoteCardAspectRatio.square,
          width: 1080,
          height: 1080,
          name: 'post',
        ),
        (
          ratio: QuoteCardAspectRatio.story,
          width: 1080,
          height: 1920,
          name: 'story',
        ),
        (
          ratio: QuoteCardAspectRatio.portrait,
          width: 1080,
          height: 1350,
          name: 'portrait',
        ),
        (
          ratio: QuoteCardAspectRatio.landscape,
          width: 1920,
          height: 1080,
          name: 'landscape',
        ),
      ]) {
        final size = item.ratio.exportLogicalSize;
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'ExportPreview'),
            home: RepaintBoundary(
              key: boundaryKey,
              child: QuoteCard(
                quote: Quote(
                  id: 1,
                  text: 'La paz comienza con una pausa. ' * 12,
                  author: 'Paz Hoy',
                ),
                isFavorite: true,
                onToggleFavorite: () {},
                exportOnly: true,
                styleOverride: QuoteStyle(
                  backgroundColor: const Color(0xFFF4EBDD),
                  textColor: const Color(0xFF36463B),
                  fontSize: 22,
                  aspectRatio: item.ratio,
                  design: const QuoteDesign(
                    bold: true,
                    italic: true,
                    underline: true,
                    verticalPosition: 1,
                    marginTop: 18,
                    marginRight: 30,
                    marginBottom: 36,
                    marginLeft: 24,
                    showAuthor: false,
                    frameWidth: 3,
                    frameColor: Color(0xFF94712C),
                    cornerRadius: 20,
                    divider: QuoteDivider.diamond,
                    gradientColors: [
                      Color(0xFFF4EBDD),
                      Color(0xFFD9E7D6),
                      Color(0xFFB8D5CB),
                    ],
                    gradientAngle: 60,
                    brightness: 0.05,
                    contrast: 1.1,
                    saturation: 0.7,
                    backgroundBlur: 2,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(IconButton), findsNothing);
        expect(find.textContaining('Paz Hoy'), findsNothing);
        final boundary =
            boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(
            pixelRatio: item.ratio.exportPixelRatio,
          );
          expect(image.width, item.width);
          expect(image.height, item.height);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('verification')
            ..createSync(recursive: true);
          await File(
            '${directory.path}/${item.name}-preview.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.binding.setSurfaceSize(null);
    },
  );
}
