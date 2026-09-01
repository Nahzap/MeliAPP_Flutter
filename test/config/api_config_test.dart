import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('apunta a meliapp.cl y endpoints de auth', () {
      expect(ApiConfig.baseUrl, ApiConfig.productionUrl);
      expect(ApiConfig.displayHost, 'www.meliapp.cl');
      expect(ApiConfig.qrHosts, contains('www.meliapp.cl'));
      expect(ApiConfig.loginEndpoint, '/api/auth/login');
      expect(ApiConfig.sessionEndpoint, '/api/auth/session');
      expect(ApiConfig.logoutEndpoint, '/api/auth/logout');
      expect(ApiConfig.registerEndpoint, '/api/auth/register');
      expect(
        ApiConfig.resendConfirmationEndpoint,
        '/api/auth/resend-confirmation',
      );
      expect(ApiConfig.googleAuthEndpoint, '/api/auth/google');
      expect(ApiConfig.userQREndpoint, '/api/usuario');
      expect(ApiConfig.certificadoPreviewEndpoint, '/certificado-preview');
    });

    test('define timeouts y headers JSON', () {
      expect(ApiConfig.connectTimeout, const Duration(seconds: 30));
      expect(ApiConfig.receiveTimeout, const Duration(seconds: 30));
      expect(ApiConfig.sendTimeout, const Duration(seconds: 30));
      expect(ApiConfig.defaultHeaders['Content-Type'], 'application/json');
      expect(ApiConfig.defaultHeaders['Accept'], 'application/json');
    });
  });
}
