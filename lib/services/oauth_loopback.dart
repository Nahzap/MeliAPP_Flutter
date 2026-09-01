import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/oauth_callback.dart';

/// Servidor local para recibir el puente OAuth desde `/auth/callback` de Cloud.
class OAuthLoopbackServer {
  HttpServer? _server;
  Completer<OAuthCallbackPayload>? _completer;

  bool get isRunning => _server != null;

  Future<void> start() async {
    await stop();
    _completer = Completer<OAuthCallbackPayload>();
    _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      ApiConfig.oauthLoopbackPort,
    );
    _server!.listen(
      _handle,
      onError: (Object error) {
        debugPrint('[OAUTH] Error en loopback: $error');
      },
    );
    debugPrint(
      '[OAUTH] Escuchando en http://127.0.0.1:${ApiConfig.oauthLoopbackPort}/oauth',
    );
  }

  Future<OAuthCallbackPayload> waitForPayload({
    Duration timeout = const Duration(minutes: 3),
  }) {
    final completer = _completer;
    if (completer == null) {
      return Future.error(StateError('Loopback OAuth no iniciado'));
    }
    return completer.future.timeout(timeout);
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
    final pending = _completer;
    _completer = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(
        TimeoutException('Inicio de sesión con Google cancelado'),
      );
    }
  }

  void _handle(HttpRequest request) {
    _cors(request.response);
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      request.response.close();
      return;
    }

    final payload = OAuthCallbackPayload.fromUri(request.uri);
    request.response
      ..statusCode = payload.isValid ? HttpStatus.ok : HttpStatus.badRequest
      ..headers.contentType = ContentType.html
      ..write(
        payload.isValid
            ? '<html><body><p>Puedes volver a MeliAPP.</p></body></html>'
            : '<html><body><p>Callback inválido.</p></body></html>',
      );
    request.response.close();

    final completer = _completer;
    if (payload.isValid && completer != null && !completer.isCompleted) {
      completer.complete(payload);
    }
  }

  void _cors(HttpResponse response) {
    response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, OPTIONS')
      ..set('Access-Control-Allow-Headers', '*')
      ..set('Access-Control-Allow-Private-Network', 'true');
  }
}
