/// Configuración centralizada para la comunicación con MeliAPP Cloud
class ApiConfig {
  static const String productionUrl = 'https://www.meliapp.cl';
  static const String localUrl = 'http://127.0.0.1:3000';
  static const String displayHost = 'www.meliapp.cl';

  /// Producción por defecto. Local: `--dart-define=MELIAPP_USE_LOCAL=true`
  /// o `--dart-define=MELIAPP_API_BASE=http://127.0.0.1:3000`.
  static String get baseUrl {
    const override = String.fromEnvironment('MELIAPP_API_BASE');
    if (override.isNotEmpty) return override;
    const useLocal = bool.fromEnvironment('MELIAPP_USE_LOCAL');
    if (useLocal) return localUrl;
    return productionUrl;
  }

  static const List<String> qrHosts = [
    'www.meliapp.cl',
    'meliapp.cl',
    'meli-app-cloud.vercel.app',
    '127.0.0.1',
    'localhost',
  ];

  static const String loginEndpoint = '/api/auth/login';
  static const String sessionEndpoint = '/api/auth/session';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String registerEndpoint = '/api/auth/register';
  static const String resendConfirmationEndpoint =
      '/api/auth/resend-confirmation';
  static const String googleAuthEndpoint = '/api/auth/google';
  static const String googleCallbackEndpoint = '/api/auth/google/callback';
  static const String oauthTokensEndpoint = '/api/auth/oauth/tokens';

  /// Puerto local donde Cloud (`/auth/callback`) avisa a Flutter en escritorio.
  static const int oauthLoopbackPort = 47821;

  /// Callback nativo del visor Android (`meliapp://oauth`).
  static const String oauthAppScheme = 'meliapp';
  static const String oauthAppHost = 'oauth';
  static const String oauthNativeRedirect = '$oauthAppScheme://$oauthAppHost';

  // Endpoints de usuario
  static const String userQREndpoint = '/api/usuario';
  static const String certificadoPreviewEndpoint = '/certificado-preview';

  // Búsqueda por palabras clave (API REST de Cloud)
  static const String searchSuggestEndpoint = '/api/search/suggest';
  static const String searchKeywordsEndpoint = '/api/search/keywords';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Configuración de logging
  static const bool enableLogging = true;
}
