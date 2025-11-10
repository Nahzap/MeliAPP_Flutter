import 'package:flutter/foundation.dart';
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
    await _checkAuthStatus();
    _isInitialized = true;
    _setLoading(false);
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
      _setError('Error de conexión: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registra un nuevo usuario
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _authService.register(
        username: username,
        email: email,
        password: password,
      );
      
      if (result['success'] == true) {
        _user = result['user'] as User?;
        print('[AUTH_PROVIDER] Usuario registrado: ${_user?.username}');
      }
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'error': 'Error al registrar: $e',
      };
    }
  }

  /// Cierra sesión del usuario
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();
    } catch (e) {
      print('Error durante logout: $e');
    } finally {
      _user = null;
      _clearError();
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
      print('Error verificando estado de auth: $e');
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
        print('[AUTH_PROVIDER] Datos completos cargados: ${_user!.username}');
        if (_user!.role != null) {
          print('[AUTH_PROVIDER] Role: ${_user!.role}');
        }
        if (_user!.tipoUsuario != null) {
          print('[AUTH_PROVIDER] Tipo: ${_user!.tipoUsuario}');
        }
      }
    } catch (e) {
      print('[AUTH_PROVIDER] Error cargando datos: $e');
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
