import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/style_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class StyleEditorSheet extends StatelessWidget {
  const StyleEditorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Texto'),
                Tab(text: 'Fondo'),
                Tab(text: 'Espaciado'),
                Tab(text: 'Efectos'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TextTab(),
                  _BackgroundTab(),
                  _SpacingTab(),
                  _EffectsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StyleProvider>();
    final fonts = [
      'Lato',
      'Roboto',
      'Merriweather',
      'Montserrat',
      'Oswald',
      'Playfair Display',
      'Dancing Script',
      'Pacifico',
      'Anton',
      'Lobster',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Tipografía', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: fonts.length,
            separatorBuilder: (c, i) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final font = fonts[index];
              final isSelected = provider.style.fontFamily == font;
              return ChoiceChip(
                label: Text(font, style: GoogleFonts.getFont(font)),
                selected: isSelected,
                onSelected: (_) => provider.setFontFamily(font),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Color del Texto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _ColorPicker(
          selectedColor: provider.style.textColor,
          onColorChanged: provider.setTextColor,
          colors: const [
            Colors.black87,
            Colors.white,
            Colors.grey,
            Colors.blueGrey,
            Colors.brown,
            Colors.indigo,
            Colors.redAccent,
            Colors.amber,
          ],
        ),
        const SizedBox(height: 24),
        const Text('Alineación', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<TextAlign>(
          segments: const [
            ButtonSegment(
              value: TextAlign.left,
              icon: Icon(Icons.format_align_left),
            ),
            ButtonSegment(
              value: TextAlign.center,
              icon: Icon(Icons.format_align_center),
            ),
            ButtonSegment(
              value: TextAlign.right,
              icon: Icon(Icons.format_align_right),
            ),
            ButtonSegment(
              value: TextAlign.justify,
              icon: Icon(Icons.format_align_justify),
            ),
          ],
          selected: {provider.style.textAlign},
          onSelectionChanged: (Set<TextAlign> newSelection) {
            provider.setTextAlign(newSelection.first);
          },
        ),
      ],
    );
  }
}

class _EffectsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StyleProvider>();
    final shadowColor = provider.style.textShadowColor;
    final outlineColor = provider.style.textOutlineColor;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Sombra ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Sombra', style: TextStyle(fontWeight: FontWeight.bold)),
            if (shadowColor != null)
              TextButton(
                onPressed: () => provider.setTextShadowColor(null),
                child: const Text('Quitar'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _ColorPicker(
          selectedColor: shadowColor ?? Colors.transparent,
          onColorChanged: provider.setTextShadowColor,
          colors: const [
            Colors.black,
            Colors.black54,
            Colors.grey,
            Colors.white,
            Colors.blue,
            Colors.red,
          ],
          includeTransparent: true,
        ),
        if (shadowColor != null) ...[
          const SizedBox(height: 16),
          const Text('Difuminado (Blur)'),
          Slider(
            value: provider.style.textShadowBlur,
            min: 0.0,
            max: 20.0,
            onChanged: provider.setTextShadowBlur,
          ),
        ],

        const Divider(height: 48),

        // --- Contorno ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Contorno',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (outlineColor != null)
              TextButton(
                onPressed: () => provider.setTextOutlineColor(null),
                child: const Text('Quitar'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _ColorPicker(
          selectedColor: outlineColor ?? Colors.transparent,
          onColorChanged: provider.setTextOutlineColor,
          colors: const [
            Colors.black,
            Colors.white,
            Colors.grey,
            Colors.indigo,
            Colors.red,
            Colors.amber,
          ],
          includeTransparent: true,
        ),
        if (outlineColor != null) ...[
          const SizedBox(height: 16),
          const Text('Grosor'),
          Slider(
            value: provider.style.textOutlineWidth,
            min: 0.5,
            max: 5.0,
            onChanged: provider.setTextOutlineWidth,
          ),
        ],
      ],
    );
  }
}

class _BackgroundTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StyleProvider>();
    final hasImage = provider.style.backgroundImagePath != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Imagen de Fondo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: provider.pickBackgroundImage,
                icon: const Icon(Icons.image),
                label: const Text('Galería'),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: provider.removeBackgroundImage,
                icon: const Icon(Icons.delete),
                tooltip: 'Quitar imagen',
              ),
            ],
          ],
        ),
        if (hasImage) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ajustes de Imagen',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: provider.resetImageSettings,
                child: const Text('Reiniciar'),
              ),
            ],
          ),
          const Text('Zoom'),
          Slider(
            value: provider.style.imageScale,
            min: 0.5,
            max: 3.0,
            onChanged: provider.setImageScale,
          ),
          const Text('Posición X'),
          Slider(
            value: provider.style.imageAlignment.x,
            min: -1.0,
            max: 1.0,
            onChanged: (v) => provider.setImageAlignment(
              Alignment(v, provider.style.imageAlignment.y),
            ),
          ),
          const Text('Posición Y'),
          Slider(
            value: provider.style.imageAlignment.y,
            min: -1.0,
            max: 1.0,
            onChanged: (v) => provider.setImageAlignment(
              Alignment(provider.style.imageAlignment.x, v),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Color de Fondo (Sólido)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _ColorPicker(
          selectedColor: provider.style.backgroundColor,
          onColorChanged: provider.setBackgroundColor,
          colors: [
            Colors.white,
            Colors.black,
            Colors.grey[200]!,
            Colors.amber[100]!,
            Colors.blue[50]!,
            Colors.pink[50]!,
            Colors.teal[50]!,
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Opacidad (Capa de Color)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: 1.0 - provider.style.opacity, // Invert logic
          min: 0.0,
          max: 1.0,
          onChanged: (val) => provider.setOpacity(1.0 - val),
        ),
      ],
    );
  }
}

class _SpacingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StyleProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Relleno (Padding)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: provider.style.contentPadding,
          min: 0.0,
          max: 64.0,
          onChanged: provider.setContentPadding,
        ),
        const SizedBox(height: 16),
        const Text(
          'Interlineado (Line Height)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: provider.style.lineHeight,
          min: 1.0,
          max: 3.0,
          onChanged: provider.setLineHeight,
        ),
        const SizedBox(height: 16),
        const Text(
          'Espaciado de Letras',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: provider.style.letterSpacing,
          min: -2.0,
          max: 10.0,
          onChanged: provider.setLetterSpacing,
        ),
        const SizedBox(height: 16),
        const Text(
          'Espaciado de Palabras',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: provider.style.wordSpacing,
          min: -2.0,
          max: 10.0,
          onChanged: provider.setWordSpacing,
        ),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final List<Color> colors;
  final bool includeTransparent;

  const _ColorPicker({
    required this.selectedColor,
    required this.onColorChanged,
    required this.colors,
    this.includeTransparent = false,
  });

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = selectedColor;
        return AlertDialog(
          title: const Text('Elige un color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) => tempColor = color,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                onColorChanged(tempColor);
                Navigator.of(context).pop();
              },
              child: const Text('Seleccionar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length + 1, // +1 for custom picker
        separatorBuilder: (c, i) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == colors.length) {
            // Custom color button
            return GestureDetector(
              onTap: () => _showColorPicker(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      Colors.red,
                      Colors.yellow,
                      Colors.green,
                      Colors.blue,
                      Colors.purple,
                      Colors.red,
                    ],
                  ),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            );
          }

          final color = colors[index];
          final isSelected = selectedColor.toARGB32() == color.toARGB32();

          // Special handling for transparent
          if (color == Colors.transparent && includeTransparent) {
            return GestureDetector(
              onTap: () => onColorChanged(color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: const Icon(Icons.block, color: Colors.red, size: 20),
              ),
            );
          }

          return GestureDetector(
            onTap: () => onColorChanged(color),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
