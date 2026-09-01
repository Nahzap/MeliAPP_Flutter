import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/config/register_messages.dart';

void main() {
  test('mapea códigos de Cloud y nunca muestra SMTP', () {
    expect(
      RegisterMessages.fromResponse({'code': 'email_not_delivered'}),
      RegisterMessages.emailNotDelivered,
    );
    expect(
      RegisterMessages.fromResponse({
        'error':
            'Error al enviar email de confirmación. Verifica configuración SMTP en Supabase Dashboard.',
      }),
      RegisterMessages.emailNotDelivered,
    );
    expect(RegisterMessages.canResend({'code': 'email_not_delivered'}), isTrue);
    expect(
      RegisterMessages.fromResponse({'code': 'registered_pending_email'}),
      RegisterMessages.pendingEmail,
    );
  });
}
