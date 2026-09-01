/// Resultado del puente OAuth Cloud → Flutter (loopback 127.0.0.1).
class OAuthCallbackPayload {
  final String? code;
  final String? accessToken;
  final String? refreshToken;

  const OAuthCallbackPayload({this.code, this.accessToken, this.refreshToken});

  bool get hasCode => code != null && code!.trim().isNotEmpty;
  bool get hasAccessToken =>
      accessToken != null && accessToken!.trim().isNotEmpty;

  bool get isValid => hasCode || hasAccessToken;

  factory OAuthCallbackPayload.fromQuery(Map<String, String> query) {
    return OAuthCallbackPayload(
      code: query['code'],
      accessToken: query['access_token'],
      refreshToken: query['refresh_token'],
    );
  }

  factory OAuthCallbackPayload.fromUri(Uri uri) {
    final query = Map<String, String>.from(uri.queryParameters);
    if (uri.fragment.isNotEmpty) {
      query.addAll(Uri.splitQueryString(uri.fragment));
    }
    return OAuthCallbackPayload.fromQuery(query);
  }
}
