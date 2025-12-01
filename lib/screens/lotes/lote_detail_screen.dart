import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/lote_model.dart';
import '../../services/lotes_service.dart';
import '../../widgets/composition_pie_chart.dart';
import '../../widgets/app_icon.dart';

/// Pantalla de detalle de un lote de miel.
///
/// Muestra toda la información del lote y gráfico de composición floral.
class LoteDetailScreen extends StatefulWidget {
  final String loteId;

  const LoteDetailScreen({super.key, required this.loteId});

  @override
  State<LoteDetailScreen> createState() => _LoteDetailScreenState();
}

class _LoteDetailScreenState extends State<LoteDetailScreen> {
  final LotesService _lotesService = LotesService();
  Lote? _lote;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLote();
  }

  Future<void> _loadLote() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('[LOTE_DETAIL] Cargando lote: ${widget.loteId}');
      final lote = await _lotesService.getLote(widget.loteId);

      setState(() {
        _lote = lote;
        _isLoading = false;
      });

      debugPrint('[LOTE_DETAIL] Lote cargado: ${lote.nombreMiel}');
    } catch (e) {
      debugPrint('[LOTE_DETAIL] Error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _lote == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Lote no encontrado'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final composicion = _lote!.parseComposicion();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Lote ${_lote!.ordenMiel}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: _handleShowQR,
            tooltip: 'Ver QR',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header decorativo
            _buildHeader(theme),

            // ⭐ Gráfico de composición PRIMERO (solicitud de jefatura)
            _buildCompositionSection(theme, composicion),

            // Información básica
            _buildInfoCard(theme),

            // Lista detallada de especies
            _buildSpeciesDetailCard(theme),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          AppIcon(AppIcons.honey02, size: 80),
          const SizedBox(height: 16),
          Text(
            _lote!.nombreMiel,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _lote!.temporada,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Lote',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Orden', '#${_lote!.ordenMiel}'),
            const Divider(),
            _buildInfoRow(
              'Producción',
              '${_lote!.kgProducidos?.toStringAsFixed(2) ?? '0'} kg',
            ),
            const Divider(),
            _buildInfoRow('Fecha Registro', _formatDate(_lote!.fechaRegistro)),
            if (_lote!.fechaActualizacion != null) ...[
              const Divider(),
              _buildInfoRow(
                'Última Actualización',
                _formatDate(_lote!.fechaActualizacion),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompositionSection(
    ThemeData theme,
    Map<String, double> composicion,
  ) {
    if (composicion.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.sentiment_dissatisfied,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Sin Datos de Composición',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Composición Floral',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: CompositionPieChart(composicion: composicion, size: 280),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesDetailCard(ThemeData theme) {
    final especies = _lote!.getEspeciesOrdenadas();
    final total = _lote!.getTotalComposicion();
    final isValid = _lote!.isComposicionValida();

    if (especies.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalle por Especie',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...especies.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value.toStringAsFixed(2)}%',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.value / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isValid ? Icons.check_circle : Icons.warning,
                      size: 20,
                      color: isValid ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${total.toStringAsFixed(2)}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isValid ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            if (!isValid) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, size: 20, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'La composición no suma exactamente 100%. Considera revisar los datos.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          Text(value, style: const TextStyle(fontSize: 15, color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _handleShowQR() {
    // TODO: Implementar visualización de QR del lote
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Función QR próximamente')));
  }
}
