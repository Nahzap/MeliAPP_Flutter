/// Modelo de usuario completo con datos de usuarios + info_contacto
class User {
  // Campos de la tabla usuarios
  final String id; // auth_user_id (UUID)
  final String username; // username
  final String? tipoUsuario; // tipo_usuario
  final String? role; // role
  final String? status; // status
  final bool? activo; // activo
  final String? fechaRegistro; // fecha_registro
  final String? lastLogin; // last_login

  // Campos de la tabla info_contacto
  final String? nombreCompleto; // nombre_completo
  final String? nombreEmpresa; // nombre_empresa
  final String? email; // correo_principal
  final String? telefono; // telefono_principal
  final String? direccion; // direccion
  final String? comuna; // comuna
  final String? region; // region

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
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Datos de tabla usuarios
      id: json['auth_user_id'] as String? ?? json['id'] as String,
      username: json['username'] as String,
      tipoUsuario: json['tipo_usuario'] as String?,
      role: json['role'] as String?,
      status: json['status'] as String?,
      activo: json['activo'] as bool?,
      fechaRegistro: json['fecha_registro'] as String?,
      lastLogin: json['last_login'] as String?,
      // Datos de tabla info_contacto
      nombreCompleto: json['nombre_completo'] as String?,
      nombreEmpresa: json['nombre_empresa'] as String?,
      email: json['correo_principal'] as String? ?? json['email'] as String?,
      telefono: json['telefono_principal'] as String?,
      direccion: json['direccion'] as String?,
      comuna: json['comuna'] as String?,
      region: json['region'] as String?,
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
    };
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, nombre: $nombreCompleto, email: $email}';
  }
}
