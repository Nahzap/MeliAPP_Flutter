import 'package:flutter/foundation.dart';
import '../models/qr_response.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// Servicio para códigos QR de MeliAPP Cloud (solo lectura / resolución de perfil).
class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  final ApiService _apiService = ApiService();

  Future<QRResponse?> generateUserQR(String uuidSegment) async {
    try {
      if (uuidSegment.length != 8) {
        debugPrint('[QR] UUID segment debe tener 8 caracteres: $uuidSegment');
        return QRResponse(
          success: false,
          error: 'UUID segment debe tener 8 caracteres',
        );
      }

      final responseData = await _apiService.getUserQR(uuidSegment);
      return QRResponse.fromJson(responseData);
    } catch (e) {
      debugPrint('[QR] Error en generateUserQR: $e');
      return QRResponse(
        success: false,
        error: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  bool isMeliappHost(String? host) {
    if (host == null || host.isEmpty) return false;
    final normalized = host.toLowerCase();
    return ApiConfig.qrHosts.any(
      (allowed) => normalized == allowed || normalized.endsWith('.$allowed'),
    );
  }

  /// Extrae un identificador de perfil desde una URL de Cloud.
  ///
  /// Soporta:
  /// - /api/usuario/{8chars}
  /// - /profile/{uuid}
  /// - /usuario/{8chars}
  QrProfileRef? parseProfileRef(String qrData) {
    final uri = Uri.tryParse(qrData.trim());
    if (uri == null || uri.host.isEmpty) return null;
    if (!isMeliappHost(uri.host)) {
      debugPrint('[QR] Host no reconocido: ${uri.host}');
      return null;
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 3 &&
        segments[0] == 'api' &&
        segments[1] == 'usuario' &&
        segments[2].length == 8) {
      return QrProfileRef(uuidSegment: segments[2]);
    }
    if (segments.length >= 2 &&
        segments[0] == 'usuario' &&
        segments[1].length == 8) {
      return QrProfileRef(uuidSegment: segments[1]);
    }
    if (segments.length >= 2 && segments[0] == 'profile') {
      final id = segments[1];
      if (id.length == 8) return QrProfileRef(uuidSegment: id);
      if (id.length >= 8) return QrProfileRef(userId: id);
    }
    return null;
  }

  /// Extrae un segmento de 8 caracteres cuando existe en la URL.
  String? extractUuidFromQR(String qrData) {
    final ref = parseProfileRef(qrData);
    if (ref == null) return null;
    if (ref.uuidSegment != null) return ref.uuidSegment;
    final id = ref.userId?.replaceAll('-', '');
    if (id != null && id.length >= 8) return id.substring(0, 8);
    return null;
  }

  Future<String?> resolveUserId(String qrData) async {
    final ref = parseProfileRef(qrData);
    if (ref == null) return null;
    return ref.userId ?? ref.uuidSegment;
  }

  bool isValidUuidSegment(String segment) {
    if (segment.length != 8) return false;
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(segment);
  }

  String buildUserUrl(String uuidSegment) {
    return '${ApiConfig.baseUrl}/api/usuario/$uuidSegment';
  }

  String buildProfileUrl(String userId) {
    return '${ApiConfig.baseUrl}/profile/$userId';
  }

  Future<Map<String, dynamic>?> getUserInfoFromQR(String qrData) async {
    final userId = await resolveUserId(qrData);
    if (userId == null) return null;
    final segment = userId.replaceAll('-', '');
    final uuidSegment = segment.length >= 8 ? segment.substring(0, 8) : userId;
    return {
      'user_id': userId,
      'uuid_segment': uuidSegment,
      'profile_url': buildProfileUrl(userId),
      'scanned_at': DateTime.now().toIso8601String(),
    };
  }
}

class QrProfileRef {
  final String? userId;
  final String? uuidSegment;

  const QrProfileRef({this.userId, this.uuidSegment});
}
