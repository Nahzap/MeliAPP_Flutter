import 'package:flutter/material.dart';
import '../models/lote_model.dart';
import '../services/taxa_service.dart';
import 'app_icon.dart';
import 'composition_pie_chart.dart';
import 'species_catalog_table.dart';

/// Card para mostrar resumen de un lote en la lista.
///
/// Muestra información básica y preview de las top 3 especies.
class LoteCard extends StatelessWidget {
  final Lote lote;
  final VoidCallback onTap;

  const LoteCard({super.key, required this.lote, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taxa = TaxaService.catalogOf(context);
    final composicion = taxa.labeledComposition(
      lote.parseComposicion(),
      lote: lote,
    );
    final especies = composicion.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = lote.getTotalComposicion();
    final isValid = lote.isComposicionValida();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono y datos principales
              Row(
                children: [
                  AppIcon(AppIcons.honey01, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lote ${lote.ordenMiel}: ${lote.nombreMiel}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lote.temporada,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (lote.hasCertificado || lote.isEstadoCertificacion)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 6,
                              children: [
                                if (lote.hasCertificado)
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: const Text('Certificado'),
                                    avatar: const Icon(
                                      Icons.verified,
                                      size: 16,
                                    ),
                                  ),
                                if (lote.isEstadoCertificacion)
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(lote.composicion ?? ''),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Badge de kg producidos
                  if (lote.kgProducidos != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${lote.kgProducidos!.toStringAsFixed(0)} kg',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Preview de composición
              Row(
                children: [
                  Icon(
                    Icons.local_florist,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Composición (${composicion.length} especies)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (especies.isNotEmpty)
                CompositionCatalogTable(
                  entries: especies.take(3).toList(),
                  swatches: CompositionPieChart.palette,
                  botanicalLabels: true,
                )
              else
                Text(
                  lote.isEstadoCertificacion
                      ? lote.composicion!
                      : 'Sin datos de composición',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),

              // Indicador de más especies
              if (composicion.length > 3) ...[
                const SizedBox(height: 4),
                Text(
                  '+ ${composicion.length - 3} especies más',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Footer con total y validación
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isValid ? Icons.check_circle : Icons.warning,
                        size: 16,
                        color: isValid ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Total:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${total.toStringAsFixed(2)} %',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isValid ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
