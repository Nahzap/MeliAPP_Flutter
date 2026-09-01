import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme_config.dart';
import 'species_catalog_table.dart';

/// Figura (torta) más tabla numerada de composición o clases.
class CompositionPieChart extends StatelessWidget {
  final Map<String, double> composicion;
  final double size;
  final bool botanicalLabels;
  final bool valuesArePercent;
  final String? tableCaption;

  const CompositionPieChart({
    super.key,
    required this.composicion,
    this.size = 240,
    this.botanicalLabels = false,
    this.valuesArePercent = true,
    this.tableCaption,
  });

  static const List<Color> palette = [
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF06B6D4),
    Color(0xFFA855F7),
  ];

  @override
  Widget build(BuildContext context) {
    if (composicion.isEmpty) {
      return SizedBox(
        height: size,
        child: const Center(
          child: Text(
            'Sin datos de composición',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final entries = composicion.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gráfico centrado arriba
        Center(
          child: SizedBox(
            width: size,
            height: size,
            child: PieChart(
              PieChartData(
                sections: _buildSections(entries),
                sectionsSpace: 2,
                centerSpaceRadius: size * 0.25,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        CompositionCatalogTable(
          entries: entries,
          swatches: palette,
          botanicalLabels: botanicalLabels,
          valuesArePercent: valuesArePercent,
          caption: tableCaption,
          footer: _totalFooter(context, entries),
        ),
      ],
    );
  }

  Widget _totalFooter(
    BuildContext context,
    List<MapEntry<String, double>> entries,
  ) {
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);
    final percent = valuesArePercent;
    final valid = !percent || (total - 100).abs() < 0.5;
    final label = percent
        ? '${total.toStringAsFixed(2)} %'
        : '${total.round()}';
    return Row(
      children: [
        Icon(
          valid ? Icons.check_circle_outline : Icons.warning_amber_outlined,
          size: 16,
          color: valid ? AppTheme.success : AppTheme.warning,
        ),
        const SizedBox(width: 6),
        Text(
          percent ? 'Total' : 'Total (n)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.slate700,
          ),
        ),
        const Spacer(),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valid ? AppTheme.slate800 : AppTheme.warning,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(
    List<MapEntry<String, double>> entries,
  ) {
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final color = palette[index % palette.length];
      final share = total <= 0 ? 0.0 : data.value / total;
      final isLarge = share > 0.12;

      return PieChartSectionData(
        value: data.value,
        title: isLarge
            ? (valuesArePercent
                  ? '${data.value.toStringAsFixed(1)}%'
                  : '${data.value.round()}')
            : '',
        color: color,
        radius: size * 0.25,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }
}
