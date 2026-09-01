import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/models/search_models.dart';
import 'package:meliapp_flutter/services/keyword_search_service.dart';

/// Adaptador que responde sin red y registra lo que se pidió.
class _StubAdapter implements HttpClientAdapter {
  int status;
  Object body;
  DioExceptionType? failWith;

  final List<RequestOptions> requests = [];

  _StubAdapter({this.status = 200, this.body = const {}});

  int get callCount => requests.length;
  RequestOptions get lastRequest => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (failWith != null) {
      throw DioException(requestOptions: options, type: failWith!);
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

KeywordSearchService _serviceWith(_StubAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.httpClientAdapter = adapter;
  return KeywordSearchService(dio: dio);
}

const _chipUlmo = KeywordChip(
  term: 'Ulmo',
  normalized: 'ulmo',
  category: 'especie',
  label: 'Especie',
);
const _chipValdivia = KeywordChip(
  term: 'Valdivia',
  normalized: 'valdivia',
  category: 'lugar',
  label: 'Lugar',
);

void main() {
  group('Debouncer', () {
    test('agrupa una ráfaga de tecleo en una sola llamada', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 40));
      var ejecuciones = 0;

      for (var i = 0; i < 6; i++) {
        debouncer.run(() => ejecuciones++);
        await Future<void>.delayed(const Duration(milliseconds: 8));
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(ejecuciones, 1);
    });

    test('cancel evita la ejecución pendiente', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 30));
      var ejecuciones = 0;

      debouncer.run(() => ejecuciones++);
      expect(debouncer.isPending, isTrue);
      debouncer.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(ejecuciones, 0);
    });
  });

  group('suggest', () {
    test('pide /api/search/suggest con el texto recortado', () async {
      final adapter = _StubAdapter(
        body: {'ok': true, 'valid': true, 'query_type': 'keyword'},
      );

      await _serviceWith(adapter).suggest('  ulmo  ');

      expect(adapter.lastRequest.path, '/api/search/suggest');
      expect(adapter.lastRequest.queryParameters['q'], 'ulmo');
    });

    test('devuelve el veredicto de frase sin lanzar', () async {
      final adapter = _StubAdapter(
        body: {
          'valid': false,
          'query_type': 'sentence',
          'reason': 'Usa palabras clave',
          'suggestions': [
            {'term': 'Ulmo', 'category': 'especie'},
          ],
        },
      );

      final resultado = await _serviceWith(adapter).suggest('quiero miel');

      expect(resultado.isSentence, isTrue);
      expect(resultado.reason, 'Usa palabras clave');
      expect(resultado.suggestions.single.term, 'Ulmo');
    });
  });

  group('search', () {
    test('envía una k por cada palabra clave y el límite', () async {
      final adapter = _StubAdapter(body: {'ok': true, 'results': []});

      await _serviceWith(adapter).search([_chipUlmo, _chipValdivia], limit: 15);

      final query = adapter.lastRequest.uri.queryParametersAll;
      expect(adapter.lastRequest.path, '/api/search/keywords');
      expect(query['k'], ['Ulmo', 'Valdivia']);
      expect(query['limit'], ['15']);
    });

    test('no llama al servidor si no hay palabras clave', () async {
      final adapter = _StubAdapter();

      final resultado = await _serviceWith(adapter).search([]);

      expect(adapter.callCount, 0);
      expect(resultado.ok, isFalse);
      expect(resultado.results, isEmpty);
    });

    test('un 400 se lee como rechazo explicado, no como excepción', () async {
      final adapter = _StubAdapter(
        status: 400,
        body: {
          'ok': false,
          'query_type': 'sentence',
          'reason': 'El buscador solo acepta palabras clave',
          'results': [],
          'suggestions': [
            {'term': 'Ulmo', 'category': 'especie'},
          ],
        },
      );

      final resultado = await _serviceWith(adapter).search([_chipUlmo]);

      expect(resultado.ok, isFalse);
      expect(resultado.isSentence, isTrue);
      expect(resultado.reason, contains('palabras clave'));
      expect(resultado.suggestions, hasLength(1));
    });

    test('deserializa los perfiles y su evidencia', () async {
      final adapter = _StubAdapter(
        body: {
          'ok': true,
          'query_type': 'keyword',
          'count': 1,
          'results': [
            {
              'auth_user_id': 'uuid-1',
              'nombre': 'Paula Gonzalez',
              'comuna': 'Futrono',
              'region': 'Los Rios',
              'score': 5,
              'matches': [
                {
                  'category': 'polen',
                  'term': 'ulmo',
                  'evidence': 'Ulmo (62%)',
                  'confidence': 'certified_pollen',
                  'label': 'Polen',
                },
              ],
            },
          ],
        },
      );

      final resultado = await _serviceWith(adapter).search([_chipUlmo]);

      expect(resultado.ok, isTrue);
      expect(resultado.results.single.nombre, 'Paula Gonzalez');
      expect(resultado.results.single.ubicacion, 'Futrono, Los Rios');
      expect(resultado.results.single.matches.single.display, 'Polen: Ulmo (62%)');
    });

    test('sin conexión entrega un mensaje accionable', () async {
      final adapter = _StubAdapter()..failWith = DioExceptionType.connectionError;

      expect(
        () => _serviceWith(adapter).search([_chipUlmo]),
        throwsA(
          isA<SearchException>().having(
            (e) => e.message,
            'message',
            contains('Sin conexión'),
          ),
        ),
      );
    });

    test('un tiempo de espera agotado se explica al usuario', () async {
      final adapter = _StubAdapter()..failWith = DioExceptionType.receiveTimeout;

      expect(
        () => _serviceWith(adapter).suggest('ulmo'),
        throwsA(
          isA<SearchException>().having(
            (e) => e.message,
            'message',
            contains('tardó demasiado'),
          ),
        ),
      );
    });

    test('un 503 del motor no se convierte en excepción de transporte', () async {
      final adapter = _StubAdapter(
        status: 503,
        body: {
          'ok': false,
          'query_type': 'error',
          'reason': 'No se pudo completar la búsqueda.',
          'results': [],
        },
      );

      // 5xx sí es fallo de transporte: debe llegar como SearchException.
      expect(
        () => _serviceWith(adapter).search([_chipUlmo]),
        throwsA(isA<SearchException>()),
      );
    });
  });

  test('el tope de palabras clave coincide con el de Cloud', () {
    expect(KeywordSearchService.maxKeywords, 5);
  });
}
