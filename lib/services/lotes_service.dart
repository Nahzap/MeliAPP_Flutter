import 'package:flutter/foundation.dart';
import '../models/lote_model.dart';
import 'api_service.dart';

/// Servicio para gestionar lotes de miel.
///
/// Consume endpoints de la API REST:
/// - GET `/api/lotes/<usuario_id>`
/// - GET `/api/lote/<lote_id>`
/// - GET `/api/lote/composicion/<lote_id>`
/// - POST `/api/gestionar-lote` - Crear lote (requiere auth)
/// - PUT `/api/lote/<lote_id>` - Actualizar lote (requiere auth)
/// - DELETE `/api/lote/<lote_id>` - Eliminar lote (requiere auth)
class LotesService {
  final ApiService _apiService = ApiService();

  /// Obtiene todos los lotes de un usuario (público, no requiere auth).
  ///
  /// Retorna una lista ordenada por orden_miel.
  Future<List<Lote>> getLotesUsuario(String userId) async {
    try {
      debugPrint('[LOTES] Obteniendo lotes para usuario: $userId');

      final response = await _apiService.dio.get('/api/lotes/$userId');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final lotesData = data['lotes'] as List;
        final lotes = lotesData.map((json) => Lote.fromJson(json)).toList();

        // Ordenar por orden_miel
        lotes.sort((a, b) => a.ordenMiel.compareTo(b.ordenMiel));

        debugPrint('[LOTES] Cargados ${lotes.length} lotes');
        return lotes;
      }

      throw Exception(data['error'] ?? 'Error obteniendo lotes');
    } catch (e) {
      debugPrint('[LOTES] Error: $e');
      rethrow;
    }
  }

  /// Obtiene un lote específico por su ID.
  Future<Lote> getLote(String loteId) async {
    try {
      debugPrint('[LOTES] Obteniendo lote: $loteId');

      final response = await _apiService.dio.get('/api/lote/$loteId');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return Lote.fromJson(data['data']);
      }

      throw Exception(data['error'] ?? 'Lote no encontrado');
    } catch (e) {
      debugPrint('[LOTES] Error obteniendo lote $loteId: $e');
      rethrow;
    }
  }

  /// Obtiene solo la composición de un lote.
  ///
  /// Útil para actualizar solo el gráfico sin recargar todo el lote.
  Future<String> getComposicion(String loteId) async {
    try {
      debugPrint('[LOTES] Obteniendo composición de lote: $loteId');

      final response = await _apiService.dio.get(
        '/api/lote/composicion/$loteId',
      );
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return data['composicion'] ?? '';
      }

      throw Exception(data['error'] ?? 'Composición no encontrada');
    } catch (e) {
      debugPrint('[LOTES] Error obteniendo composición: $e');
      rethrow;
    }
  }

  /// Crea un nuevo lote (requiere autenticación).
  ///
  /// El backend automáticamente asigna auth_user_id del usuario logueado.
  Future<Lote> createLote({
    required int ordenMiel,
    required String nombreMiel,
    required List<String> temporadas,
    required double kgProducidos,
    required String composicionPolen,
  }) async {
    try {
      debugPrint('[LOTES] Creando lote: $nombreMiel');

      final data = {
        'orden_miel': ordenMiel,
        'nombre_miel': nombreMiel,
        'temporadas': temporadas.join(' - '),
        'kg_producidos': kgProducidos,
        'composicion_polen': composicionPolen,
      };

      final response = await _apiService.dio.post(
        '/api/gestionar-lote',
        data: data,
      );
      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        debugPrint('[LOTES] Lote creado exitosamente');
        return Lote.fromJson(responseData['lote']);
      }

      throw Exception(responseData['error'] ?? 'Error creando lote');
    } catch (e) {
      debugPrint('[LOTES] Error creando lote: $e');
      rethrow;
    }
  }

  /// Actualiza un lote existente (requiere autenticación).
  Future<Lote> updateLote(
    String loteId, {
    String? nombreMiel,
    List<String>? temporadas,
    double? kgProducidos,
    String? composicionPolen,
    int? ordenMiel,
  }) async {
    try {
      debugPrint('[LOTES] Actualizando lote: $loteId');

      final data = <String, dynamic>{};
      if (nombreMiel != null) data['nombre_miel'] = nombreMiel;
      if (temporadas != null) data['temporadas'] = temporadas.join(' - ');
      if (kgProducidos != null) data['kg_producidos'] = kgProducidos;
      if (composicionPolen != null) {
        data['composicion_polen'] = composicionPolen;
      }
      if (ordenMiel != null) data['orden_miel'] = ordenMiel;

      final response = await _apiService.dio.put(
        '/api/lote/$loteId',
        data: data,
      );
      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        debugPrint('[LOTES] Lote actualizado exitosamente');
        return Lote.fromJson(responseData['lote']);
      }

      throw Exception(responseData['error'] ?? 'Error actualizando lote');
    } catch (e) {
      debugPrint('[LOTES] Error actualizando lote: $e');
      rethrow;
    }
  }

  /// Elimina un lote (requiere autenticación).
  Future<bool> deleteLote(String loteId) async {
    try {
      debugPrint('[LOTES] Eliminando lote: $loteId');

      final response = await _apiService.dio.delete('/api/lote/$loteId');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        debugPrint('[LOTES] Lote eliminado exitosamente');
        return true;
      }

      throw Exception(data['error'] ?? 'Error eliminando lote');
    } catch (e) {
      debugPrint('[LOTES] Error eliminando lote: $e');
      rethrow;
    }
  }

  /// Obtiene la URL del QR de un lote.
  ///
  /// El endpoint requiere autenticación y el usuario debe ser dueño del lote.
  Future<String> getLoteQrUrl(String loteId) async {
    try {
      debugPrint('[LOTES] Obteniendo QR de lote: $loteId');

      // El endpoint GET /api/lote/<lote_id>/qr devuelve la imagen directamente
      // Retornamos la URL completa para usar en Image.network
      return '${_apiService.dio.options.baseUrl}/lote/$loteId/qr';
    } catch (e) {
      debugPrint('[LOTES] Error obteniendo QR URL: $e');
      rethrow;
    }
  }

  /// Calcula estadísticas de lotes de un usuario.
  Future<LoteStats> getStats(String userId) async {
    try {
      final lotes = await getLotesUsuario(userId);

      if (lotes.isEmpty) {
        return LoteStats(
          totalLotes: 0,
          totalKg: 0,
          especiesPredominantes: {},
          promedioKgPorLote: 0,
        );
      }

      final totalKg = lotes.fold<double>(
        0,
        (sum, lote) => sum + (lote.kgProducidos ?? 0),
      );

      final especiesPredominantes = <String, int>{};
      for (var lote in lotes) {
        final especie = lote.getEspeciePredominante();
        if (especie != null) {
          especiesPredominantes[especie] =
              (especiesPredominantes[especie] ?? 0) + 1;
        }
      }

      return LoteStats(
        totalLotes: lotes.length,
        totalKg: totalKg,
        especiesPredominantes: especiesPredominantes,
        promedioKgPorLote: totalKg / lotes.length,
      );
    } catch (e) {
      debugPrint('[LOTES] Error calculando stats: $e');
      rethrow;
    }
  }
}

/// Estadísticas agregadas de lotes de un usuario.
class LoteStats {
  final int totalLotes;
  final double totalKg;
  final Map<String, int> especiesPredominantes;
  final double promedioKgPorLote;

  LoteStats({
    required this.totalLotes,
    required this.totalKg,
    required this.especiesPredominantes,
    required this.promedioKgPorLote,
  });
}
