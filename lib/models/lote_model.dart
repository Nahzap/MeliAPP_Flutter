/// Modelo para lotes de miel (origenes_botanicos table).
///
/// Representa un lote de producción de miel con su composición botánica.
/// El campo `composicion` viene en formato CSV: "Especie:%, Especie:%"
///
/// Ejemplo: "Maitén:40, Notro:30, Michay:20, Avellano Chileno:10"
class Lote {
  final String id;
  final String authUserId;
  final int ordenMiel;
  final String nombreMiel;
  final String temporada;
  final double? kgProducidos;
  final String? composicion;
  final DateTime? fechaRegistro;
  final DateTime? fechaActualizacion;

  Lote({
    required this.id,
    required this.authUserId,
    required this.ordenMiel,
    required this.nombreMiel,
    required this.temporada,
    this.kgProducidos,
    this.composicion,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  /// Crea un Lote desde un JSON del backend
  factory Lote.fromJson(Map<String, dynamic> json) {
    return Lote(
      id: json['id'] as String,
      authUserId: json['auth_user_id'] as String,
      ordenMiel: json['orden_miel'] as int,
      nombreMiel: json['nombre_miel'] as String,
      temporada: json['temporada'] as String,
      kgProducidos: json['kg_producidos'] != null
          ? double.tryParse(json['kg_producidos'].toString())
          : null,
      composicion: json['composicion'] as String?,
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.parse(json['fecha_registro'] as String)
          : null,
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'] as String)
          : null,
    );
  }

  /// Convierte el Lote a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_user_id': authUserId,
      'orden_miel': ordenMiel,
      'nombre_miel': nombreMiel,
      'temporada': temporada,
      'kg_producidos': kgProducidos,
      'composicion': composicion,
      'fecha_registro': fechaRegistro?.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  /// Parsea el campo composicion en un mapa {Especie: Porcentaje}
  ///
  /// Ejemplo:
  /// Input: "Maitén:40, Notro:30, Michay:20"
  /// Output: {"Maitén": 40.0, "Notro": 30.0, "Michay": 20.0}
  Map<String, double> parseComposicion() {
    if (composicion == null || composicion!.isEmpty) {
      return {};
    }

    final result = <String, double>{};
    final items = composicion!.split(',');

    for (var item in items) {
      final parts = item.trim().split(':');
      if (parts.length == 2) {
        final especie = parts[0].trim();
        final porcentaje = double.tryParse(parts[1].trim());
        if (porcentaje != null) {
          result[especie] = porcentaje;
        }
      }
    }

    return result;
  }

  /// Retorna el total de la composición (debería ser ~100%)
  double getTotalComposicion() {
    return parseComposicion().values.fold(0.0, (sum, val) => sum + val);
  }

  /// Lista de especies ordenadas por porcentaje descendente
  List<MapEntry<String, double>> getEspeciesOrdenadas() {
    final comp = parseComposicion();
    final entries = comp.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Retorna la especie predominante (mayor porcentaje)
  String? getEspeciePredominante() {
    final ordenadas = getEspeciesOrdenadas();
    return ordenadas.isNotEmpty ? ordenadas.first.key : null;
  }

  /// Lista de temporadas parseadas
  List<String> getTemporadas() {
    return temporada.split(' - ').map((e) => e.trim()).toList();
  }

  /// Verifica si la composición suma aproximadamente 100%
  bool isComposicionValida() {
    final total = getTotalComposicion();
    return total >= 99.0 && total <= 101.0;
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

  /// Crea una copia del lote con campos modificados
  Lote copyWith({
    String? id,
    String? authUserId,
    int? ordenMiel,
    String? nombreMiel,
    String? temporada,
    double? kgProducidos,
    String? composicion,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
  }) {
    return Lote(
      id: id ?? this.id,
      authUserId: authUserId ?? this.authUserId,
      ordenMiel: ordenMiel ?? this.ordenMiel,
      nombreMiel: nombreMiel ?? this.nombreMiel,
      temporada: temporada ?? this.temporada,
      kgProducidos: kgProducidos ?? this.kgProducidos,
      composicion: composicion ?? this.composicion,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
