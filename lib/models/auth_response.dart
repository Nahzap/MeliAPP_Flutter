/// Modelo para las respuestas de autenticación de la API REST
class AuthResponse {
  final bool success;
  final String? message;
  final String? error;
  final String? redirectUrl;

  AuthResponse({
    required this.success,
    this.message,
    this.error,
    this.redirectUrl,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      error: json['error'] as String?,
      redirectUrl: json['redirect_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'error': error,
      'redirect_url': redirectUrl,
    };
  }

  @override
  String toString() {
    return 'AuthResponse{success: $success, message: $message, error: $error}';
  }
}
