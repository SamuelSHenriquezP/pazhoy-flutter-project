import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pazhoy/src/providers/style_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('home_widget'), (
        MethodCall methodCall,
      ) async {
        return null;
      });

  group('QuoteStyle & StyleProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('QuoteStyle serializes and deserializes QuoteCardAspectRatio', () {
      for (final ratio in QuoteCardAspectRatio.values) {
        final style = QuoteStyle(
          fontFamily: 'Merriweather',
          backgroundColor: const Color(0xFFFAF8F5),
          textColor: const Color(0xFF1F2937),
          aspectRatio: ratio,
        );

        final jsonMap = style.toJson();
        expect(jsonMap['aspectRatio'], ratio.name);

        final restored = QuoteStyle.fromJson(jsonMap);
        expect(restored.aspectRatio, ratio);
        expect(restored.fontFamily, 'Merriweather');
        expect(restored.backgroundColor.toARGB32(), 0xFFFAF8F5);
      }
    });

    test(
      'missing background image is removed from memory and storage on load',
      () async {
        final saved = const QuoteStyle(
          backgroundImagePath: 'missing/background.jpg',
        );
        SharedPreferences.setMockInitialValues({
          'quote_style': jsonEncode(saved.toJson()),
        });
        final provider = StyleProvider();
        await provider.init();
        expect(provider.style.backgroundImagePath, isNull);
        final prefs = await SharedPreferences.getInstance();
        expect(
          jsonDecode(prefs.getString('quote_style')!)['backgroundImagePath'],
          isNull,
        );
        provider.dispose();
      },
    );

    test(
      'default font can be restored after selecting a custom font',
      () async {
        final provider = StyleProvider();
        await provider.init();
        provider.setFontFamily('Lato');
        provider.setFontFamily(null);
        expect(provider.style.fontFamily, isNull);
        provider.dispose();
      },
    );

    test(
      'QuoteStyle.fromJson falls back safely on missing or invalid aspectRatio',
      () {
        final fromMissing = QuoteStyle.fromJson(<String, dynamic>{});
        expect(fromMissing.aspectRatio, QuoteCardAspectRatio.auto);

        final fromInvalid = QuoteStyle.fromJson({
          'aspectRatio': 'unknown_ratio',
        });
        expect(fromInvalid.aspectRatio, QuoteCardAspectRatio.auto);

        final fromIndex = QuoteStyle.fromJson({
          'aspectRatio': QuoteCardAspectRatio.story.index,
        });
        expect(fromIndex.aspectRatio, QuoteCardAspectRatio.story);
      },
    );

    test('StyleProvider persists aspectRatio in SharedPreferences', () async {
      final provider = StyleProvider();
      await provider.init();
      expect(provider.style.aspectRatio, QuoteCardAspectRatio.auto);

      provider.setAspectRatio(QuoteCardAspectRatio.story);
      // Allow async _saveStyle() to flush to SharedPreferences
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final reloaded = StyleProvider();
      await reloaded.init();
      expect(reloaded.style.aspectRatio, QuoteCardAspectRatio.story);
    });

    test(
      'StyleProvider exposes 4 curated presets and applies them preserving aspectRatio',
      () async {
        expect(StyleProvider.presets.length, 4);
        expect(StyleProvider.presets.map((p) => p.name).toList(), [
          'Editorial',
          'Nocturno',
          'Papel cálido',
          'Minimal',
        ]);

        final provider = StyleProvider();
        await provider.init();
        provider.setAspectRatio(QuoteCardAspectRatio.square);

        final nocturno = StyleProvider.presets.firstWhere(
          (p) => p.id == 'nocturno',
        );
        provider.applyPreset(nocturno);

        expect(provider.style.fontFamily, 'Montserrat');
        expect(provider.style.backgroundColor.toARGB32(), 0xFF161B22);
        expect(provider.style.textColor.toARGB32(), 0xFFF3F4F6);
        expect(provider.style.aspectRatio, QuoteCardAspectRatio.square);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        final reloaded = StyleProvider();
        await reloaded.init();
        expect(reloaded.style.fontFamily, 'Montserrat');
        expect(reloaded.style.backgroundColor.toARGB32(), 0xFF161B22);
        expect(reloaded.style.aspectRatio, QuoteCardAspectRatio.square);
      },
    );
  });
}
