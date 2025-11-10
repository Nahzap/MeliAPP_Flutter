import 'user_model.dart';

/// Modelo para la respuesta del endpoint de verificación de sesión
class SessionResponse {
  final bool success;
  final bool loggedIn;
  final User? user;
  final String? error;

  SessionResponse({
    required this.success,
    required this.loggedIn,
    this.user,
    this.error,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      success: json['success'] as bool,
      loggedIn: json['logged_in'] as bool,
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'logged_in': loggedIn,
      'user': user?.toJson(),
      'error': error,
    };
  }

  @override
  String toString() {
    return 'SessionResponse{success: $success, loggedIn: $loggedIn, user: $user}';
  }
}
