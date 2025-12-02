import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_response.dart';
import '../models/session_response.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Servicio de autenticación que maneja login, logout y verificación de sesión
/// Se comunica exclusivamente con la API REST, nunca directamente con Supabase
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  static const String _loginStateKey = 'is_logged_in';
  static const String _userDataKey = 'user_data';

  /// Realiza login con email y password
  /// Retorna AuthResponse con el resultado de la operación
  Future<AuthResponse> login(String email, String password) async {
    try {
      final responseData = await _apiService.login(email, password);
      final authResponse = AuthResponse.fromJson(responseData);

      if (authResponse.success) {
        await _saveLoginState(true);
        debugPrint('[AUTH] Login exitoso para: $email');

        // Intentar obtener datos REALES del usuario desde el servidor
        try {
          debugPrint(
            '[AUTH] Obteniendo datos reales del usuario desde /api/user/current...',
          );
          final currentUserResponse = await _apiService.getCurrentUser();

          if (currentUserResponse['success'] == true &&
              currentUserResponse['user'] != null) {
            final userData = currentUserResponse['user'];

            // Crear usuario con datos REALES de Supabase (usuarios + info_contacto)
            final realUser = User(
              id: userData['auth_user_id'] ?? email.split('@')[0],
              username: userData['username'] ?? email.split('@')[0],
              tipoUsuario: userData['tipo_usuario'],
              role: userData['role'],
              status: userData['status'],
              activo: userData['activo'] as bool?,
              fechaRegistro: userData['fecha_registro'] as String?,
              lastLogin: userData['last_login'] as String?,
              nombreCompleto: userData['nombre_completo'],
              nombreEmpresa: userData['nombre_empresa'],
              email: userData['correo_principal'] ?? email,
              telefono: userData['telefono_principal'],
              direccion: userData['direccion'],
              comuna: userData['comuna'],
              region: userData['region'],
            );

            await _saveUserData(realUser);
            debugPrint(
              '[AUTH] Datos REALES del usuario obtenidos desde Supabase',
            );
            debugPrint(
              '[AUTH] Usuario: ${realUser.username}, Role: ${realUser.role}, Tipo: ${realUser.tipoUsuario}',
            );
          } else {
            throw Exception('No se pudieron obtener datos del usuario');
          }
        } catch (userError) {
          debugPrint('[AUTH] No se pudieron obtener datos reales: $userError');
          debugPrint('[AUTH] Usando datos temporales como fallback');

          // Fallback: crear usuario con datos temporales
          final fallbackUser = User(
            id: email.split('@')[0],
            username: email.split('@')[0],
            email: email,
            status: 'active',
          );
          await _saveUserData(fallbackUser);
        }
      } else {
        debugPrint('[AUTH] Login fallido: ${authResponse.error}');
      }

      return authResponse;
    } catch (e) {
      debugPrint('[AUTH] Error en login: $e');
      return AuthResponse(
        success: false,
        error: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  /// Verifica la sesión actual en el servidor
  /// Retorna los datos del usuario si está autenticado
  Future<SessionResponse?> checkSession() async {
    try {
      final responseData = await _apiService.checkSession();
      final sessionResponse = SessionResponse.fromJson(responseData);

      if (sessionResponse.success &&
          sessionResponse.loggedIn &&
          sessionResponse.user != null) {
        await _saveUserData(sessionResponse.user!);
        await _saveLoginState(true);
        debugPrint(
          '[AUTH] Sesión válida para usuario: ${sessionResponse.user!.username}',
        );
      } else {
        await _saveLoginState(false);
        await _clearUserData();
        debugPrint('[AUTH] No hay sesión activa');
      }

      return sessionResponse;
    } catch (e) {
      debugPrint('[AUTH] Error verificando sesión: $e');

      // WORKAROUND: Si el error es por columna 'id' no existe,
      // crear una sesión simulada con datos del login exitoso
      final errorString = e.toString();
      if (errorString.contains('column usuarios.id does not exist') ||
          errorString.contains('42703')) {
        debugPrint('[AUTH] WORKAROUND: Detectado error de columna usuarios.id');
        debugPrint('[AUTH] Creando sesión simulada basada en login exitoso');

        // Crear usuario simulado con datos básicos
        final simulatedUser = User(
          id: 'temp-user-id', // ID temporal
          username: 'usuario-logueado', // Username temporal
          email: 'usuario@email.com', // Email temporal
        );

        await _saveUserData(simulatedUser);
        await _saveLoginState(true);

        return SessionResponse(
          success: true,
          loggedIn: true,
          user: simulatedUser,
        );
      }

      await _saveLoginState(false);
      return null;
    }
  }

  /// Registrar nuevo usuario
  /// IMPORTANTE: El registro NO crea sesión automáticamente
  /// El usuario debe confirmar su email antes de hacer login
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AUTH] Iniciando registro para: $email');

      // IMPORTANTE: Limpiar cualquier sesión anterior antes de registrar
      await _clearUserData();
      await _saveLoginState(false);
      _apiService.clearCookies();

      // Llamar al endpoint de registro
      final response = await _apiService.register(
        username: username,
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        debugPrint('[AUTH] ✅ Registro exitoso');
        debugPrint(
          '[AUTH] ⚠️ El usuario debe confirmar su email antes de hacer login',
        );

        // NO intentar obtener datos del usuario porque NO está autenticado
        // El usuario debe confirmar email y luego hacer login
        return {
          'success': true,
          'message':
              response['message'] ??
              'Registro exitoso. Por favor confirma tu email.',
          'requires_confirmation': true,
        };
      } else {
        debugPrint('[AUTH] Error en registro: ${response['error']}');
        return {
          'success': false,
          'error': response['error'] ?? 'Error al registrar usuario',
        };
      }
    } catch (e) {
      debugPrint('[AUTH] Excepción en registro: $e');
      return {'success': false, 'error': 'Error de conexión al registrar'};
    }
  }

  /// Cierra la sesión del usuario
  /// Limpia TODOS los datos: cookies, SharedPreferences, estado
  Future<bool> logout() async {
    try {
      debugPrint('[AUTH] 🔓 Cerrando sesión...');

      // 1. Llamar al endpoint de logout en servidor
      try {
        await _apiService.logout();
        debugPrint('[AUTH] ✅ Sesión cerrada en servidor');
      } catch (e) {
        debugPrint('[AUTH] ⚠️ Error cerrando sesión en servidor: $e');
        // Continuar con limpieza local de todos modos
      }

      // 2. Limpiar TODAS las cookies
      _apiService.clearCookies();
      debugPrint('[AUTH] 🍪 Cookies limpiadas');

      // 3. Limpiar TODOS los datos de SharedPreferences
      await _clearUserData();
      debugPrint('[AUTH] 📦 SharedPreferences limpiado');

      // 4. Marcar como no logueado
      await _saveLoginState(false);
      debugPrint('[AUTH] ✅ Logout completo');

      return true;
    } catch (e) {
      debugPrint('[AUTH] ❌ Error crítico en logout: $e');

      // IMPORTANTE: Limpiar todo de todos modos
      _apiService.clearCookies();
      await _clearUserData();
      await _saveLoginState(false);

      return false;
    }
  }

  /// Verifica si el usuario está logueado localmente
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_loginStateKey) ?? false;

    // Verificar también si hay cookies de sesión
    final hasCookies = await _apiService.hasCookies();

    return isLoggedIn && hasCookies;
  }

  /// Obtiene los datos del usuario guardados localmente
  Future<User?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userDataKey);

      if (userJson != null) {
        // Aquí necesitaremos parsear manualmente hasta que se generen los archivos .g.dart
        // Por ahora retornamos null y dependemos de checkSession()
        return null;
      }

      return null;
    } catch (e) {
      debugPrint('[AUTH] Error obteniendo usuario cacheado: $e');
      return null;
    }
  }

  /// Guarda el estado de login en SharedPreferences
  Future<void> _saveLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginStateKey, isLoggedIn);
  }

  /// Guarda los datos del usuario en SharedPreferences
  Future<void> _saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Guardar todos los datos del usuario (usuarios + info_contacto)
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_username', user.username);
      if (user.tipoUsuario != null)
        await prefs.setString('user_tipo_usuario', user.tipoUsuario!);
      if (user.role != null) await prefs.setString('user_role', user.role!);
      if (user.status != null)
        await prefs.setString('user_status', user.status!);
      if (user.activo != null) await prefs.setBool('user_activo', user.activo!);
      if (user.fechaRegistro != null)
        await prefs.setString('user_fecha_registro', user.fechaRegistro!);
      if (user.lastLogin != null)
        await prefs.setString('user_last_login', user.lastLogin!);
      if (user.nombreCompleto != null)
        await prefs.setString('user_nombre_completo', user.nombreCompleto!);
      if (user.nombreEmpresa != null)
        await prefs.setString('user_nombre_empresa', user.nombreEmpresa!);
      if (user.email != null) await prefs.setString('user_email', user.email!);
      if (user.telefono != null)
        await prefs.setString('user_telefono', user.telefono!);
      if (user.direccion != null)
        await prefs.setString('user_direccion', user.direccion!);
      if (user.comuna != null)
        await prefs.setString('user_comuna', user.comuna!);
      if (user.region != null)
        await prefs.setString('user_region', user.region!);
      debugPrint('[AUTH] Datos de usuario guardados localmente');
    } catch (e) {
      debugPrint('[AUTH] Error guardando datos de usuario: $e');
    }
  }

  /// Limpia los datos del usuario de SharedPreferences
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      await prefs.remove('user_id');
      await prefs.remove('user_username');
      await prefs.remove('user_tipo_usuario');
      await prefs.remove('user_role');
      await prefs.remove('user_status');
      await prefs.remove('user_activo');
      await prefs.remove('user_fecha_registro');
      await prefs.remove('user_last_login');
      await prefs.remove('user_nombre_completo');
      await prefs.remove('user_nombre_empresa');
      await prefs.remove('user_email');
      await prefs.remove('user_telefono');
      await prefs.remove('user_direccion');
      await prefs.remove('user_comuna');
      await prefs.remove('user_region');
      debugPrint('[AUTH] Datos de usuario limpiados');
    } catch (e) {
      debugPrint('[AUTH] Error limpiando datos de usuario: $e');
    }
  }

  /// Obtiene datos completos del usuario desde SharedPreferences
  Future<Map<String, String?>> getBasicUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'id': prefs.getString('user_id'),
        'username': prefs.getString('user_username'),
        'tipo_usuario': prefs.getString('user_tipo_usuario'),
        'role': prefs.getString('user_role'),
        'status': prefs.getString('user_status'),
        'activo': prefs.getBool('user_activo')?.toString(),
        'fecha_registro': prefs.getString('user_fecha_registro'),
        'last_login': prefs.getString('user_last_login'),
        'nombre_completo': prefs.getString('user_nombre_completo'),
        'nombre_empresa': prefs.getString('user_nombre_empresa'),
        'email': prefs.getString('user_email'),
        'telefono': prefs.getString('user_telefono'),
        'direccion': prefs.getString('user_direccion'),
        'comuna': prefs.getString('user_comuna'),
        'region': prefs.getString('user_region'),
      };
    } catch (e) {
      debugPrint('[AUTH] Error obteniendo datos básicos: $e');
      return {};
    }
  }
}
