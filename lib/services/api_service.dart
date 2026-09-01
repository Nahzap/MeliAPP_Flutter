import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
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
  Future<void>? _initFuture;

  /// Cookies persistentes (sobreviven al cerrar la app). En tests/web: memoria.
  Future<void> initialize() {
    _initFuture ??= _doInitialize();
    return _initFuture!;
  }

  Future<void> _doInitialize() async {
    if (_initialized) return;

    CookieJar jar = CookieJar();
    if (!kIsWeb) {
      try {
        final dir = await getApplicationSupportDirectory();
        jar = PersistCookieJar(
          storage: FileStorage('${dir.path}/meliapp_cookies'),
        );
      } catch (e) {
        debugPrint('[API] Cookies en memoria (sin persistencia): $e');
      }
    }
    _cookieJar = jar;

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: ApiConfig.defaultHeaders,
      ),
    );

    _dio.interceptors.add(CookieManager(_cookieJar));

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
    if (!_initialized) {
      throw StateError('ApiService.initialize() debe completarse primero');
    }
    return _dio;
  }

  /// Getter para acceso al jar de cookies
  CookieJar get cookieJar {
    if (!_initialized) {
      throw StateError('ApiService.initialize() debe completarse primero');
    }
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
    await initialize();

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
    await initialize();
    try {
      final response = await _dio.get(ApiConfig.sessionEndpoint);
      return _asJsonMap(response.data);
    } catch (e) {
      debugPrint('[API] Error en checkSession: $e');
      rethrow;
    }
  }

  /// Obtiene los datos completos del usuario actual desde el servidor
  /// Usa el NUEVO endpoint /api/profile/me que retorna usuarios + info_contacto
  Future<Map<String, dynamic>> getCurrentUser() async {
    await initialize();
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

  /// Registrar nuevo usuario (mismo POST que Cloud).
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String tipoUsuario,
  }) async {
    await initialize();
    try {
      debugPrint('[API] Registrando nuevo usuario: $email');
      final response = await _dio.post(
        ApiConfig.registerEndpoint,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'tipo_usuario': tipoUsuario,
        },
      );
      debugPrint('[API] Registro exitoso: ${response.data}');
      return _asJsonMap(response.data);
    } on DioException catch (e) {
      debugPrint('[API] Error en registro: $e');
      return _oauthErrorBody(e, 'Error al registrar usuario');
    }
  }

  Future<Map<String, dynamic>> resendConfirmation(String email) async {
    await initialize();
    try {
      final response = await _dio.post(
        ApiConfig.resendConfirmationEndpoint,
        data: {'email': email},
      );
      return _asJsonMap(response.data);
    } on DioException catch (e) {
      return _oauthErrorBody(e, 'No se pudo reenviar el correo');
    }
  }

  /// Inicia OAuth Google (Cloud POST /api/auth/google).
  Future<Map<String, dynamic>> startGoogleAuth({String? redirectTo}) async {
    await initialize();
    try {
      final response = await _dio.post(
        ApiConfig.googleAuthEndpoint,
        data: {
          if (redirectTo != null && redirectTo.isNotEmpty)
            'redirect_to': redirectTo,
        },
      );
      return _asJsonMap(response.data);
    } on DioException catch (e) {
      return _oauthErrorBody(e, 'No se pudo iniciar Google');
    }
  }

  /// Completa OAuth con authorization code.
  Future<Map<String, dynamic>> completeGoogleCallback(String code) async {
    await initialize();
    try {
      final response = await _dio.post(
        ApiConfig.googleCallbackEndpoint,
        data: {'code': code},
      );
      return _asJsonMap(response.data);
    } on DioException catch (e) {
      return _oauthErrorBody(e, 'No se pudo completar Google');
    }
  }

  /// Completa OAuth implícito con tokens del fragmento.
  Future<Map<String, dynamic>> completeOAuthTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await initialize();
    try {
      final response = await _dio.post(
        ApiConfig.oauthTokensEndpoint,
        data: {
          'access_token': accessToken,
          if (refreshToken != null && refreshToken.isNotEmpty)
            'refresh_token': refreshToken,
        },
      );
      return _asJsonMap(response.data);
    } on DioException catch (e) {
      return _oauthErrorBody(e, 'No se pudo completar Google');
    }
  }

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'success': false, 'error': 'Respuesta inválida del servidor'};
  }

  Map<String, dynamic> _oauthErrorBody(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'success': false, 'error': fallback};
  }

  /// Misma ruta que Cloud: POST JSON → HTML de `certificado_preview.html`.
  Future<String> fetchCertificadoPreview(Map<String, dynamic> payload) async {
    await initialize();
    final response = await _dio.post(
      ApiConfig.certificadoPreviewEndpoint,
      data: payload,
      options: Options(
        responseType: ResponseType.plain,
        contentType: 'application/json',
        headers: const {'Accept': 'text/html'},
      ),
    );
    final html = response.data?.toString() ?? '';
    if (html.contains('Certificado de Origen') ||
        html.contains('IEEE Style Preview')) {
      return html;
    }
    throw StateError('Cloud no devolvió la plantilla IEEE del certificado');
  }

  /// Obtener información de un usuario por ID
  Future<Map<String, dynamic>> getUserById(String userId) async {
    await initialize();
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
  Future<void> clearCookies() async {
    await initialize();
    await _cookieJar.deleteAll();
  }

  /// Verificar si hay cookies de sesión
  Future<bool> hasCookies() async {
    await initialize();
    final cookies = await _cookieJar.loadForRequest(
      Uri.parse(ApiConfig.baseUrl),
    );
    return cookies.any(
      (c) => c.name == 'meliapp_session' && c.value.isNotEmpty,
    );
  }
}
