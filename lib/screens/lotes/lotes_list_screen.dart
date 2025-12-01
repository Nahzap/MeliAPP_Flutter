import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/lote_model.dart';
import '../../models/user_model.dart';
import '../../services/lotes_service.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/lote_card.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/composition_pie_chart.dart';

/// Pantalla que muestra la lista de lotes de miel del usuario.
///
/// Features:
/// - Lista de lotes ordenados por orden_miel
/// - Pull to refresh
/// - Empty state cuando no hay lotes
/// - Navegación a detalle de lote
class LotesListScreen extends StatefulWidget {
  final String? userId;

  const LotesListScreen({super.key, this.userId});

  @override
  State<LotesListScreen> createState() => _LotesListScreenState();
}

class _LotesListScreenState extends State<LotesListScreen> {
  final LotesService _lotesService = LotesService();
  final ApiService _apiService = ApiService();
  List<Lote> _lotes = [];
  User? _otherUser; // Info del otro usuario
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadLotes(),
      if (widget.userId != null) _loadOtherUserInfo(),
    ]);
  }

  Future<void> _loadOtherUserInfo() async {
    try {
      debugPrint(
        '[LOTES_LIST] Cargando info de otro usuario: ${widget.userId}',
      );
      final userData = await _apiService.getUserById(widget.userId!);
      setState(() {
        _otherUser = User.fromJson(userData);
      });
      debugPrint(
        '[LOTES_LIST] Info usuario cargada: ${_otherUser?.nombreCompleto}',
      );
    } catch (e) {
      debugPrint('[LOTES_LIST] Error cargando usuario: $e');
      // No bloqueamos la UI si falla la carga del usuario
    }
  }

  Future<void> _loadLotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Obtener userId
      final userId =
          widget.userId ??
          Provider.of<AuthProvider>(context, listen: false).user?.id;

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('[LOTES_LIST] Cargando lotes para usuario: $userId');
      final lotes = await _lotesService.getLotesUsuario(userId);

      setState(() {
        _lotes = lotes;
        _isLoading = false;
      });

      debugPrint('[LOTES_LIST] Cargados ${lotes.length} lotes');
    } catch (e) {
      debugPrint('[LOTES_LIST] Error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwnProfile =
        widget.userId == null || widget.userId == authProvider.user?.id;
    final title = isOwnProfile ? 'Mis Lotes' : 'Lotes Disponibles';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLotes,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando lotes...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    if (_lotes.isEmpty) {
      return _buildEmptyState();
    }

    return _buildLotesList();
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error al cargar lotes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLotes,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(AppIcons.honey01, size: 120),
            const SizedBox(height: 24),
            Text(
              'No hay lotes registrados',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Aún no se han registrado lotes de miel',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLotesList() {
    return RefreshIndicator(
      onRefresh: _loadLotes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _lotes.length + 1, // +1 para el header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader();
          }

          final lote = _lotes[index - 1];
          return LoteCard(lote: lote, onTap: () => _navigateToDetail(lote));
        },
      ),
    );
  }

  Widget _buildHeader() {
    final totalKg = _lotes.fold<double>(
      0,
      (sum, lote) => sum + (lote.kgProducidos ?? 0),
    );

    // Consolidar composición de todos los lotes
    final Map<String, double> consolidatedComposition = {};
    for (final lote in _lotes) {
      final especies = lote.getEspeciesOrdenadas();
      for (final entry in especies) {
        consolidatedComposition[entry.key] =
            (consolidatedComposition[entry.key] ?? 0) + entry.value;
      }
    }

    // Normalizar a porcentajes
    final totalPercent = consolidatedComposition.values.fold<double>(
      0,
      (sum, val) => sum + val,
    );
    if (totalPercent > 0) {
      consolidatedComposition.updateAll(
        (key, value) => (value / totalPercent) * 100,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Información del usuario (solo para otros usuarios)
          if (_otherUser != null) ...[
            _buildUserInfoCard(),
            const SizedBox(height: 16),
          ],

          // Gráfico de composición consolidada
          if (consolidatedComposition.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.eco,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Composición Polínica Total',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Análisis consolidado de ${_lotes.length} lote${_lotes.length != 1 ? 's' : ''}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    CompositionPieChart(composicion: consolidatedComposition),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // TOP 3 Ranking de Producción
          if (_lotes.length >= 3) _buildTop3Ranking(),
          if (_lotes.length >= 3) const SizedBox(height: 16),

          // Estadísticas de producción
          Card(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de Producción',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                        icon: Icons.inventory,
                        label: 'Lotes',
                        value: _lotes.length.toString(),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      _buildStat(
                        icon: Icons.scale,
                        label: 'Total Kg',
                        value: totalKg.toStringAsFixed(0),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      _buildStat(
                        icon: Icons.analytics,
                        label: 'Promedio',
                        value: _lotes.isNotEmpty
                            ? (totalKg / _lotes.length).toStringAsFixed(1)
                            : '0',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTop3Ranking() {
    // Ordenar lotes por kg_producidos descendente
    final topLotes = List<Lote>.from(_lotes)
      ..sort((a, b) => (b.kgProducidos ?? 0).compareTo(a.kgProducidos ?? 0));

    final top3 = topLotes.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Top 3 Lotes',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lotes con mayor producción',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ...top3.asMap().entries.map((entry) {
              final index = entry.key;
              final lote = entry.value;
              return _buildRankingItem(index + 1, lote);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingItem(int position, Lote lote) {
    // Colores y estrellas según posición
    final colors = {
      1: const Color(0xFFFFD700), // Oro
      2: const Color(0xFFC0C0C0), // Plata
      3: const Color(0xFFCD7F32), // Cobre/Bronce
    };

    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};

    final color = colors[position]!;
    final medal = medals[position]!;

    return InkWell(
      onTap: () => _navigateToDetail(lote),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Row(
          children: [
            // Icono de miel con medalla (70% más grande)
            SizedBox(
              width: 68,
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'MeliAPP_icons/honey02.png',
                    width: 68,
                    height: 68,
                    color: color,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Text(medal, style: const TextStyle(fontSize: 28)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Info del lote
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lote.nombreMiel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lote #${lote.ordenMiel}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Producción
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(lote.kgProducidos ?? 0).toStringAsFixed(0)} kg',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#$position',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    if (_otherUser == null) return const SizedBox.shrink();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icono apicultor
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'MeliAPP_icons/apicultor.png',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _otherUser!.nombreCompleto ?? _otherUser!.username,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_otherUser!.nombreEmpresa != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _otherUser!.nombreEmpresa!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Información de contacto
            Text(
              'Información de Contacto',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Email
            if (_otherUser!.email != null)
              _buildContactRow(
                Icons.email_outlined,
                'Correo',
                _otherUser!.email!,
              ),
            if (_otherUser!.email != null) const SizedBox(height: 8),

            // Teléfono
            if (_otherUser!.telefono != null)
              _buildContactRow(
                Icons.phone_outlined,
                'Teléfono',
                _otherUser!.telefono!,
              ),
            if (_otherUser!.telefono != null) const SizedBox(height: 8),

            // Ubicación
            if (_otherUser!.comuna != null || _otherUser!.region != null)
              _buildContactRowWithCustomIcon(
                'MeliAPP_icons/apiario01.png',
                'Ubicación',
                _otherUser!.comuna != null && _otherUser!.region != null
                    ? '${_otherUser!.comuna}, ${_otherUser!.region}'
                    : _otherUser!.comuna ?? _otherUser!.region ?? '',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRowWithCustomIcon(
    String iconPath,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Image.asset(
            iconPath,
            width: 20,
            height: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _navigateToDetail(Lote lote) {
    Navigator.pushNamed(context, '/lotes/detail', arguments: lote.id).then((_) {
      // Refresh después de volver del detalle
      _loadLotes();
    });
  }
}
