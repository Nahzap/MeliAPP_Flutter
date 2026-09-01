/// Apiario / ubicación geográfica de un usuario (tabla `ubicaciones`).
class Ubicacion {
  final String id;
  final String? authUserId;
  final String nombre;
  final double? latitud;
  final double? longitud;
  final String? normaGeo;
  final String? descripcion;
  final String? comuna;
  final String? region;

  const Ubicacion({
    required this.id,
    required this.nombre,
    this.authUserId,
    this.latitud,
    this.longitud,
    this.normaGeo,
    this.descripcion,
    this.comuna,
    this.region,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      id: json['id']?.toString() ?? '',
      authUserId: json['auth_user_id']?.toString(),
      nombre:
          json['nombre']?.toString() ??
          json['nombre_ubicacion']?.toString() ??
          'Ubicación',
      latitud: _toDouble(json['latitud']),
      longitud: _toDouble(json['longitud']),
      normaGeo: json['norma_geo']?.toString(),
      descripcion: json['descripcion']?.toString(),
      comuna: json['comuna']?.toString(),
      region: json['region']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_user_id': authUserId,
      'nombre': nombre,
      'latitud': latitud,
      'longitud': longitud,
      'norma_geo': normaGeo,
      'descripcion': descripcion,
      'comuna': comuna,
      'region': region,
    };
  }

  bool get hasCoordinates => latitud != null && longitud != null;

  String? get mapsQuery {
    if (hasCoordinates) {
      return '$latitud,$longitud';
    }
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
