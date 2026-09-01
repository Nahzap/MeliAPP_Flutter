import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/models/auth_response.dart';
import 'package:meliapp_flutter/models/qr_response.dart';
import 'package:meliapp_flutter/models/session_response.dart';

void main() {
  group('AuthResponse', () {
    test('parsea login exitoso', () {
      final response = AuthResponse.fromJson({
        'success': true,
        'message': 'Bienvenido',
        'redirect_url': '/home',
      });

      expect(response.success, isTrue);
      expect(response.message, 'Bienvenido');
      expect(response.redirectUrl, '/home');
      expect(response.error, isNull);
    });

    test('parsea error de credenciales', () {
      final response = AuthResponse.fromJson({
        'success': false,
        'error': 'Credenciales inválidas',
      });

      expect(response.success, isFalse);
      expect(response.error, 'Credenciales inválidas');
    });

    test('toJson conserva redirect_url', () {
      final json = AuthResponse(success: true, redirectUrl: '/home').toJson();

      expect(json['redirect_url'], '/home');
      expect(json['success'], isTrue);
    });
  });

  group('SessionResponse', () {
    test('parsea sesión activa con usuario anidado', () {
      final response = SessionResponse.fromJson({
        'success': true,
        'logged_in': true,
        'user': {
          'auth_user_id': 'uuid-1',
          'username': 'apicultor',
          'correo_principal': 'ana@meliapp.cl',
        },
      });

      expect(response.success, isTrue);
      expect(response.loggedIn, isTrue);
      expect(response.user?.id, 'uuid-1');
      expect(response.user?.username, 'apicultor');
      expect(response.user?.email, 'ana@meliapp.cl');
    });

    test('deja user nulo si no viene en el JSON', () {
      final response = SessionResponse.fromJson({
        'success': true,
        'logged_in': false,
      });

      expect(response.loggedIn, isFalse);
      expect(response.user, isNull);
    });
  });

  group('QRResponse', () {
    test('parsea QR generado', () {
      final response = QRResponse.fromJson({
        'success': true,
        'qr_code': 'data:image/png;base64,abc',
        'user_id': 'uuid-1',
        'uuid_segment': '550e8400',
      });

      expect(response.success, isTrue);
      expect(response.qrCode, startsWith('data:image/png'));
      expect(response.uuidSegment, '550e8400');
    });

    test('parsea error de generación', () {
      final response = QRResponse.fromJson({
        'success': false,
        'error': 'Usuario no encontrado',
      });

      expect(response.success, isFalse);
      expect(response.error, 'Usuario no encontrado');
    });
  });
}
