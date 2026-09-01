import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/search_models.dart';
import 'api_service.dart';

/// Retrasa una acción hasta que el usuario deja de escribir.
///
/// Sin esto, cada tecla dispara una petición: una consulta de 10 caracteres
/// genera 9 llamadas al servidor.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  bool get isPending => _timer?.isActive ?? false;

  void dispose() => _timer?.cancel();
}

/// Cliente de la API REST de búsqueda por palabras clave de MeliAPP Cloud.
///
/// El servidor decide qué es una palabra clave y qué es una frase; aquí solo
/// se aplican guardas locales que no dependen del catálogo (tope de chips,
/// duplicados y longitud mínima).
class KeywordSearchService {
  final ApiService? _apiService;
  final Dio? _dioOverride;

  /// [dio] permite inyectar un cliente en tests sin inicializar [ApiService].
  KeywordSearchService({ApiService? apiService, Dio? dio})
    : _apiService = apiService,
      _dioOverride = dio;

  Dio get _client => _dioOverride ?? (_apiService ?? ApiService()).dio;

  /// Tope de palabras clave. Debe coincidir con `MAX_KEYWORDS` en Cloud.
  static const int maxKeywords = 5;

  /// Longitud mínima antes de pedir sugerencias.
  static const int minQueryLength = 2;

  /// Espera tras la última tecla antes de consultar.
  static const Duration debounceDelay = Duration(milliseconds: 300);

  /// Cualquier respuesta que el servidor sepa explicar se lee del cuerpo.
  /// Solo los 5xx se tratan como fallo de transporte.
  static bool _readableStatus(int? status) =>
      status != null && status >= 200 && status < 500;

  /// Sugerencias y veredicto del parser para lo que el usuario lleva escrito.
  ///
  /// Con [query] vacío devuelve las palabras clave populares del catálogo.
  Future<SuggestResult> suggest(
    String query, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _client.get(
        ApiConfig.searchSuggestEndpoint,
        queryParameters: {'q': query.trim()},
        options: Options(validateStatus: _readableStatus),
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data is Map) {
        return SuggestResult.fromJson(Map<String, dynamic>.from(data));
      }
      return SuggestResult.empty;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      debugPrint('[SEARCH] suggest falló: ${e.type}');
      throw SearchException(_messageFor(e));
    }
  }

  /// Busca perfiles apícolas que cumplan **todas** las palabras clave.
  ///
  /// Devuelve el resultado incluso cuando el servidor rechaza la consulta
  /// (HTTP 400): en ese caso `ok` es `false` y `reason` explica por qué.
  Future<KeywordSearchResult> search(
    List<KeywordChip> chips, {
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    if (chips.isEmpty) {
      return const KeywordSearchResult(
        ok: false,
        queryType: 'empty',
        reason: '',
        keywords: [],
        suggestions: [],
        count: 0,
        results: [],
      );
    }

    try {
      final response = await _client.get(
        ApiConfig.searchKeywordsEndpoint,
        queryParameters: {
          'k': chips.map((chip) => chip.term).toList(),
          'limit': limit,
        },
        options: Options(validateStatus: _readableStatus),
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data is Map) {
        return KeywordSearchResult.fromJson(Map<String, dynamic>.from(data));
      }
      throw const SearchException(
        'El servidor devolvió una respuesta inesperada.',
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      debugPrint('[SEARCH] search falló: ${e.type}');
      throw SearchException(_messageFor(e));
    }
  }

  static String _messageFor(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La búsqueda tardó demasiado. Revisa tu conexión.';
      case DioExceptionType.connectionError:
        return 'Sin conexión con MeliAPP. Revisa tu red.';
      default:
        return 'No se pudo completar la búsqueda. Inténtalo de nuevo.';
    }
  }
}
