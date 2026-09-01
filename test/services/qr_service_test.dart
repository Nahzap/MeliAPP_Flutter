import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/services/qr_service.dart';

void main() {
  late QRService service;

  setUp(() {
    service = QRService();
  });

  group('isValidUuidSegment', () {
    test('acepta 8 caracteres hexadecimales', () {
      expect(service.isValidUuidSegment('550e8400'), isTrue);
      expect(service.isValidUuidSegment('ABCDEF12'), isTrue);
    });

    test('rechaza largo incorrecto o caracteres no hex', () {
      expect(service.isValidUuidSegment('550e840'), isFalse);
      expect(service.isValidUuidSegment('550e84001'), isFalse);
      expect(service.isValidUuidSegment('550e84zz'), isFalse);
      expect(service.isValidUuidSegment(''), isFalse);
    });
  });

  group('extractUuidFromQR', () {
    test('extrae el segmento de una URL válida del dominio Vercel', () {
      const qr = 'https://meli-app-cloud.vercel.app/api/usuario/550e8400';

      expect(service.extractUuidFromQR(qr), '550e8400');
    });

    test('acepta el dominio de MeliAPP Cloud', () {
      const qr = 'https://www.meliapp.cl/api/usuario/550e8400';

      expect(service.extractUuidFromQR(qr), '550e8400');
    });

    test('acepta URL de perfil Cloud', () {
      const qr =
          'https://www.meliapp.cl/profile/bf9b4b99-21dc-4881-bc95-fdd290d696f8';

      expect(service.parseProfileRef(qr)?.userId, startsWith('bf9b4b99'));
    });

    test('retorna null si el host no es el dominio esperado', () {
      expect(
        service.extractUuidFromQR(
          'https://meli-app-cloud.vercel.app/api/lote/550e8400',
        ),
        isNull,
      );
      expect(
        service.extractUuidFromQR(
          'https://meli-app-cloud.vercel.app/api/usuario/abc',
        ),
        isNull,
      );
      expect(service.extractUuidFromQR('no-es-una-url'), isNull);
    });
  });

  group('buildUserUrl y getUserInfoFromQR', () {
    test('construye la URL de perfil con el segmento', () {
      expect(
        service.buildUserUrl('550e8400'),
        'https://www.meliapp.cl/api/usuario/550e8400',
      );
    });

    test(
      'getUserInfoFromQR retorna segmento y URL si el QR es válido',
      () async {
        final info = await service.getUserInfoFromQR(
          'https://www.meliapp.cl/api/usuario/550e8400',
        );

        expect(info, isNotNull);
        expect(info!['uuid_segment'], '550e8400');
        expect(info['profile_url'], 'https://www.meliapp.cl/profile/550e8400');
        expect(info['scanned_at'], isA<String>());
      },
    );

    test('getUserInfoFromQR retorna null si el QR no es válido', () async {
      final info = await service.getUserInfoFromQR(
        'https://example.com/api/usuario/550e8400',
      );

      expect(info, isNull);
    });
  });

  group('generateUserQR', () {
    test('falla en cliente si el segmento no tiene 8 caracteres', () async {
      final response = await service.generateUserQR('abc');

      expect(response, isNotNull);
      expect(response!.success, isFalse);
      expect(response.error, contains('8 caracteres'));
    });
  });
}
