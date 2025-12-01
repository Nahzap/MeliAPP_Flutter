import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Provider para manejo del estado de autenticación
/// Utiliza ChangeNotifier para notificar cambios a la UI
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  /// Inicializa el provider verificando el estado de autenticación
  /// IMPORTANTE: Verifica y limpia cualquier estado inconsistente
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);

    try {
      // Verificar estado de autenticación
      await _checkAuthStatus();

      // Si no hay usuario pero SharedPreferences dice que está logueado, limpiar
      if (_user == null) {
        final isLoggedIn = await _authService.isLoggedIn();
        if (!isLoggedIn) {
          debugPrint('[AUTH_PROVIDER] 🧹 Limpiando estado inconsistente...');
          await _authService.logout(); // Forzar limpieza completa
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] Error en inicialización: $e');
      _isInitialized = true;
    } finally {
      _setLoading(false);
    }
  }

  /// Realiza login con email y password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(email, password);

      if (response.success) {
        // NO llamar a _loadUserSession() que intenta verificar /api/auth/session
        // En su lugar, cargar directamente desde cache local
        await _loadBasicUserData();
        return true;
      } else {
        _setError(response.error ?? 'Error de autenticación');
        return false;
      }
    } catch (e) {
      // Extraer mensaje limpio del backend
      String errorMessage = 'Credenciales incorrectas';

      if (e.toString().contains('Credenciales inválidas') ||
          e.toString().contains('401')) {
        errorMessage = 'Credenciales incorrectas';
      } else if (e.toString().contains('Network') ||
          e.toString().contains('Connection')) {
        errorMessage = 'Error de conexión. Verifica tu internet';
      }

      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registra un nuevo usuario
  /// IMPORTANTE: El registro NO crea sesión, el usuario debe confirmar email
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      // Limpiar cualquier usuario previo antes de registrar
      _user = null;
      _clearError();

      final result = await _authService.register(
        username: username,
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        // NO establecer _user porque el usuario NO está autenticado
        // Debe confirmar email y luego hacer login
        debugPrint(
          '[AUTH_PROVIDER] ✅ Registro exitoso - Requiere confirmación de email',
        );
      } else {
        _setError(result['error'] ?? 'Error al registrar');
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Error al registrar: $e');
      _setLoading(false);
      return {'success': false, 'error': 'Error al registrar: $e'};
    }
  }

  /// Cierra sesión del usuario
  /// Limpia COMPLETAMENTE el estado: usuario, cookies, cache
  Future<void> logout() async {
    _setLoading(true);

    try {
      debugPrint('[AUTH_PROVIDER] 🔓 Iniciando logout...');

      // 1. Logout en servidor y limpieza de datos
      await _authService.logout();

      // 2. Limpiar estado del provider
      _user = null;
      _clearError();
      _isInitialized = false;

      debugPrint('[AUTH_PROVIDER] ✅ Estado limpiado completamente');
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] Error durante logout: $e');

      // IMPORTANTE: Limpiar estado local de todos modos
      _user = null;
      _clearError();
      _isInitialized = false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verifica el estado de autenticación al iniciar la app
  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        // Solo cargar desde cache local, NO verificar sesión en servidor
        await _loadBasicUserData();
      } else {
        _user = null;
      }
    } catch (e) {
      debugPrint('Error verificando estado de auth: $e');
      _user = null;
    }
  }

  /// Carga datos completos del usuario desde SharedPreferences
  Future<void> _loadBasicUserData() async {
    try {
      final userData = await _authService.getBasicUserData();

      if (userData['id'] != null && userData['username'] != null) {
        _user = User(
          id: userData['id']!,
          username: userData['username']!,
          tipoUsuario: userData['tipo_usuario'],
          role: userData['role'],
          status: userData['status'],
          activo: userData['activo'] == 'true',
          fechaRegistro: userData['fecha_registro'],
          lastLogin: userData['last_login'],
          nombreCompleto: userData['nombre_completo'],
          nombreEmpresa: userData['nombre_empresa'],
          email: userData['email'],
          telefono: userData['telefono'],
          direccion: userData['direccion'],
          comuna: userData['comuna'],
          region: userData['region'],
        );
        debugPrint(
          '[AUTH_PROVIDER] Datos completos cargados: ${_user!.username}',
        );
        if (_user!.role != null) {
          debugPrint('[AUTH_PROVIDER] Role: ${_user!.role}');
        }
        if (_user!.tipoUsuario != null) {
          debugPrint('[AUTH_PROVIDER] Tipo: ${_user!.tipoUsuario}');
        }
      }
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] Error cargando datos: $e');
    }
  }

  /// Refresca los datos del usuario
  Future<void> refreshUser() async {
    if (!isAuthenticated) return;

    _setLoading(true);
    // Solo recargar desde cache local, NO verificar sesión en servidor
    await _loadBasicUserData();
    _setLoading(false);
  }

  /// Obtiene el UUID segment del usuario actual (primeros 8 caracteres)
  String? getCurrentUserUuidSegment() {
    if (_user?.id == null) return null;

    final userId = _user!.id;
    // Remover guiones y tomar primeros 8 caracteres
    final cleanId = userId.replaceAll('-', '');
    return cleanId.length >= 8 ? cleanId.substring(0, 8) : null;
  }

  // Métodos privados para manejo de estado
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Limpia todos los datos del provider
  void clear() {
    _user = null;
    _isLoading = false;
    _errorMessage = null;
    _isInitialized = false;
    notifyListeners();
  }
}
