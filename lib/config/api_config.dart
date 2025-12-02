/// Configuración centralizada para la comunicación con la API REST
class ApiConfig {
  // URL base de tu API REST en Vercel
  static const String baseUrl = 'https://meli-app-cloud.vercel.app';

  // Endpoints de autenticación
  static const String loginEndpoint = '/api/auth/login';
  static const String sessionEndpoint = '/api/auth/session';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String registerEndpoint = '/api/auth/register';

  // Endpoints de usuario
  static const String userQREndpoint = '/api/usuario';

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
