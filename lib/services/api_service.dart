import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Servicio principal para comunicación HTTP con la API REST
/// Maneja cookies de sesión Flask automáticamente
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  late CookieJar _cookieJar;
  bool _initialized = false;

  /// Inicializa el servicio con configuración de cookies y timeouts
  void initialize() {
    if (_initialized) return;

    _cookieJar = CookieJar();

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: ApiConfig.defaultHeaders,
      ),
    );

    // Interceptor de cookies para mantener sesión Flask
    _dio.interceptors.add(CookieManager(_cookieJar));

    // Interceptor de logging para debug
    if (ApiConfig.enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (obj) => debugPrint('[API] $obj'),
        ),
      );
    }

    // Interceptor de errores
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          debugPrint('[API ERROR] ${error.message}');
          if (error.response != null) {
            debugPrint('[API ERROR] Status: ${error.response?.statusCode}');
            debugPrint('[API ERROR] Data: ${error.response?.data}');
          }
          handler.next(error);
        },
      ),
    );

    _initialized = true;
  }

  /// Getter para acceso directo al cliente Dio
  Dio get dio {
    if (!_initialized) initialize();
    return _dio;
  }

  /// Getter para acceso al jar de cookies
  CookieJar get cookieJar {
    if (!_initialized) initialize();
    return _cookieJar;
  }

  /// Método genérico para realizar requests HTTP
  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    if (!_initialized) initialize();

    try {
      final options = Options(method: method, headers: headers);

      return await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      debugPrint('[API] DioException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[API] Unexpected error: $e');
      rethrow;
    }
  }

  /// Login con email y password
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await request(
      ApiConfig.loginEndpoint,
      method: 'POST',
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Verificar sesión actual
  Future<Map<String, dynamic>> checkSession() async {
    try {
      final response = await _dio.get('/api/auth/session');
      return response.data;
    } catch (e) {
      debugPrint('[API] Error en checkSession: $e');
      rethrow;
    }
  }

  /// Obtiene los datos completos del usuario actual desde el servidor
  /// Usa el NUEVO endpoint /api/profile/me que retorna usuarios + info_contacto
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      debugPrint('[API] Llamando al NUEVO endpoint /api/profile/me');
      final response = await _dio.get('/api/profile/me');
      debugPrint('[API] Respuesta de /api/profile/me recibida');
      return response.data;
    } catch (e) {
      debugPrint('[API] Error en /api/profile/me: $e');
      debugPrint('[API] Intentando fallback a /api/user/current...');
      try {
        final response = await _dio.get('/api/user/current');
        debugPrint('[API] Fallback exitoso');
        return response.data;
      } catch (fallbackError) {
        debugPrint('[API] Fallback también falló: $fallbackError');
        rethrow;
      }
    }
  }

  /// Registrar nuevo usuario
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[API] Registrando nuevo usuario: $email');
      final response = await _dio.post(
        '/api/auth/register',
        data: {'username': username, 'email': email, 'password': password},
      );
      debugPrint('[API] Registro exitoso: ${response.data}');
      return response.data;
    } catch (e) {
      debugPrint('[API] Error en registro: $e');
      rethrow;
    }
  }

  /// Obtener información de un usuario por ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      debugPrint('[API] Obteniendo info de usuario: $userId');
      final response = await _dio.get('/api/profile/$userId');
      debugPrint('[API] Info usuario obtenida');
      return response.data;
    } catch (e) {
      debugPrint('[API] Error obteniendo usuario: $e');
      rethrow;
    }
  }

  /// Cerrar sesión
  Future<Map<String, dynamic>> logout() async {
    final response = await request(ApiConfig.logoutEndpoint, method: 'POST');
    return response.data as Map<String, dynamic>;
  }

  /// Obtener QR de usuario
  Future<Map<String, dynamic>> getUserQR(String uuidSegment) async {
    final response = await request(
      '${ApiConfig.userQREndpoint}/$uuidSegment/qr',
      queryParameters: {'format': 'json'},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Limpiar cookies (útil para logout completo)
  void clearCookies() {
    _cookieJar.deleteAll();
  }

  /// Verificar si hay cookies de sesión
  Future<bool> hasCookies() async {
    final cookies = await _cookieJar.loadForRequest(
      Uri.parse(ApiConfig.baseUrl),
    );
    return cookies.isNotEmpty;
  }
}
