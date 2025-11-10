import '../models/qr_response.dart';
import 'api_service.dart';

/// Servicio para manejo de códigos QR
/// Genera QR a través de la API REST y procesa QR escaneados
class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  final ApiService _apiService = ApiService();

  /// Genera un código QR para un usuario específico
  /// [uuidSegment] debe ser el segmento UUID de 8 caracteres del usuario
  Future<QRResponse?> generateUserQR(String uuidSegment) async {
    try {
      if (uuidSegment.length != 8) {
        print('[QR] UUID segment debe tener 8 caracteres: $uuidSegment');
        return QRResponse(
          success: false,
          error: 'UUID segment debe tener 8 caracteres',
        );
      }

      final responseData = await _apiService.getUserQR(uuidSegment);
      final qrResponse = QRResponse.fromJson(responseData);
      
      if (qrResponse.success) {
        print('[QR] QR generado exitosamente para: $uuidSegment');
      } else {
        print('[QR] Error generando QR: ${qrResponse.error}');
      }
      
      return qrResponse;
    } catch (e) {
      print('[QR] Error en generateUserQR: $e');
      return QRResponse(
        success: false,
        error: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  /// Extrae el UUID segment de una URL de QR escaneada
  /// Ejemplo: https://meli-app-v3.vercel.app/api/usuario/550e8400 -> 550e8400
  String? extractUuidFromQR(String qrData) {
    try {
      final uri = Uri.tryParse(qrData);
      
      if (uri == null) {
        print('[QR] QR data no es una URL válida: $qrData');
        return null;
      }

      // Verificar que sea de nuestro dominio
      if (!uri.host.contains('meli-app-v3.vercel.app')) {
        print('[QR] QR no es de nuestro dominio: ${uri.host}');
        return null;
      }

      // Extraer UUID segment de la URL
      // Formato esperado: /api/usuario/{uuid_segment}
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 3 && 
          pathSegments[0] == 'api' && 
          pathSegments[1] == 'usuario') {
        
        final uuidSegment = pathSegments[2];
        
        if (uuidSegment.length == 8) {
          print('[QR] UUID segment extraído: $uuidSegment');
          return uuidSegment;
        } else {
          print('[QR] UUID segment no tiene 8 caracteres: $uuidSegment');
        }
      } else {
        print('[QR] Formato de URL no válido: ${uri.path}');
      }
      
      return null;
    } catch (e) {
      print('[QR] Error extrayendo UUID: $e');
      return null;
    }
  }

  /// Valida si un string es un UUID segment válido (8 caracteres hexadecimales)
  bool isValidUuidSegment(String segment) {
    if (segment.length != 8) return false;
    
    // Verificar que solo contenga caracteres hexadecimales
    final hexPattern = RegExp(r'^[0-9a-fA-F]+$');
    return hexPattern.hasMatch(segment);
  }

  /// Construye la URL completa para un UUID segment
  String buildUserUrl(String uuidSegment) {
    return 'https://meli-app-v3.vercel.app/api/usuario/$uuidSegment';
  }

  /// Obtiene información de usuario a partir de un UUID segment escaneado
  /// Esto podría expandirse para hacer una llamada a la API y obtener datos del usuario
  Future<Map<String, dynamic>?> getUserInfoFromQR(String qrData) async {
    final uuidSegment = extractUuidFromQR(qrData);
    
    if (uuidSegment == null) {
      return null;
    }

    try {
      // Aquí podrías agregar una llamada a la API para obtener información del usuario
      // Por ejemplo: GET /api/usuario/{uuid_segment}
      // Por ahora solo retornamos el UUID segment
      
      return {
        'uuid_segment': uuidSegment,
        'profile_url': buildUserUrl(uuidSegment),
        'scanned_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('[QR] Error obteniendo info de usuario: $e');
      return null;
    }
  }
}
