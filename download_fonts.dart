import 'dart:io';

void main() async {
  final Map<String, String> fonts = {
    'Lato': 'ofl/lato/Lato-Regular.ttf',
    'Roboto': 'ofl/roboto/Roboto-Regular.ttf',
    'Merriweather': 'ofl/merriweather/Merriweather-Regular.ttf',
    'Montserrat': 'ofl/montserrat/Montserrat-Regular.ttf',
    'Oswald': 'ofl/oswald/Oswald-Regular.ttf',
    'Playfair Display': 'ofl/playfairdisplay/PlayfairDisplay-Regular.ttf',
    'Dancing Script': 'ofl/dancingscript/DancingScript-Regular.ttf',
    'Pacifico': 'ofl/pacifico/Pacifico-Regular.ttf',
    'Anton': 'ofl/anton/Anton-Regular.ttf',
    'Lobster': 'ofl/lobster/Lobster-Regular.ttf',
  };

  final dir = Directory('assets/google_fonts');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final client = HttpClient();
  
  for (final font in fonts.keys) {
    print('Descargando $font...');
    try {
      final path = fonts[font]!;
      final url = Uri.parse('https://raw.githubusercontent.com/google/fonts/main/$path');
      
      final req = await client.getUrl(url);
      final res = await req.close();
      
      if (res.statusCode == 200) {
        final fileName = '${font.replaceAll(' ', '')}-Regular.ttf';
        final file = File('${dir.path}/$fileName');
        await res.pipe(file.openWrite());
        print('Guardado: $fileName');
      } else {
        print('Error HTTP ${res.statusCode} para $font');
      }
    } catch (e) {
      print('Error con $font: $e');
    }
  }
  
  client.close();
  print('Finalizado.');
}
