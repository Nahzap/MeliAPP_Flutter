import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget de gráfico de torta para mostrar composición floral.
///
/// Usa fl_chart para visualizar porcentajes de especies.
class CompositionPieChart extends StatelessWidget {
  final Map<String, double> composicion;
  final double size;

  const CompositionPieChart({
    super.key,
    required this.composicion,
    this.size = 240, // +20% (200 * 1.2 = 240)
  });

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
        // Leyenda abajo con ancho completo
        _buildLegend(entries, context),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(
    List<MapEntry<String, double>> entries,
  ) {
    final colors = _getColors();

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final color = colors[index % colors.length];
      final isLarge = data.value > 10;

      return PieChartSectionData(
        value: data.value,
        title: isLarge ? '${data.value.toStringAsFixed(1)}%' : '',
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

  Widget _buildLegend(
    List<MapEntry<String, double>> entries,
    BuildContext context,
  ) {
    final colors = _getColors();

    return Column(
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final color = colors[index % colors.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _LegendItem(color: color, label: data.key, value: data.value),
        );
      }).toList(),
    );
  }

  List<Color> _getColors() {
    return [
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF97316), // Orange
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFA855F7), // Violet
    ];
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
