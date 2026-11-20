import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../providers/style_provider.dart';
import '../providers/quotes_provider.dart';
import '../models/quote.dart';
import 'quote_card.dart';

class AdvancedStyleEditor extends StatelessWidget {
  final Quote? previewQuote;
  const AdvancedStyleEditor({super.key, this.previewQuote});

  static Future<void> show(BuildContext context) {
    final quotes = context.read<QuotesProvider>();
    final quote = quotes.quotes.isEmpty
        ? null
        : quotes.quotes[quotes.currentIndex.clamp(0, quotes.quotes.length - 1)];
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: AdvancedStyleEditor(previewQuote: quote),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StyleProvider>();
    final style = provider.style;
    final d = style.design;
    return DefaultTabController(
      length: 5,
      child: SizedBox(
        height:
            (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom) *
            0.86,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Edición avanzada',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Deshacer',
                      onPressed: provider.canUndo ? provider.undo : null,
                      icon: const Icon(Icons.undo),
                    ),
                    IconButton(
                      tooltip: 'Rehacer',
                      onPressed: provider.canRedo ? provider.redo : null,
                      icon: const Icon(Icons.redo),
                    ),
                    IconButton(
                      tooltip: 'Cerrar edición avanzada',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              if (previewQuote != null &&
                  MediaQuery.viewInsetsOf(context).bottom == 0)
                SizedBox(
                  height: 132,
                  child: Center(
                    child: SizedBox(
                      width: 220,
                      child: QuoteCard(
                        quote: previewQuote!,
                        isFavorite: false,
                        onToggleFavorite: () {},
                        exportOnly: true,
                        styleOverride:
                            style.aspectRatio == QuoteCardAspectRatio.auto
                            ? style.copyWith(
                                aspectRatio: QuoteCardAspectRatio.square,
                              )
                            : style,
                      ),
                    ),
                  ),
                ),
              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'Texto'),
                  Tab(text: 'Composición'),
                  Tab(text: 'Fondo'),
                  Tab(text: 'Decoración'),
                  Tab(text: 'Mis estilos'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _Panel(
                      children: [
                        const _Heading('Énfasis de la frase'),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('Negrita'),
                              selected: d.bold,
                              onSelected: (v) =>
                                  provider.updateDesign(d.copyWith(bold: v)),
                            ),
                            FilterChip(
                              label: const Text('Cursiva'),
                              selected: d.italic,
                              onSelected: (v) =>
                                  provider.updateDesign(d.copyWith(italic: v)),
                            ),
                            FilterChip(
                              label: const Text('Subrayado'),
                              selected: d.underline,
                              onSelected: (v) => provider.updateDesign(
                                d.copyWith(underline: v),
                              ),
                            ),
                          ],
                        ),
                        const _Heading('Autor'),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Mostrar autor y referencia'),
                          value: d.showAuthor,
                          onChanged: (v) =>
                              provider.updateDesign(d.copyWith(showAuthor: v)),
                        ),
                        _NumberControl(
                          label: 'Tamaño del autor',
                          value: d.authorSize,
                          min: 8,
                          max: 30,
                          onChanged: (v) =>
                              provider.updateDesign(d.copyWith(authorSize: v)),
                        ),
                        _ColorControl(
                          label: 'Color del autor',
                          color: d.authorColor ?? style.textColor,
                          onChanged: (v) =>
                              provider.updateDesign(d.copyWith(authorColor: v)),
                        ),
                        TextButton(
                          onPressed: () => provider.updateDesign(
                            d.copyWith(clearAuthorColor: true),
                          ),
                          child: const Text('Usar el color de la frase'),
                        ),
                      ],
                    ),
                    _Panel(
                      children: [
                        const _Heading('Posición vertical'),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final option in [
                              (value: -1.0, label: 'Arriba'),
                              (value: 0.0, label: 'Centro'),
                              (value: 1.0, label: 'Abajo'),
                            ])
                              ChoiceChip(
                                label: Text(option.label),
                                selected: d.verticalPosition == option.value,
                                onSelected: (_) => provider.updateDesign(
                                  d.copyWith(verticalPosition: option.value),
                                ),
                              ),
                          ],
                        ),
                        if (style.aspectRatio == QuoteCardAspectRatio.auto)
                          const Text(
                            'Elige un formato fijo para ver la posición vertical.',
                          ),
                        const _Heading('Márgenes independientes'),
                        _NumberControl(
                          label: 'Margen superior',
                          value: d.marginTop ?? style.contentPadding,
                          min: 0,
                          max: 80,
                          onChanged: (v) =>
                              provider.updateDesign(d.copyWith(marginTop: v)),
                        ),
                        _NumberControl(
                          label: 'Margen inferior',
                          value: d.marginBottom ?? style.contentPadding,
                          min: 0,
                          max: 80,
                          onChanged: (v) => provider.updateDesign(
                            d.copyWith(marginBottom: v),
                          ),
                        ),
                        _NumberControl(
                          label: 'Margen izquierdo',
                          value: d.marginLeft ?? style.contentPadding,
                          min: 0,
                          max: 80,
                          onChanged: (v) =>
                              provider.updateDesign(d.copyWith(marginLeft: v)),
                        ),
                        _NumberControl(
                          label: 'Margen derecho',
                          value: d.marginRight ?? style.contentPadding,
                          min: 0,
                          max: 80,
                          onChanged: (v) =>
                              provider.updateDesign(d.copyWith(marginRight: v)),
                        ),
                        TextButton(
                          onPressed: () => provider.updateDesign(
                            d.copyWith(clearMargins: true),
                          ),
                          child: const Text('Igualar los cuatro márgenes'),
                        ),
                        const _Heading('Formato de la imagen'),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final item in quoteFormatChoices)
                              ChoiceChip(
                                label: Text(item.label),
                                selected: style.aspectRatio == item.ratio,
                                onSelected: (_) =>
                                    provider.setAspectRatio(item.ratio),
                              ),
                          ],
                        ),
                      ],
                    ),
                    _Panel(
                      children: [
                        const _Heading('Degradado personalizado'),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Usar degradado propio'),
                          subtitle: const Text(
                            'Sustituye la imagen de fondo al activarlo.',
                          ),
                          value: d.gradientColors != null,
                          onChanged: (v) => provider.setCustomGradient(
                            v ? [style.backgroundColor, style.textColor] : null,
                          ),
                        ),
                        if (d.gradientColors != null) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Tres colores'),
                            value: d.gradientColors!.length == 3,
                            onChanged: (v) => provider.setCustomGradient(
                              v
                                  ? [
                                      d.gradientColors!.first,
                                      Color.lerp(
                                        d.gradientColors!.first,
                                        d.gradientColors!.last,
                                        0.5,
                                      )!,
                                      d.gradientColors!.last,
                                    ]
                                  : [
                                      d.gradientColors!.first,
                                      d.gradientColors!.last,
                                    ],
                            ),
                          ),
                          for (int i = 0; i < d.gradientColors!.length; i++)
                            _ColorControl(
                              label: 'Color ${i + 1}',
                              color: d.gradientColors![i],
                              onChanged: (color) {
                                final colors = List<Color>.from(
                                  d.gradientColors!,
                                );
                                colors[i] = color;
                                provider.setCustomGradient(colors);
                              },
                            ),
                          _NumberControl(
                            label: 'Dirección del degradado',
                            value: d.gradientAngle,
                            min: 0,
                            max: 360,
                            suffix: '°',
                            onChanged: (v) => provider.updateDesign(
                              d.copyWith(gradientAngle: v),
                            ),
                          ),
                        ],
                        const _Heading('Ajustes del fondo'),
                        const Text(
                          'Estos ajustes afectan al fondo; el texto conserva su color.',
                        ),
                        _NumberControl(
                          label: 'Desenfoque del fondo',
                          value: d.backgroundBlur,
                          min: 0,
                          max: 20,
                          onChanged: (v) => provider.updateDesign(
                            d.copyWith(backgroundBlur: v),
                          ),
                        ),
                        _NumberControl(
                          label: 'Brillo del fondo',
                          value: d.brightness,
                          min: -0.5,
                          max: 0.5,
                          onChanged: (v) =>
                              provider.updateDesign(d.copyWith(brightness: v)),
                        ),
                        _NumberControl(
                          label: 'Contraste del fondo',
                          value: d.contrast,
                          min: 0.5,
                          max: 1.5,
                          onChanged: (v) =>
                              provider.updateDesign(d.copyWith(contrast: v)),
                        ),
                        _NumberControl(
                          label: 'Saturación del fondo',
                          value: d.saturation,
                          min: 0,
                          max: 2,
                          onChanged: (v) =>
                              provider.updateDesign(d.copyWith(saturation: v)),
                        ),
                        TextButton(
                          onPressed: () => provider.updateDesign(
                            d.copyWith(
                              backgroundBlur: 0,
                              brightness: 0,
                              contrast: 1,
                              saturation: 1,
                            ),
                          ),
                          child: const Text('Restablecer ajustes del fondo'),
                        ),
                      ],
                    ),
                    _Panel(
                      children: [
                        const _Heading('Marco y esquinas'),
                        _NumberControl(
                          label: 'Grosor del marco',
                          value: d.frameWidth,
                          min: 0,
                          max: 8,
                          onChanged: (v) =>
                              provider.updateDesign(d.copyWith(frameWidth: v)),
                        ),
                        _ColorControl(
                          label: 'Color del marco',
                          color: d.frameColor,
                          onChanged: (v) =>
                              provider.updateDesign(d.copyWith(frameColor: v)),
                        ),
                        _NumberControl(
                          label: 'Redondeado de esquinas',
                          value: d.cornerRadius,
                          min: 0,
                          max: 40,
                          onChanged: (v) => provider.updateDesign(
                            d.copyWith(cornerRadius: v),
                          ),
                        ),
                        const _Heading('Separador decorativo'),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final item in [
                              (value: QuoteDivider.none, label: 'Ninguno'),
                              (value: QuoteDivider.line, label: 'Línea'),
                              (value: QuoteDivider.dots, label: 'Puntos'),
                              (value: QuoteDivider.diamond, label: 'Rombo'),
                            ])
                              ChoiceChip(
                                label: Text(item.label),
                                selected: d.divider == item.value,
                                onSelected: (_) => provider.updateDesign(
                                  d.copyWith(divider: item.value),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const _SavedStylesPanel(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const quoteFormatChoices = [
  (ratio: QuoteCardAspectRatio.auto, label: 'Auto'),
  (ratio: QuoteCardAspectRatio.square, label: '1:1'),
  (ratio: QuoteCardAspectRatio.story, label: '9:16'),
  (ratio: QuoteCardAspectRatio.portrait, label: '4:5'),
  (ratio: QuoteCardAspectRatio.landscape, label: '16:9'),
];

class _Panel extends StatelessWidget {
  final List<Widget> children;
  const _Panel({required this.children});
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(20), children: children);
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  );
}

class _NumberControl extends StatelessWidget {
  final String label;
  final double value, min, max;
  final String suffix;
  final ValueChanged<double> onChanged;
  const _NumberControl({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix = '',
  });
  @override
  Widget build(BuildContext context) {
    final provider = context.read<StyleProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('${value.toStringAsFixed(max <= 2 ? 2 : 0)}$suffix'),
          ],
        ),
        Slider(
          semanticFormatterCallback: (value) =>
              '$label ${value.toStringAsFixed(1)}$suffix',
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
          onChangeStart: (_) => provider.beginEdit(),
          onChangeEnd: (_) => provider.endEdit(),
        ),
      ],
    );
  }
}

class _ColorControl extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;
  const _ColorControl({
    required this.label,
    required this.color,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey),
      ),
    ),
    onTap: () async {
      Color selected = color;
      final result = await showDialog<Color>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(label),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: color,
              onColorChanged: (v) => selected = v,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selected),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      );
      if (result != null) onChanged(result);
    },
  );
}

class _SavedStylesPanel extends StatefulWidget {
  const _SavedStylesPanel();
  @override
  State<_SavedStylesPanel> createState() => _SavedStylesPanelState();
}

class _SavedStylesPanelState extends State<_SavedStylesPanel> {
  final _name = TextEditingController();
  bool _saving = false;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StyleProvider>();
    return _Panel(
      children: [
        const _Heading('Guardar el diseño actual'),
        TextField(
          controller: _name,
          maxLength: 40,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Nombre del estilo',
            hintText: 'Por ejemplo, Amanecer suave',
          ),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar estilo'),
          onPressed: _saving || _name.text.trim().isEmpty
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    await provider.saveNamedStyle(_name.text);
                    if (!mounted || !context.mounted) return;
                    _name.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Estilo guardado')),
                    );
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
        ),
        const _Heading('Mis estilos guardados'),
        if (provider.savedStyles.isEmpty)
          const Text('Guarda un diseño para reutilizarlo en otras frases.'),
        for (final preset in provider.savedStyles)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(preset.name),
            subtitle: const Text('Toca para aplicar'),
            leading: CircleAvatar(
              backgroundColor: preset.style.backgroundColor,
              child: Icon(Icons.format_quote, color: preset.style.textColor),
            ),
            onTap: () => provider.applySavedStyle(preset),
            trailing: IconButton(
              tooltip: 'Eliminar ${preset.name}',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => provider.deleteSavedStyle(preset.id),
            ),
          ),
      ],
    );
  }
}
