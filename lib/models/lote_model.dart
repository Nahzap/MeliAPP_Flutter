/// Modelo para lotes de miel (tabla origenes_botanicos).
///
/// `composicion` puede ser CSV de polen ("Maitén:40, Notro:30"),
/// CSV certificado ("Poleo: 65.6%, Arrayan: 34.4%") o un estado
/// de certificación ("Pendiente de Análisis", "Procesando IA").
class Lote {
  final String id;
  final String authUserId;
  final int ordenMiel;
  final String nombreMiel;
  final String temporada;
  final String? anioCosecha;
  final double? kgProducidos;
  final String? composicion;
  final DateTime? fechaRegistro;
  final DateTime? fechaActualizacion;

  /// Valor crudo de Cloud (`fecha_actualizacion`), para el IEEE.
  final String? fechaActualizacionRaw;
  final String? observacionesApicultor;
  final String? observacionesRevisor;
  final String? revisorId;
  final String? revisorNombre;
  final Map<String, dynamic>? datosCertificado;

  Lote({
    required this.id,
    required this.authUserId,
    required this.ordenMiel,
    required this.nombreMiel,
    required this.temporada,
    this.anioCosecha,
    this.kgProducidos,
    this.composicion,
    this.fechaRegistro,
    this.fechaActualizacion,
    this.fechaActualizacionRaw,
    this.observacionesApicultor,
    this.observacionesRevisor,
    this.revisorId,
    this.revisorNombre,
    this.datosCertificado,
  });

  factory Lote.fromJson(Map<String, dynamic> json) {
    return Lote(
      id: json['id'] as String,
      authUserId: json['auth_user_id'] as String,
      ordenMiel: json['orden_miel'] is int
          ? json['orden_miel'] as int
          : int.tryParse('${json['orden_miel']}') ?? 0,
      nombreMiel: json['nombre_miel'] as String,
      temporada: json['temporada'] as String,
      anioCosecha: json['anio_cosecha']?.toString(),
      kgProducidos: json['kg_producidos'] != null
          ? double.tryParse(json['kg_producidos'].toString())
          : null,
      composicion: json['composicion'] as String?,
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.tryParse(json['fecha_registro'] as String)
          : null,
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.tryParse(json['fecha_actualizacion'] as String)
          : null,
      fechaActualizacionRaw: json['fecha_actualizacion']?.toString(),
      observacionesApicultor: _nullableText(json['observaciones_apicultor']),
      observacionesRevisor: _nullableText(json['observaciones_revisor']),
      revisorId: json['revisor_id']?.toString(),
      revisorNombre: _nullableText(json['revisor_nombre']),
      datosCertificado: json['datos_certificado'] is Map
          ? Map<String, dynamic>.from(json['datos_certificado'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_user_id': authUserId,
      'orden_miel': ordenMiel,
      'nombre_miel': nombreMiel,
      'temporada': temporada,
      'anio_cosecha': anioCosecha,
      'kg_producidos': kgProducidos,
      'composicion': composicion,
      'fecha_registro': fechaRegistro?.toIso8601String(),
      'fecha_actualizacion':
          fechaActualizacionRaw ?? fechaActualizacion?.toIso8601String(),
      'observaciones_apicultor': observacionesApicultor,
      'observaciones_revisor': observacionesRevisor,
      'revisor_id': revisorId,
      'revisor_nombre': revisorNombre,
      'datos_certificado': datosCertificado,
    };
  }

  bool get hasCertificado =>
      datosCertificado != null && datosCertificado!.isNotEmpty;

  /// Cloud genera el IEEE aunque el PDF no esté persistido.
  bool get puedeMostrarCertificado {
    if (hasCertificado) return true;
    final text = composicion ?? '';
    return text.contains('%') && !isEstadoCertificacion;
  }

  bool get isEstadoCertificacion {
    final text = composicion?.trim() ?? '';
    if (text.isEmpty) return false;
    if (_looksLikeCsv(text)) return false;
    final lower = text.toLowerCase();
    const markers = [
      'pendiente',
      'procesando',
      'rechazado',
      'análisis',
      'analisis',
      'certific',
    ];
    return markers.any(lower.contains);
  }

  /// Polen para gráficos: certificado estructurado primero, luego CSV.
  Map<String, double> parseComposicion() {
    final fromCert = _composicionFromCertificado();
    if (fromCert.isNotEmpty) return fromCert;
    return _parseComposicionCsv(composicion);
  }

  double getTotalComposicion() {
    return parseComposicion().values.fold(0.0, (sum, val) => sum + val);
  }

  List<MapEntry<String, double>> getEspeciesOrdenadas() {
    final entries = parseComposicion().entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  String? getEspeciePredominante() {
    final ordenadas = getEspeciesOrdenadas();
    return ordenadas.isNotEmpty ? ordenadas.first.key : null;
  }

  List<String> getTemporadas() {
    return temporada.split(' - ').map((e) => e.trim()).toList();
  }

  bool isComposicionValida() {
    final total = getTotalComposicion();
    return total >= 99.0 && total <= 101.0;
  }

  String? get metodoAnalisis {
    final analisis = datosCertificado?['analisis_melisopalinologico'];
    if (analisis is Map && analisis['metodo'] != null) {
      return analisis['metodo'].toString();
    }
    return null;
  }

  Map<String, dynamic>? get datosMuestra {
    final raw = datosCertificado?['datos_muestra'];
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  List<Map<String, dynamic>> get polenesIdentificados {
    final analisis = datosCertificado?['analisis_melisopalinologico'];
    if (analisis is! Map) return const [];
    final raw = analisis['polenes_identificados'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  String toString() {
    return 'Lote{ordenMiel: $ordenMiel, nombreMiel: $nombreMiel, kgProducidos: $kgProducidos}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lote && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  Lote copyWith({
    String? id,
    String? authUserId,
    int? ordenMiel,
    String? nombreMiel,
    String? temporada,
    String? anioCosecha,
    double? kgProducidos,
    String? composicion,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
    String? fechaActualizacionRaw,
    String? observacionesApicultor,
    String? observacionesRevisor,
    String? revisorId,
    String? revisorNombre,
    Map<String, dynamic>? datosCertificado,
  }) {
    return Lote(
      id: id ?? this.id,
      authUserId: authUserId ?? this.authUserId,
      ordenMiel: ordenMiel ?? this.ordenMiel,
      nombreMiel: nombreMiel ?? this.nombreMiel,
      temporada: temporada ?? this.temporada,
      anioCosecha: anioCosecha ?? this.anioCosecha,
      kgProducidos: kgProducidos ?? this.kgProducidos,
      composicion: composicion ?? this.composicion,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      fechaActualizacionRaw:
          fechaActualizacionRaw ?? this.fechaActualizacionRaw,
      observacionesApicultor:
          observacionesApicultor ?? this.observacionesApicultor,
      observacionesRevisor: observacionesRevisor ?? this.observacionesRevisor,
      revisorId: revisorId ?? this.revisorId,
      revisorNombre: revisorNombre ?? this.revisorNombre,
      datosCertificado: datosCertificado ?? this.datosCertificado,
    );
  }

  Map<String, double> _composicionFromCertificado() {
    final result = <String, double>{};
    for (final pollen in polenesIdentificados) {
      final name = (pollen['nombre_comun'] ?? pollen['taxon'] ?? '')
          .toString()
          .trim();
      if (name.isEmpty) continue;
      final pct = pollen['proporcion_pct'];
      final value = pct is num ? pct.toDouble() : double.tryParse('$pct');
      if (value != null) result[name] = value;
    }
    return result;
  }

  static String? _nullableText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static bool _looksLikeCsv(String text) {
    return text.contains(':') && RegExp(r'\d').hasMatch(text);
  }

  static Map<String, double> _parseComposicionCsv(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    final result = <String, double>{};
    for (final item in raw.split(',')) {
      final parts = item.trim().split(':');
      if (parts.length != 2) continue;
      final especie = parts[0].trim();
      if (especie.isEmpty) continue;
      final porcentaje = _parsePercent(parts[1]);
      if (porcentaje != null) {
        result[especie] = porcentaje;
      }
    }
    return result;
  }

  static double? _parsePercent(String raw) {
    final cleaned = raw.trim().replaceAll('%', '').replaceAll(',', '.').trim();
    return double.tryParse(cleaned);
  }
}
