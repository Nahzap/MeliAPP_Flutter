import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../models/lote_model.dart';
import '../../services/lotes_service.dart';
import '../../services/taxa_service.dart';
import '../../widgets/composition_pie_chart.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/formal_catalog_table.dart';
import 'certificado_document_screen.dart';

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
  final ScrollController _scrollController = ScrollController();
  Lote? _lote;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLote();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLote() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('[LOTE_DETAIL] Cargando lote: ${widget.loteId}');
      final lote = await _lotesService.getLote(widget.loteId);
      if (mounted) {
        await context.read<TaxaService>().ensureLoaded();
      }

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

    final taxa = TaxaService.catalogOf(context);
    final composicion = taxa.labeledComposition(
      _lote!.parseComposicion(),
      lote: _lote,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Lote ${_lote!.ordenMiel}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: _scrollToTop,
            tooltip: 'Ir arriba',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: _handleShowQR,
            tooltip: 'Ver QR',
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header decorativo
            _buildHeader(theme),

            // ⭐ Gráfico de composición PRIMERO (solicitud de jefatura)
            _buildCompositionSection(theme, composicion),

            // Información básica
            _buildInfoCard(theme),

            _buildObservaciones(theme),

            _buildCertificado(theme),

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
            if (_lote!.revisorNombre != null) ...[
              const Divider(),
              _buildInfoRow('Revisor', _lote!.revisorNombre!),
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
      final estado = _lote!.isEstadoCertificacion ? _lote!.composicion : null;
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                estado != null
                    ? Icons.hourglass_empty
                    : Icons.sentiment_dissatisfied,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                estado ?? 'Sin Datos de Composición',
                textAlign: TextAlign.center,
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
              child: CompositionPieChart(
                composicion: composicion,
                size: 280,
                botanicalLabels: true,
                tableCaption: catalogCaption(1, 'Composición polínica'),
              ),
            ),
            if (!_lote!.isComposicionValida()) ...[
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
                        'La composición no suma exactamente 100 %. Conviene revisar los datos.',
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

  Widget _buildObservaciones(ThemeData theme) {
    final apicultor = _lote!.observacionesApicultor;
    final revisor = _lote!.observacionesRevisor;
    if (apicultor == null && revisor == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Observaciones',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (apicultor != null) ...[
              const SizedBox(height: 12),
              Text('Apicultor', style: theme.textTheme.labelLarge),
              Text(apicultor),
            ],
            if (revisor != null) ...[
              const SizedBox(height: 12),
              Text('Revisor', style: theme.textTheme.labelLarge),
              Text(revisor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCertificado(ThemeData theme) {
    if (!_lote!.puedeMostrarCertificado) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Certificado de origen botánico',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CertificadoDocumentScreen(lote: _lote!),
                    ),
                  );
                },
                icon: const Icon(Icons.description_outlined),
                label: const Text('Ver documento'),
              ),
            ),
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

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _handleShowQR() async {
    final url =
        '${ApiConfig.baseUrl}/profile/${_lote!.authUserId}?lote=${_lote!.id}';
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
