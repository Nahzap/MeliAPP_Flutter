import 'ubicacion_model.dart';

/// Modelo de usuario completo con datos de usuarios + info_contacto.
class User {
  final String id;
  final String username;
  final String? tipoUsuario;
  final String? role;
  final String? status;
  final bool? activo;
  final String? fechaRegistro;
  final String? lastLogin;
  final String? nombreCompleto;
  final String? nombreEmpresa;
  final String? email;
  final String? telefono;
  final String? direccion;
  final String? comuna;
  final String? region;
  final String? rut;
  final String? registroSag;
  final List<Ubicacion> ubicaciones;
  final Map<String, dynamic> redesSociales;

  User({
    required this.id,
    required this.username,
    this.tipoUsuario,
    this.role,
    this.status,
    this.activo,
    this.fechaRegistro,
    this.lastLogin,
    this.nombreCompleto,
    this.nombreEmpresa,
    this.email,
    this.telefono,
    this.direccion,
    this.comuna,
    this.region,
    this.rut,
    this.registroSag,
    this.ubicaciones = const [],
    this.redesSociales = const {},
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final nestedUser = json['user'];
    final source = nestedUser is Map<String, dynamic> ? nestedUser : json;

    return User(
      id:
          source['auth_user_id'] as String? ??
          source['id'] as String? ??
          json['auth_user_id'] as String? ??
          json['id'] as String? ??
          '',
      username: (source['username'] ?? json['username'] ?? '') as String,
      tipoUsuario: source['tipo_usuario'] as String?,
      role: source['role'] as String?,
      status: source['status'] as String?,
      activo: source['activo'] as bool?,
      fechaRegistro: source['fecha_registro'] as String?,
      lastLogin: source['last_login'] as String?,
      nombreCompleto: source['nombre_completo'] as String?,
      nombreEmpresa: source['nombre_empresa'] as String?,
      email:
          source['correo_principal'] as String? ?? source['email'] as String?,
      telefono:
          source['telefono_principal'] as String? ??
          source['telefono'] as String?,
      direccion: source['direccion'] as String?,
      comuna: source['comuna'] as String?,
      region: source['region'] as String?,
      rut: source['rut'] as String?,
      registroSag: source['registro_sag'] as String?,
      ubicaciones: _parseUbicaciones(
        source['ubicaciones'] ?? json['ubicaciones'],
      ),
      redesSociales: _parseRedes(
        source['redes_sociales'] ?? json['redes_sociales'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auth_user_id': id,
      'username': username,
      'tipo_usuario': tipoUsuario,
      'role': role,
      'status': status,
      'activo': activo,
      'fecha_registro': fechaRegistro,
      'last_login': lastLogin,
      'nombre_completo': nombreCompleto,
      'nombre_empresa': nombreEmpresa,
      'correo_principal': email,
      'telefono_principal': telefono,
      'direccion': direccion,
      'comuna': comuna,
      'region': region,
      'rut': rut,
      'registro_sag': registroSag,
      'ubicaciones': ubicaciones.map((u) => u.toJson()).toList(),
      'redes_sociales': redesSociales,
    };
  }

  String get displayName =>
      (nombreCompleto != null && nombreCompleto!.trim().isNotEmpty)
      ? nombreCompleto!.trim()
      : username;

  /// Rol ocupacional único (evita APICULTOR + apicultor).
  String? get occupationLabel {
    final labels = <String>[];
    for (final raw in [role, tipoUsuario]) {
      final pretty = _prettyLabel(raw);
      if (pretty == null) continue;
      if (_genericIdentityTokens.contains(_normalize(pretty))) continue;
      if (labels.any((item) => _normalize(item) == _normalize(pretty))) {
        continue;
      }
      labels.add(pretty);
    }
    return labels.isEmpty ? null : labels.first;
  }

  bool get hasDistinctUsername {
    final handle = username.trim();
    if (handle.isEmpty) return false;
    return _normalize(handle) != _normalize(displayName);
  }

  String? get locationLabel {
    final parts = [
      comuna,
      region,
    ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty);
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  bool get isActive {
    final st = status?.trim().toLowerCase();
    if (st == 'active' || st == 'activo') return true;
    return activo == true;
  }

  Map<String, String> get redesConValor {
    final result = <String, String>{};
    redesSociales.forEach((key, value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isNotEmpty) result[key] = text;
    });
    return result;
  }

  static List<Ubicacion> _parseUbicaciones(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Ubicacion.fromJson(Map<String, dynamic>.from(e)))
        .where((u) => u.id.isNotEmpty || u.nombre.isNotEmpty)
        .toList();
  }

  static Map<String, dynamic> _parseRedes(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const {};
  }

  static const _genericIdentityTokens = {'user', 'usuario', 'active', 'activo'};

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String? _prettyLabel(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text == text.toUpperCase() || text == text.toLowerCase()) {
      return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
    }
    return text;
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, nombre: $nombreCompleto, email: $email}';
  }
}
