import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/config/api_config.dart';
import 'package:meliapp_flutter/models/oauth_callback.dart';

void main() {
  test('parsea authorization code del puente OAuth', () {
    final payload = OAuthCallbackPayload.fromUri(
      Uri.parse('http://127.0.0.1:47821/oauth?code=abc123'),
    );
    expect(payload.hasCode, isTrue);
    expect(payload.code, 'abc123');
    expect(payload.isValid, isTrue);
  });

  test('parsea tokens implícitos del puente OAuth', () {
    final payload = OAuthCallbackPayload.fromQuery({
      'access_token': 'tok',
      'refresh_token': 'ref',
    });
    expect(payload.hasAccessToken, isTrue);
    expect(payload.refreshToken, 'ref');
  });

  test('rechaza un callback vacío', () {
    expect(OAuthCallbackPayload.fromQuery({}).isValid, isFalse);
  });

  test('parsea el puente nativo meliapp://oauth', () {
    final payload = OAuthCallbackPayload.fromUri(
      Uri.parse('meliapp://oauth?code=abc123'),
    );
    expect(payload.hasCode, isTrue);
    expect(payload.code, 'abc123');
    expect(payload.isValid, isTrue);
  });

  test('parsea tokens del fragmento de /auth/callback', () {
    final payload = OAuthCallbackPayload.fromUri(
      Uri.parse(
        'https://www.meliapp.cl/auth/callback#access_token=tok&refresh_token=ref',
      ),
    );
    expect(payload.hasAccessToken, isTrue);
    expect(payload.accessToken, 'tok');
    expect(payload.refreshToken, 'ref');
  });

  test('ApiConfig declara el puerto loopback y los endpoints Google', () {
    expect(ApiConfig.oauthLoopbackPort, 47821);
    expect(ApiConfig.oauthAppScheme, 'meliapp');
    expect(ApiConfig.oauthAppHost, 'oauth');
    expect(ApiConfig.oauthNativeRedirect, 'meliapp://oauth');
    expect(ApiConfig.googleAuthEndpoint, '/api/auth/google');
    expect(ApiConfig.googleCallbackEndpoint, '/api/auth/google/callback');
    expect(ApiConfig.oauthTokensEndpoint, '/api/auth/oauth/tokens');
  });
}
