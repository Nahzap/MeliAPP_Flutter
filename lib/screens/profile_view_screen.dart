import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../models/lote_model.dart';
import '../models/ubicacion_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/botanical_service.dart';
import '../services/lotes_service.dart';
import '../services/taxa_service.dart';
import '../widgets/composition_pie_chart.dart';
import '../widgets/formal_catalog_table.dart';
import '../widgets/lote_card.dart';
import '../widgets/species_catalog_table.dart';

/// Visor de perfil MeliAPP Cloud (solo lectura).
///
/// Si [userId] es nulo, muestra el usuario autenticado.
class ProfileViewScreen extends StatefulWidget {
  final String? userId;
  final bool embedded;
  final int refreshToken;
  final ScrollController? scrollController;

  const ProfileViewScreen({
    super.key,
    this.userId,
    this.embedded = false,
    this.refreshToken = 0,
    this.scrollController,
  });

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  final _api = ApiService();
  final _lotesService = LotesService();
  final _floraService = BotanicalService();
  ScrollController? _ownedScroll;

  User? _user;
  List<Lote> _lotes = [];
  BotanicalClasses? _flora;
  bool _loading = true;
  String? _error;

  String? get _resolvedUserId {
    return widget.userId ??
        Provider.of<AuthProvider>(context, listen: false).user?.id;
  }

  bool get _isOwn {
    final current = Provider.of<AuthProvider>(context, listen: false).user?.id;
    return widget.userId == null || widget.userId == current;
  }

  ScrollController get _scroll =>
      widget.scrollController ?? (_ownedScroll ??= ScrollController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _ownedScroll?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfileViewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken ||
        oldWidget.userId != widget.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final isOwn = widget.userId == null || widget.userId == auth.user?.id;
      User? user = isOwn ? auth.user : null;
      final userId = widget.userId ?? user?.id;
      if (userId == null) {
        throw Exception('No hay usuario para mostrar');
      }

      if (!isOwn || user == null) {
        final raw = await _api.getUserById(userId);
        if (!mounted) return;
        user = User.fromJson(Map<String, dynamic>.from(raw));
      }

      final lotes = await _lotesService.getLotesUsuario(userId);
      if (!mounted) return;
      await context.read<TaxaService>().ensureLoaded();
      if (!mounted) return;
      final flora = await _floraService.getByComuna(user.comuna);
      if (!mounted) return;

      setState(() {
        _user = user;
        _lotes = lotes;
        _flora = flora;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[PROFILE] Error: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.displayName ?? 'Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            tooltip: 'Ir arriba',
            onPressed: _scrollToTop,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Abrir en MeliAPP Cloud',
            onPressed: _openCloudProfile,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: body,
    );
  }

  void _scrollToTop() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error ?? 'Perfil no encontrado'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final user = _user!;
    final totalKg = _lotes.fold<double>(
      0,
      (sum, lote) => sum + (lote.kgProducidos ?? 0),
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _buildHeader(user),
          const SizedBox(height: 12),
          _buildStats(user, totalKg),
          if (user.redesConValor.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildRedes(user),
          ],
          if (_hasContactChannels(user)) ...[
            const SizedBox(height: 12),
            _buildContacto(user),
          ],
          const SizedBox(height: 12),
          _buildUbicaciones(user),
          const SizedBox(height: 16),
          _buildFlora(),
          const SizedBox(height: 16),
          _buildLotes(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(User user) {
    final theme = Theme.of(context);
    final occupation = user.occupationLabel;
    final location = user.locationLabel;
    final empresa = user.nombreEmpresa?.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (user.isActive)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
                if (user.hasDistinctUsername)
                  Text(
                    '@${user.username}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                if (occupation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    occupation,
                    style: const TextStyle(
                      color: Color(0xFFFEF3C7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (location != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
                if (empresa != null && empresa.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    empresa,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(User user, double totalKg) {
    final lotes = _lotes.length;
    final apiarios = user.ubicaciones.length;
    final kg = _formatMagnitude(totalKg.round());

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            _metric(value: kg, unit: 'kg', caption: 'Producción'),
            _metricDivider(),
            _metric(value: '$lotes', caption: lotes == 1 ? 'Lote' : 'Lotes'),
            _metricDivider(),
            _metric(
              value: '$apiarios',
              caption: apiarios == 1 ? 'Apiario' : 'Apiarios',
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric({
    required String value,
    required String caption,
    String? unit,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    height: 1.1,
                  ),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _metricDivider() {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.grey[200],
    );
  }

  Widget _buildRedes(User user) {
    return Wrap(
      spacing: 8,
      children: user.redesConValor.entries.map((e) {
        return ActionChip(
          avatar: const Icon(Icons.link, size: 16),
          label: Text(e.key),
          onPressed: () => _openUrl(e.value),
        );
      }).toList(),
    );
  }

  bool _hasContactChannels(User user) {
    return (user.email != null && user.email!.trim().isNotEmpty) ||
        (user.telefono != null && user.telefono!.trim().isNotEmpty) ||
        (user.direccion != null && user.direccion!.trim().isNotEmpty);
  }

  Widget _buildContacto(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Contacto',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (user.email != null && user.email!.trim().isNotEmpty)
              _contactAction(
                icon: Icons.email_outlined,
                value: user.email!.trim(),
                onTap: () => _openUrl('mailto:${user.email!.trim()}'),
              ),
            if (user.telefono != null && user.telefono!.trim().isNotEmpty)
              _contactAction(
                icon: Icons.phone_outlined,
                value: user.telefono!.trim(),
                onTap: () => _openUrl(_telUri(user.telefono!.trim())),
              ),
            if (user.direccion != null && user.direccion!.trim().isNotEmpty)
              _contactAction(
                icon: Icons.home_outlined,
                value: user.direccion!.trim(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _contactAction({
    required IconData icon,
    required String value,
    VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  String _formatMagnitude(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) buffer.write('\u00A0');
      buffer.write(digits[i]);
    }
    return value < 0 ? '-$buffer' : buffer.toString();
  }

  String _telUri(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+')) return 'tel:$digits';
    if (digits.startsWith('56')) return 'tel:+$digits';
    return 'tel:$digits';
  }

  Widget _buildUbicaciones(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apiarios y ubicaciones',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (user.ubicaciones.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sin ubicaciones publicadas',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (_isOwn)
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse('${ApiConfig.baseUrl}/edit-profile'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Text('Completar en MeliAPP Cloud'),
                    ),
                ],
              )
            else
              ...user.ubicaciones.map(_ubicacionTile),
          ],
        ),
      ),
    );
  }

  Widget _ubicacionTile(Ubicacion ubicacion) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.hive_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(ubicacion.nombre),
      subtitle: Text(
        [
          if (ubicacion.descripcion != null) ubicacion.descripcion,
          if (ubicacion.hasCoordinates)
            '${ubicacion.latitud!.toStringAsFixed(5)}, ${ubicacion.longitud!.toStringAsFixed(5)}',
        ].join('\n'),
      ),
      trailing: ubicacion.hasCoordinates
          ? IconButton(
              icon: const Icon(Icons.map_outlined),
              onPressed: () => _openMaps(ubicacion),
            )
          : null,
    );
  }

  Widget _buildFlora() {
    final flora = _flora;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flora de la comuna',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (flora == null)
              Text(
                'No hay clases botánicas para esta comuna',
                style: TextStyle(color: Colors.grey[600]),
              )
            else ...[
              Text(
                '${flora.comuna}: ${flora.totalSpecies} especies en ${flora.totalClasses} clases',
                style: TextStyle(color: Colors.grey[700]),
              ),
              if (flora.classCounts.isNotEmpty) ...[
                const SizedBox(height: 16),
                CompositionPieChart(
                  composicion: flora.classCounts,
                  size: 200,
                  valuesArePercent: false,
                  tableCaption: catalogCaption(1, 'Clases botánicas'),
                ),
              ],
              if (flora.classes.isNotEmpty) ...[
                const SizedBox(height: 24),
                CatalogTableStack(
                  firstTableIndex: flora.classCounts.isNotEmpty ? 2 : 1,
                  groups: flora.classes,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Lotes de miel',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/lotes/list',
                  arguments: _isOwn ? null : _resolvedUserId,
                );
              },
              child: const Text('Ver lista'),
            ),
          ],
        ),
        if (_lotes.isEmpty)
          Text(
            'Sin lotes publicados',
            style: TextStyle(color: Colors.grey[600]),
          )
        else
          ..._lotes.map(
            (lote) => LoteCard(
              lote: lote,
              onTap: () => Navigator.pushNamed(
                context,
                '/lotes/detail',
                arguments: lote.id,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openCloudProfile() async {
    final id = _user?.id ?? _resolvedUserId;
    if (id == null) return;
    await _openUrl('${ApiConfig.baseUrl}/profile/$id');
  }

  Future<void> _openMaps(Ubicacion ubicacion) async {
    final q = ubicacion.mapsQuery;
    if (q == null) return;
    await _openUrl('https://www.google.com/maps/search/?api=1&query=$q');
  }

  Future<void> _openUrl(String raw) async {
    var value = raw.trim();
    if (!value.startsWith('http')) {
      value = 'https://$value';
    }
    final uri = Uri.tryParse(value);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
