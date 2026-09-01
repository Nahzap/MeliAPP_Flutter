/// Copy de registro alineado con Cloud (`AuthManager._public_register_message`).
class RegisterMessages {
  static const pendingEmail =
      'Cuenta creada. Revisa tu correo y confirma el enlace para activarla. '
      'Si no llega, mira en spam o pulsa reenviar.';

  static const emailNotDelivered =
      'La cuenta quedó pendiente de confirmación, pero no pudimos enviar el correo. '
      'Pulsa reenviar o inténtalo en unos minutos.';

  static const duplicateEmail =
      'Ese correo ya tiene una cuenta. Inicia sesión o recupera tu contraseña.';

  static const rateLimited =
      'Has alcanzado el límite de intentos de registro. Espera un momento o usa otro correo.';

  static const fallback = 'No se pudo crear la cuenta. Inténtalo de nuevo.';

  static String fromResponse(Map<String, dynamic> data) {
    switch (data['code']?.toString()) {
      case 'registered_pending_email':
        return pendingEmail;
      case 'email_not_delivered':
        return emailNotDelivered;
      case 'duplicate_email':
        return duplicateEmail;
      case 'rate_limited':
        return rateLimited;
    }
    final raw = '${data['message'] ?? ''} ${data['error'] ?? ''}'.trim();
    if (RegExp(r'smtp|dashboard|resend', caseSensitive: false).hasMatch(raw)) {
      return emailNotDelivered;
    }
    final message = (data['message'] ?? data['error'])?.toString().trim();
    if (message == null || message.isEmpty) return fallback;
    return message;
  }

  static bool canResend(Map<String, dynamic> data) {
    if (data['can_resend'] == true) return true;
    final code = data['code']?.toString();
    return code == 'email_not_delivered' || code == 'registered_pending_email';
  }
}
