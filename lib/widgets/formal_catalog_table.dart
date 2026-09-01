import 'package:flutter/material.dart';
import '../config/theme_config.dart';

/// Numeración romana para títulos de tabla (Tabla I, II, …).
String catalogRoman(int n) {
  if (n <= 0) return '';
  const digits = <(int, String)>[
    (1000, 'M'),
    (900, 'CM'),
    (500, 'D'),
    (400, 'CD'),
    (100, 'C'),
    (90, 'XC'),
    (50, 'L'),
    (40, 'XL'),
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ];
  final buffer = StringBuffer();
  var remaining = n;
  for (final pair in digits) {
    while (remaining >= pair.$1) {
      buffer.write(pair.$2);
      remaining -= pair.$1;
    }
  }
  return buffer.toString();
}

String catalogCaption(int index, String title) {
  return 'Tabla ${catalogRoman(index)}. $title';
}

class FormalCatalogColumn {
  final String header;
  final TableColumnWidth width;
  final Alignment alignment;

  const FormalCatalogColumn({
    required this.header,
    this.width = const FlexColumnWidth(),
    this.alignment = Alignment.centerLeft,
  });
}

/// Tabla de catálogo con grilla, encabezado y filas numerables.
class FormalCatalogTable extends StatelessWidget {
  final String? caption;
  final String? subtitle;
  final List<FormalCatalogColumn> columns;
  final List<List<Widget>> rows;
  final Widget? footer;

  const FormalCatalogTable({
    super.key,
    this.caption,
    this.subtitle,
    required this.columns,
    required this.rows,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (caption != null) ...[
          Text(
            caption!,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          Text(
            subtitle!,
            style: textTheme.bodySmall?.copyWith(
              color: AppTheme.slate500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Table(
          border: TableBorder(
            top: const BorderSide(color: AppTheme.primaryDark, width: 1.6),
            bottom: const BorderSide(color: AppTheme.primaryDark, width: 1.6),
            left: const BorderSide(color: AppTheme.amber200),
            right: const BorderSide(color: AppTheme.amber200),
            horizontalInside: const BorderSide(color: AppTheme.amber200),
            verticalInside: const BorderSide(color: AppTheme.amber200),
          ),
          columnWidths: {
            for (var i = 0; i < columns.length; i++) i: columns[i].width,
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: AppTheme.amber100),
              children: [
                for (final column in columns)
                  _HeaderCell(text: column.header, alignment: column.alignment),
              ],
            ),
            for (var i = 0; i < rows.length; i++)
              TableRow(
                decoration: BoxDecoration(
                  color: i.isEven ? Colors.white : AppTheme.amber50,
                ),
                children: [
                  for (var c = 0; c < columns.length; c++)
                    _BodyCell(
                      alignment: columns[c].alignment,
                      child: c < rows[i].length
                          ? rows[i][c]
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
          ],
        ),
        if (footer != null) ...[const SizedBox(height: 8), footer!],
      ],
    );
  }
}

class NumberCell extends StatelessWidget {
  final int number;
  final Color? swatch;

  const NumberCell(this.number, {super.key, this.swatch});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (swatch != null) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: swatch, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          '$number',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.slate700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final Alignment alignment;

  const _HeaderCell({required this.text, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Align(
        alignment: alignment,
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppTheme.slate800,
          ),
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final Alignment alignment;
  final Widget child;

  const _BodyCell({required this.alignment, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Align(alignment: alignment, child: child),
    );
  }
}
