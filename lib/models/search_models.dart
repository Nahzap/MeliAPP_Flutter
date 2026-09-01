/// Modelos del contrato REST de búsqueda por palabras clave de MeliAPP Cloud.
///
/// Endpoints:
/// - `GET /api/search/suggest?q=` → veredicto del parser y sugerencias
/// - `GET /api/search/keywords?k=&k=` → perfiles apícolas (AND entre claves)
///
/// El servidor es la autoridad sobre qué es una palabra clave y qué es una
/// frase. El visor no reimplementa la gramática.
library;

/// Categorías que emite Cloud. Los nombres deben coincidir con
/// `CATEGORY_LABELS` en `services/keyword_parser.py`.
class KeywordCategory {
  static const String apicultor = 'apicultor';
  static const String tipoMiel = 'tipo_miel';
  static const String polen = 'polen';
  static const String especie = 'especie';
  static const String lugar = 'lugar';
  static const String zona = 'zona';
  static const String libre = 'libre';

  /// Solo se usa si el servidor no envía `label`. La etiqueta del servidor
  /// tiene prioridad para que el vocabulario no se bifurque.
  static const Map<String, String> _fallback = {
    apicultor: 'Apicultor',
    tipoMiel: 'Tipo de miel',
    polen: 'Polen',
    especie: 'Especie',
    lugar: 'Lugar',
    zona: 'Flora de zona',
    libre: 'Palabra clave',
  };

  static String labelFor(String? category) =>
      _fallback[category] ?? 'Palabra clave';
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

/// Una palabra clave confirmada, ya validada por el servidor.
class KeywordChip {
  final String term;
  final String normalized;
  final String category;
  final String label;

  const KeywordChip({
    required this.term,
    required this.normalized,
    required this.category,
    required this.label,
  });

  factory KeywordChip.fromJson(Map<String, dynamic> json) {
    final term = _asString(json['term']) ?? '';
    final category = _asString(json['category']) ?? KeywordCategory.libre;
    return KeywordChip(
      term: term,
      normalized: _asString(json['normalized']) ?? term.toLowerCase(),
      category: category,
      label: _asString(json['label']) ?? KeywordCategory.labelFor(category),
    );
  }

  Map<String, dynamic> toJson() => {'term': term, 'category': category};

  /// Clave de deduplicación: dos chips con el mismo texto son el mismo chip.
  String get dedupeKey => normalized.toLowerCase();

  @override
  bool operator ==(Object other) =>
      other is KeywordChip && other.dedupeKey == dedupeKey;

  @override
  int get hashCode => dedupeKey.hashCode;

  @override
  String toString() => 'KeywordChip($term, $category)';
}

/// Una fila de la lista de sugerencias.
///
/// Puede ser un término del catálogo (se convierte en chip) o una persona
/// (lleva `id` y navega directo al perfil, igual que en la web).
class KeywordSuggestion {
  final String term;
  final String normalized;
  final String category;
  final String label;
  final String? id;
  final String? especialidad;

  const KeywordSuggestion({
    required this.term,
    required this.normalized,
    required this.category,
    required this.label,
    this.id,
    this.especialidad,
  });

  factory KeywordSuggestion.fromJson(Map<String, dynamic> json) {
    final term = _asString(json['term']) ?? _asString(json['nombre']) ?? '';
    final category = _asString(json['category']) ?? KeywordCategory.libre;
    return KeywordSuggestion(
      term: term,
      normalized: _asString(json['normalized']) ?? term.toLowerCase(),
      category: category,
      label: _asString(json['label']) ?? KeywordCategory.labelFor(category),
      id: _asString(json['id']),
      especialidad: _asString(json['especialidad']),
    );
  }

  /// Las personas se abren directamente; los términos se acumulan como chips.
  bool get isPerson => id != null && id!.isNotEmpty;

  /// Texto secundario de la fila: especialidad si es persona, categoría si no.
  String get subtitle {
    if (isPerson) return especialidad ?? 'Apicultor';
    return KeywordCategory.labelFor(category);
  }

  KeywordChip toChip() => KeywordChip(
    term: term,
    normalized: normalized,
    category: category,
    label: KeywordCategory.labelFor(category),
  );
}

/// Por qué un perfil coincidió con una palabra clave.
class SearchMatch {
  final String category;
  final String term;
  final String evidence;
  final String confidence;
  final String label;

  const SearchMatch({
    required this.category,
    required this.term,
    required this.evidence,
    required this.confidence,
    required this.label,
  });

  factory SearchMatch.fromJson(Map<String, dynamic> json) {
    final category = _asString(json['category']) ?? KeywordCategory.libre;
    return SearchMatch(
      category: category,
      term: _asString(json['term']) ?? '',
      evidence: _asString(json['evidence']) ?? '',
      confidence: _asString(json['confidence']) ?? 'direct',
      label: _asString(json['label']) ?? KeywordCategory.labelFor(category),
    );
  }

  /// Coincidencia indirecta: la especie crece en la zona, pero no está
  /// certificada en un lote de este perfil.
  bool get isZoneFlora => confidence == 'zone_flora';

  String get display => evidence.isEmpty ? label : '$label: $evidence';
}

/// Un perfil apícola devuelto por la búsqueda.
class ApicolaProfile {
  final String authUserId;
  final String nombre;
  final String? nombreEmpresa;
  final String? username;
  final String? role;
  final String? comuna;
  final String? region;
  final int score;
  final List<SearchMatch> matches;

  const ApicolaProfile({
    required this.authUserId,
    required this.nombre,
    this.nombreEmpresa,
    this.username,
    this.role,
    this.comuna,
    this.region,
    this.score = 0,
    this.matches = const [],
  });

  factory ApicolaProfile.fromJson(Map<String, dynamic> json) {
    final rawMatches = json['matches'];
    return ApicolaProfile(
      authUserId: _asString(json['auth_user_id']) ?? '',
      nombre: _asString(json['nombre']) ?? 'Apicultor',
      nombreEmpresa: _asString(json['nombre_empresa']),
      username: _asString(json['username']),
      role: _asString(json['role']) ?? _asString(json['tipo_usuario']),
      comuna: _asString(json['comuna']),
      region: _asString(json['region']),
      score: (json['score'] as num?)?.toInt() ?? 0,
      matches: rawMatches is List
          ? rawMatches
                .whereType<Map>()
                .map((m) => SearchMatch.fromJson(Map<String, dynamic>.from(m)))
                .toList()
          : const [],
    );
  }

  /// "Valdivia, Los Ríos" — omite las partes que el perfil no tenga.
  String? get ubicacion {
    final partes = [comuna, region].where((p) => p != null && p.isNotEmpty);
    return partes.isEmpty ? null : partes.join(', ');
  }

  String get inicial => nombre.isEmpty ? 'A' : nombre[0].toUpperCase();
}

/// Respuesta de `GET /api/search/suggest`.
class SuggestResult {
  final bool valid;
  final String queryType;
  final String reason;
  final List<KeywordChip> keywords;
  final List<KeywordSuggestion> suggestions;

  const SuggestResult({
    required this.valid,
    required this.queryType,
    required this.reason,
    required this.keywords,
    required this.suggestions,
  });

  factory SuggestResult.fromJson(Map<String, dynamic> json) {
    return SuggestResult(
      valid: json['valid'] == true || json['ok'] == true,
      queryType: _asString(json['query_type']) ?? 'empty',
      reason: _asString(json['reason']) ?? '',
      keywords: _listOf(json['keywords'], KeywordChip.fromJson),
      suggestions: _listOf(json['suggestions'], KeywordSuggestion.fromJson),
    );
  }

  static const SuggestResult empty = SuggestResult(
    valid: false,
    queryType: 'empty',
    reason: '',
    keywords: [],
    suggestions: [],
  );

  /// El usuario escribió una frase en vez de palabras clave.
  bool get isSentence => queryType == 'sentence';
}

/// Respuesta de `GET /api/search/keywords`.
class KeywordSearchResult {
  final bool ok;
  final String queryType;
  final String reason;
  final List<KeywordChip> keywords;
  final List<KeywordSuggestion> suggestions;
  final int count;
  final List<ApicolaProfile> results;

  const KeywordSearchResult({
    required this.ok,
    required this.queryType,
    required this.reason,
    required this.keywords,
    required this.suggestions,
    required this.count,
    required this.results,
  });

  factory KeywordSearchResult.fromJson(Map<String, dynamic> json) {
    final results = _listOf(json['results'], ApicolaProfile.fromJson);
    return KeywordSearchResult(
      ok: json['ok'] == true,
      queryType: _asString(json['query_type']) ?? 'keyword',
      reason: _asString(json['reason']) ?? '',
      keywords: _listOf(json['keywords'], KeywordChip.fromJson),
      suggestions: _listOf(json['suggestions'], KeywordSuggestion.fromJson),
      count: (json['count'] as num?)?.toInt() ?? results.length,
      results: results,
    );
  }

  bool get isSentence => queryType == 'sentence';
}

List<T> _listOf<T>(dynamic raw, T Function(Map<String, dynamic>) build) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => build(Map<String, dynamic>.from(item)))
      .toList();
}

/// Fallo de red o del servidor con un mensaje mostrable al usuario.
class SearchException implements Exception {
  final String message;
  const SearchException(this.message);

  @override
  String toString() => message;
}
