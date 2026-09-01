import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/lote_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/certificado_builder.dart';
import '../../services/taxa_service.dart';
import '../../widgets/certificado_html_view.dart';

/// Certificado IEEE de Cloud, visto dentro de la app.
class CertificadoDocumentScreen extends StatefulWidget {
  final Lote lote;

  const CertificadoDocumentScreen({super.key, required this.lote});

  @override
  State<CertificadoDocumentScreen> createState() =>
      _CertificadoDocumentScreenState();
}

class _CertificadoDocumentScreenState extends State<CertificadoDocumentScreen> {
  bool _loading = true;
  String? _error;
  String? _html;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromCloud());
  }

  Future<void> _loadFromCloud() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final taxa = context.read<TaxaService>();
      await taxa.ensureLoaded();
      final apicultor = await _loadApicultor();
      final data = CertificadoBuilder.build(
        lote: widget.lote,
        apicultor: apicultor,
        taxa: taxa.catalog,
      );
      final html = await ApiService().fetchCertificadoPreview(data.json);
      if (!mounted) return;
      setState(() {
        _html = html;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[CERT] Cloud preview: $e');
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el certificado.';
        _loading = false;
      });
    }
  }

  Future<User?> _loadApicultor() async {
    final auth = context.read<AuthProvider>().user;
    if (auth != null && auth.id == widget.lote.authUserId) return auth;
    try {
      final raw = await ApiService().getUserById(widget.lote.authUserId);
      return User.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      debugPrint('[CERT] No se pudo cargar apicultor: $e');
      return auth;
    }
  }

  Future<void> _download() async {
    final html = _html;
    if (html == null) return;
    try {
      final saved = await saveCertificadoDocument(html);
      if (!mounted || saved) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo generar el PDF en este dispositivo.'),
        ),
      );
    } catch (e) {
      debugPrint('[CERT] Descarga: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo descargar el certificado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF525659),
      appBar: AppBar(
        title: const Text('Certificado de origen'),
        actions: [
          if (_html != null)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Descargar',
              onPressed: _download,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFromCloud,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    return CertificadoHtmlView(html: _html!);
  }
}
