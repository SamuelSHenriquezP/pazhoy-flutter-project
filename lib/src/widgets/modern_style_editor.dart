import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/style_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ModernStyleEditor extends StatefulWidget {
  const ModernStyleEditor({super.key});

  @override
  State<ModernStyleEditor> createState() => _ModernStyleEditorState();
}

class _ModernStyleEditorState extends State<ModernStyleEditor> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.text_fields, 'label': 'Texto'},
    {'icon': Icons.format_paint, 'label': 'Fondo'},
    {'icon': Icons.space_bar, 'label': 'Espacio'},
    {'icon': Icons.auto_awesome, 'label': 'Efectos'},
    {'icon': Icons.restart_alt, 'label': 'Reset'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Submenu Area (Animated)
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _selectedIndex == -1 ? 0 : 220, // Height for submenu
          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _selectedIndex == -1
              ? null
              : ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _buildSubmenuContent(_selectedIndex),
                  ),
                ),
        ),

        // Bottom Bar (Categories)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_categories.length, (index) {
              final isSelected = _selectedIndex == index;
              final cat = _categories[index];
              return GestureDetector(
                onTap: () {
                  if (cat['label'] == 'Reset') {
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: const Text(
                          'Resetear estilo',
                          style: TextStyle(color: Colors.black),
                        ),
                        content: const Text(
                          '¿Estás seguro de que deseas resetear el estilo de la tarjeta a su estado original?',
                          style: TextStyle(color: Colors.black87),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.read<StyleProvider>().resetStyle();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Resetear'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  setState(() {
                    if (_selectedIndex == index) {
                      // Toggle off if tapping same
                      // _selectedIndex = -1;
                      // User probably wants to keep it open, but let's keep it simple
                    } else {
                      _selectedIndex = index;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 16 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat['icon'],
                        color: isSelected ? Colors.white : Colors.grey,
                        size: 24,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          cat['label'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmenuContent(int index) {
    // Key is important for AnimatedSwitcher
    switch (index) {
      case 0:
        return _TextSubmenu(key: const ValueKey(0));
      case 1:
        return _BackgroundSubmenu(key: const ValueKey(1));
      case 2:
        return _SpacingSubmenu(key: const ValueKey(2));
      case 3:
        return _EffectsSubmenu(key: const ValueKey(3));
      default:
        return const SizedBox.shrink();
    }
  }
}

// --- Submenus (Ported Logic) ---

class _TextSubmenu extends StatelessWidget {
  const _TextSubmenu({super.key});

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
        const Text(
          'Tipografía',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
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
                showCheckmark: false,
                selectedColor: Colors.black,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Color',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _ColorPickerRow(
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
        const SizedBox(height: 16),
        const Text(
          'Alineación',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
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
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tamaño',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              '${provider.style.fontSize.toInt()}px',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        Slider(
          value: provider.style.fontSize,
          min: 10.0,
          max: 36.0,
          activeColor: Colors.black,
          onChanged: provider.setFontSize,
        ),
      ],
    );
  }
}

class _BackgroundSubmenu extends StatelessWidget {
  const _BackgroundSubmenu({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StyleProvider>();
    final hasImage = provider.style.backgroundImagePath != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: provider.pickBackgroundImage,
                icon: const Icon(Icons.image),
                label: const Text('Galería'),
                style: FilledButton.styleFrom(backgroundColor: Colors.black),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: provider.removeBackgroundImage,
                icon: const Icon(Icons.delete),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Color Sólido',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _ColorPickerRow(
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Opacidad',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              '${((1.0 - provider.style.opacity) * 100).toInt()}%',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        Slider(
          value:
              1.0 - provider.style.opacity, // Invert: 0->1 becomes 1->0 opacity
          min: 0.0,
          max: 1.0,
          activeColor: Colors.black,
          onChanged: (val) => provider.setOpacity(1.0 - val),
        ),
      ],
    );
  }
}

class _SpacingSubmenu extends StatelessWidget {
  const _SpacingSubmenu({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StyleProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SliderRow(
          label: 'Relleno',
          value: provider.style.contentPadding,
          min: 0.0,
          max: 64.0,
          onChanged: provider.setContentPadding,
        ),
        _SliderRow(
          label: 'Altura Línea',
          value: provider.style.lineHeight,
          min: 1.0,
          max: 3.0,
          onChanged: provider.setLineHeight,
        ),
        _SliderRow(
          label: 'Espacio Letras',
          value: provider.style.letterSpacing,
          min: -2.0,
          max: 10.0,
          onChanged: provider.setLetterSpacing,
        ),
      ],
    );
  }
}

class _EffectsSubmenu extends StatelessWidget {
  const _EffectsSubmenu({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StyleProvider>();
    final shadowColor = provider.style.textShadowColor;
    final outlineColor = provider.style.textOutlineColor;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sombra',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (shadowColor != null)
              TextButton(
                onPressed: () => provider.setTextShadowColor(null),
                child: const Text(
                  'Quitar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
        _ColorPickerRow(
          selectedColor: shadowColor ?? Colors.transparent,
          onColorChanged: provider.setTextShadowColor,
          colors: const [
            Colors.black,
            Colors.black54,
            Colors.grey,
            Colors.white,
          ],
          includeTransparent: true,
        ),
        if (shadowColor != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Difuminado', style: TextStyle(fontSize: 12)),
              Text(
                '${(provider.style.textShadowBlur / 20 * 100).toInt()}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          Slider(
            value: provider.style.textShadowBlur,
            min: 0.0,
            max: 20.0,
            activeColor: Colors.black,
            onChanged: provider.setTextShadowBlur,
          ),
        ],
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Contorno',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (outlineColor != null)
              TextButton(
                onPressed: () => provider.setTextOutlineColor(null),
                child: const Text(
                  'Quitar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
        _ColorPickerRow(
          selectedColor: outlineColor ?? Colors.transparent,
          onColorChanged: provider.setTextOutlineColor,
          colors: const [
            Colors.black,
            Colors.white,
            Colors.grey,
            Colors.indigo,
          ],
          includeTransparent: true,
        ),
        if (outlineColor != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grosor', style: TextStyle(fontSize: 12)),
              Text(
                '${((provider.style.textOutlineWidth - 0.5) / 4.5 * 100).toInt()}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          Slider(
            value: provider.style.textOutlineWidth,
            min: 0.5,
            max: 5.0,
            activeColor: Colors.black,
            onChanged: provider.setTextOutlineWidth,
          ),
        ],
      ],
    );
  }
}

// --- Helpers ---

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 30,
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: Colors.black,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ColorPickerRow extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final List<Color> colors;
  final bool includeTransparent;

  const _ColorPickerRow({
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
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length + 1,
        separatorBuilder: (c, i) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == colors.length) {
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
                    color: isSelected ? Colors.black : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
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
                  color: isSelected ? Colors.black : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
