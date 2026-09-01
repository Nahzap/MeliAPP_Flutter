import 'dart:convert';
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
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);

    try {
      _user = await _authService.restoreSession();
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

  /// Login con Google OAuth (MeliAPP Cloud).
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _authService.loginWithGoogle();
      if (response.success) {
        await _loadBasicUserData();
        final live = await _authService.fetchCurrentProfile();
        if (live != null) _user = live;
        return _user != null;
      }
      _setError(response.error ?? 'No se pudo iniciar sesión con Google');
      return false;
    } catch (e) {
      _setError('No se pudo iniciar sesión con Google');
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
    required String tipoUsuario,
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
        tipoUsuario: tipoUsuario,
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

  Future<void> _loadBasicUserData() async {
    try {
      final cached = await _authService.getCachedUser();
      if (cached != null) {
        _user = cached;
        return;
      }

      final userData = await _authService.getBasicUserData();

      if (userData['id'] != null && userData['username'] != null) {
        _user = User.fromJson({
          'auth_user_id': userData['id'],
          'username': userData['username'],
          'tipo_usuario': userData['tipo_usuario'],
          'role': userData['role'],
          'status': userData['status'],
          'activo': userData['activo'] == 'true',
          'fecha_registro': userData['fecha_registro'],
          'last_login': userData['last_login'],
          'nombre_completo': userData['nombre_completo'],
          'nombre_empresa': userData['nombre_empresa'],
          'correo_principal': userData['email'],
          'telefono_principal': userData['telefono'],
          'direccion': userData['direccion'],
          'comuna': userData['comuna'],
          'region': userData['region'],
          'ubicaciones': _decodeJsonList(userData['ubicaciones']),
          'redes_sociales': _decodeJsonMap(userData['redes_sociales']),
        });
      }
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] Error cargando datos: $e');
    }
  }

  /// Recarga el perfil desde Cloud (no solo cache local)
  Future<void> refreshUser() async {
    _setLoading(true);
    try {
      final live = await _authService.fetchCurrentProfile();
      if (live != null) {
        _user = live;
      } else {
        await _loadBasicUserData();
      }
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] Error refrescando perfil: $e');
      await _loadBasicUserData();
    } finally {
      _setLoading(false);
    }
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

  dynamic _decodeJsonList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return jsonDecode(raw);
    } catch (_) {
      return [];
    }
  }

  dynamic _decodeJsonMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      return jsonDecode(raw);
    } catch (_) {
      return {};
    }
  }
}
