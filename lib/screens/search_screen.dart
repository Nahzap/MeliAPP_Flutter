import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../models/search_models.dart';
import '../services/keyword_search_service.dart';
import '../widgets/keyword_chip_field.dart';
import '../widgets/match_evidence_pills.dart';

/// Búsqueda de perfiles apícolas por palabras clave.
///
/// Consume la API REST de MeliAPP Cloud:
/// - `GET /api/search/suggest` para sugerencias y veredicto del parser
/// - `GET /api/search/keywords` para los perfiles (AND entre palabras clave)
///
/// El buscador no acepta frases ni preguntas: es el servidor quien decide si
/// lo escrito es una palabra clave, de modo que el visor y meliapp.cl no
/// puedan discrepar.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final KeywordSearchService _service = KeywordSearchService();
  final Debouncer _debouncer = Debouncer(
    delay: KeywordSearchService.debounceDelay,
  );

  final List<KeywordChip> _chips = [];
  List<KeywordSuggestion> _suggestions = [];
  List<KeywordSuggestion> _populares = [];
  List<ApicolaProfile> _perfiles = [];

  String? _aviso;
  String? _error;
  bool _buscando = false;
  bool _sugiriendo = false;
  bool _yaBusco = false;

  CancelToken? _suggestToken;
  CancelToken? _searchToken;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _cargarPopulares();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _suggestToken?.cancel();
    _searchToken?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  // ------------------------------------------------------------- datos

  Future<void> _cargarPopulares() async {
    try {
      final resultado = await _service.suggest('');
      if (!mounted) return;
      setState(() => _populares = resultado.suggestions);
    } on SearchException {
      // El estado inicial sin populares sigue siendo usable: no se molesta
      // al usuario con un error por unas sugerencias decorativas.
    } catch (_) {}
  }

  void _onTextChanged(String texto) {
    // La coma cierra el chip, igual que en la web.
    if (texto.contains(',')) {
      final partes = texto.split(',');
      final ultimo = partes.removeLast();
      _controller.text = ultimo;
      _controller.selection = TextSelection.collapsed(offset: ultimo.length);
      for (final parte in partes) {
        if (parte.trim().isNotEmpty) _confirmarBorrador(parte.trim());
      }
      return;
    }

    final consulta = texto.trim();
    if (consulta.length < KeywordSearchService.minQueryLength) {
      _debouncer.cancel();
      setState(() {
        _suggestions = [];
        _aviso = null;
      });
      return;
    }

    _debouncer.run(() => _pedirSugerencias(consulta));
  }

  Future<void> _pedirSugerencias(String consulta) async {
    _suggestToken?.cancel();
    final token = CancelToken();
    _suggestToken = token;

    setState(() => _sugiriendo = true);
    try {
      final resultado = await _service.suggest(consulta, cancelToken: token);
      if (!mounted || token.isCancelled) return;
      setState(() {
        _suggestions = resultado.suggestions;
        _aviso = resultado.isSentence ? resultado.reason : null;
        _sugiriendo = false;
      });
    } on DioException {
      // Petición reemplazada por otra más reciente.
    } on SearchException catch (e) {
      if (!mounted) return;
      setState(() {
        _sugiriendo = false;
        _error = e.message;
      });
    }
  }

  /// Valida el borrador contra el servidor y lo convierte en chips.
  Future<void> _confirmarBorrador([String? texto]) async {
    final borrador = (texto ?? _controller.text).trim();
    if (borrador.isEmpty) return;

    _debouncer.cancel();
    setState(() => _sugiriendo = true);

    try {
      final resultado = await _service.suggest(borrador);
      if (!mounted) return;

      if (resultado.isSentence) {
        setState(() {
          _aviso = resultado.reason;
          _suggestions = resultado.suggestions;
          _sugiriendo = false;
        });
        return;
      }

      if (resultado.keywords.isEmpty) {
        setState(() {
          _aviso = resultado.reason.isEmpty
              ? 'No se reconoció ninguna palabra clave.'
              : resultado.reason;
          _suggestions = resultado.suggestions;
          _sugiriendo = false;
        });
        return;
      }

      _controller.clear();
      setState(() {
        _suggestions = [];
        _aviso = null;
        _sugiriendo = false;
      });
      _agregarChips(resultado.keywords);
    } on SearchException catch (e) {
      if (!mounted) return;
      setState(() {
        _sugiriendo = false;
        _error = e.message;
      });
    }
  }

  void _agregarChips(List<KeywordChip> nuevos) {
    var agregoAlguno = false;
    var seLleno = false;

    for (final chip in nuevos) {
      if (_chips.contains(chip)) continue;
      if (_chips.length >= KeywordSearchService.maxKeywords) {
        seLleno = true;
        break;
      }
      _chips.add(chip);
      agregoAlguno = true;
    }

    setState(() {
      if (seLleno) {
        _aviso =
            'Usa como máximo ${KeywordSearchService.maxKeywords} palabras clave.';
      }
    });

    if (agregoAlguno) _buscar();
  }

  void _quitarChip(KeywordChip chip) {
    setState(() {
      _chips.remove(chip);
      _aviso = null;
    });
    if (_chips.isEmpty) {
      setState(() {
        _perfiles = [];
        _yaBusco = false;
      });
      return;
    }
    _buscar();
  }

  Future<void> _buscar() async {
    if (_chips.isEmpty) return;

    _searchToken?.cancel();
    final token = CancelToken();
    _searchToken = token;

    setState(() {
      _buscando = true;
      _error = null;
      _yaBusco = true;
    });

    try {
      final resultado = await _service.search(_chips, cancelToken: token);
      if (!mounted || token.isCancelled) return;

      setState(() {
        _buscando = false;
        _perfiles = resultado.results;
        if (!resultado.ok && resultado.reason.isNotEmpty) {
          _aviso = resultado.reason;
        }
      });
    } on DioException {
      // Búsqueda reemplazada por otra más reciente.
    } on SearchException catch (e) {
      if (!mounted) return;
      setState(() {
        _buscando = false;
        _error = e.message;
        _perfiles = [];
      });
    }
  }

  void _onSugerenciaTocada(KeywordSuggestion sugerencia) {
    // Las personas se abren directamente; los términos se acumulan.
    if (sugerencia.isPerson) {
      _abrirPerfil(sugerencia.id!);
      return;
    }
    _controller.clear();
    setState(() {
      _suggestions = [];
      _aviso = null;
    });
    _agregarChips([sugerencia.toChip()]);
  }

  void _abrirPerfil(String userId) {
    Navigator.pushNamed(context, '/profile', arguments: userId);
  }

  // ------------------------------------------------------------- interfaz

  bool get _mostrandoSugerencias =>
      _suggestions.isNotEmpty && (_focusNode.hasFocus || _aviso != null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar'), elevation: 1),
      body: Column(
        children: [
          _buildCabecera(),
          Expanded(
            child: _mostrandoSugerencias
                ? _buildListaSugerencias()
                : _buildCuerpo(),
          ),
        ],
      ),
    );
  }

  Widget _buildCabecera() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solo palabras clave: apicultor, tipo de miel, polen, especie o lugar.',
            style: TextStyle(fontSize: 12.5, color: AppTheme.slate500),
          ),
          const SizedBox(height: 10),
          KeywordChipField(
            chips: _chips,
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onTextChanged,
            onSubmitted: _confirmarBorrador,
            onRemove: _quitarChip,
            onBackspaceEmpty: () => _quitarChip(_chips.last),
            isBusy: _sugiriendo || _buscando,
          ),
          if (_aviso != null) ...[const SizedBox(height: 10), _buildAviso()],
        ],
      ),
    );
  }

  Widget _buildAviso() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.amber50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.amber200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _aviso!,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaSugerencias() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _suggestions.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: AppTheme.slate100),
      itemBuilder: (context, index) {
        final sugerencia = _suggestions[index];
        return ListTile(
          dense: true,
          leading: Icon(
            sugerencia.isPerson ? Icons.person_outline : Icons.local_offer_outlined,
            size: 20,
            color: AppTheme.slate400,
          ),
          title: Text(
            sugerencia.term,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            sugerencia.subtitle,
            style: TextStyle(fontSize: 12, color: AppTheme.slate500),
          ),
          trailing: Icon(
            sugerencia.isPerson ? Icons.arrow_forward_ios : Icons.add,
            size: 14,
            color: AppTheme.slate400,
          ),
          onTap: () => _onSugerenciaTocada(sugerencia),
        );
      },
    );
  }

  Widget _buildCuerpo() {
    if (_error != null) return _buildError();
    if (_buscando && _perfiles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_yaBusco) return _buildEstadoInicial();
    if (_perfiles.isEmpty) return _buildSinResultados();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _perfiles.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          final n = _perfiles.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              n == 1 ? '1 perfil relacionado' : '$n perfiles relacionados',
              style: TextStyle(fontSize: 13, color: AppTheme.slate500),
            ),
          );
        }
        return _buildTarjetaPerfil(_perfiles[index - 1]);
      },
    );
  }

  Widget _buildTarjetaPerfil(ApicolaProfile perfil) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _abrirPerfil(perfil.authUserId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    perfil.inicial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfil.nombre,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        perfil.role ?? 'Apicultor',
                        if (perfil.ubicacion != null) perfil.ubicacion!,
                      ].join(' · '),
                      style: TextStyle(fontSize: 12.5, color: AppTheme.slate600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (perfil.nombreEmpresa != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        perfil.nombreEmpresa!,
                        style: TextStyle(fontSize: 12, color: AppTheme.slate500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (perfil.matches.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      MatchEvidencePills(matches: perfil.matches),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.slate400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoInicial() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Icon(Icons.travel_explore, size: 84, color: AppTheme.slate300),
          const SizedBox(height: 20),
          const Text(
            'Busca perfiles apícolas',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Combina hasta ${KeywordSearchService.maxKeywords} palabras clave.\n'
            'Se muestran los perfiles que cumplen todas.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: AppTheme.slate500),
          ),
          if (_populares.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'SUGERIDAS',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.1,
                color: AppTheme.slate400,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _populares
                  .map(
                    (item) => ActionChip(
                      label: Text(item.term),
                      labelStyle: const TextStyle(fontSize: 13),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: AppTheme.slate200),
                      onPressed: () => _agregarChips([item.toChip()]),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSinResultados() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 72, color: AppTheme.slate300),
            const SizedBox(height: 16),
            const Text(
              'Sin perfiles para esas palabras clave',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba con otra especie, un tipo de miel o un lugar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: AppTheme.slate500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.slate600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _error = null);
                _buscar();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
