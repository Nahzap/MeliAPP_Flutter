import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../models/species_name.dart';
import '../services/botanical_service.dart';
import 'formal_catalog_table.dart';

/// Tabla de especies de una clase botánica: Nº, latín, nombre común.
class BotanicalClassTable extends StatelessWidget {
  final int tableIndex;
  final BotanicalClassGroup group;
  final bool expanded;
  final VoidCallback? onToggle;

  const BotanicalClassTable({
    super.key,
    required this.tableIndex,
    required this.group,
    this.expanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyMedium;
    final species = group.especies;
    final caption = catalogCaption(
      tableIndex,
      '${group.titulo} (n = ${species.length})',
    );
    final table = FormalCatalogTable(
      columns: const [
        FormalCatalogColumn(
          header: 'Nº',
          width: FixedColumnWidth(44),
          alignment: Alignment.centerRight,
        ),
        FormalCatalogColumn(
          header: 'Nombre científico',
          width: FlexColumnWidth(1.6),
        ),
        FormalCatalogColumn(
          header: 'Nombre común',
          width: FlexColumnWidth(1.2),
        ),
      ],
      rows: [
        for (var i = 0; i < species.length; i++)
          _speciesRow(
            i + 1,
            SpeciesName.fromParts(
              species[i].nombreCientifico,
              species[i].nombreComun,
            ),
            body,
          ),
      ],
    );

    if (onToggle == null) {
      return FormalCatalogTable(
        caption: caption,
        subtitle: group.descripcion,
        columns: table.columns,
        rows: table.rows,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.amber200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: AppTheme.amber50,
            borderRadius: expanded
                ? const BorderRadius.vertical(top: Radius.circular(7))
                : BorderRadius.circular(7),
            child: InkWell(
              onTap: onToggle,
              borderRadius: expanded
                  ? const BorderRadius.vertical(top: Radius.circular(7))
                  : BorderRadius.circular(7),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      height: 36,
                      margin: const EdgeInsets.only(right: 10, top: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            caption,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.slate800,
                                ),
                          ),
                          if (group.descripcion.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              group.descripcion,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.slate500),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          color: AppTheme.primaryDark,
                        ),
                        Text(
                          expanded ? 'Ocultar' : 'Ampliar',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: table,
            ),
        ],
      ),
    );
  }
}

/// Una tabla de clase a la vez, mismo ancho, en orden vertical.
class CatalogTableStack extends StatefulWidget {
  final List<BotanicalClassGroup> groups;
  final int firstTableIndex;

  const CatalogTableStack({
    super.key,
    required this.groups,
    this.firstTableIndex = 1,
  });

  @override
  State<CatalogTableStack> createState() => _CatalogTableStackState();
}

class _CatalogTableStackState extends State<CatalogTableStack> {
  int _openIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.groups.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          BotanicalClassTable(
            tableIndex: widget.firstTableIndex + i,
            group: widget.groups[i],
            expanded: _openIndex == i,
            onToggle: () {
              setState(() {
                _openIndex = _openIndex == i ? -1 : i;
              });
            },
          ),
        ],
      ],
    );
  }
}

/// Tabla de composición polínica (o conteo de clases) con numeración.
class CompositionCatalogTable extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final bool botanicalLabels;
  final bool valuesArePercent;
  final List<Color> swatches;
  final String? caption;
  final Widget? footer;

  const CompositionCatalogTable({
    super.key,
    required this.entries,
    required this.swatches,
    this.botanicalLabels = false,
    this.valuesArePercent = true,
    this.caption,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyMedium;
    final valueHeader = valuesArePercent ? '%' : 'n';
    final columns = botanicalLabels
        ? [
            const FormalCatalogColumn(
              header: 'Nº',
              width: FixedColumnWidth(52),
              alignment: Alignment.centerRight,
            ),
            const FormalCatalogColumn(
              header: 'Nombre científico',
              width: FlexColumnWidth(1.6),
            ),
            const FormalCatalogColumn(
              header: 'Nombre común',
              width: FlexColumnWidth(1.2),
            ),
            FormalCatalogColumn(
              header: valueHeader,
              width: const FixedColumnWidth(64),
              alignment: Alignment.centerRight,
            ),
          ]
        : [
            const FormalCatalogColumn(
              header: 'Nº',
              width: FixedColumnWidth(52),
              alignment: Alignment.centerRight,
            ),
            const FormalCatalogColumn(
              header: 'Clase',
              width: FlexColumnWidth(2),
            ),
            FormalCatalogColumn(
              header: valueHeader,
              width: const FixedColumnWidth(64),
              alignment: Alignment.centerRight,
            ),
          ];

    return FormalCatalogTable(
      caption: caption,
      columns: columns,
      footer: footer,
      rows: [
        for (var i = 0; i < entries.length; i++)
          _compositionRow(
            index: i + 1,
            label: entries[i].key,
            value: entries[i].value,
            swatch: swatches[i % swatches.length],
            body: body,
            botanical: botanicalLabels,
            percent: valuesArePercent,
          ),
      ],
    );
  }
}

List<Widget> _speciesRow(int number, SpeciesName name, TextStyle? body) {
  return [
    NumberCell(number),
    Text(
      name.scientific,
      style: body?.copyWith(
        fontStyle: FontStyle.italic,
        color: AppTheme.slate800,
      ),
    ),
    Text(
      name.hasDistinctCommon ? name.common! : '—',
      style: body?.copyWith(color: AppTheme.slate700),
    ),
  ];
}

List<Widget> _compositionRow({
  required int index,
  required String label,
  required double value,
  required Color swatch,
  required TextStyle? body,
  required bool botanical,
  required bool percent,
}) {
  final valueText = percent
      ? '${value.toStringAsFixed(1)} %'
      : '${value.round()}';
  final valueWidget = Text(
    valueText,
    style: body?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppTheme.slate800,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );

  if (!botanical) {
    return [
      NumberCell(index, swatch: swatch),
      Text(label, style: body?.copyWith(color: AppTheme.slate800)),
      valueWidget,
    ];
  }

  final name = SpeciesName.parse(label);
  return [
    NumberCell(index, swatch: swatch),
    Text(
      name.scientific,
      style: body?.copyWith(
        fontStyle: FontStyle.italic,
        color: AppTheme.slate800,
      ),
    ),
    Text(
      name.hasDistinctCommon ? name.common! : '—',
      style: body?.copyWith(color: AppTheme.slate700),
    ),
    valueWidget,
  ];
}
