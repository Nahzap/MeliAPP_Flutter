/// Modelo para la respuesta del endpoint de generación de QR
class QRResponse {
  final bool success;
  final String? qrCode;
  final String? userId;
  final String? uuidSegment;
  final String? error;

  QRResponse({
    required this.success,
    this.qrCode,
    this.userId,
    this.uuidSegment,
    this.error,
  });

  factory QRResponse.fromJson(Map<String, dynamic> json) {
    return QRResponse(
      success: json['success'] as bool,
      qrCode: json['qr_code'] as String?,
      userId: json['user_id'] as String?,
      uuidSegment: json['uuid_segment'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'qr_code': qrCode,
      'user_id': userId,
      'uuid_segment': uuidSegment,
      'error': error,
    };
  }

  @override
  String toString() {
    return 'QRResponse{success: $success, userId: $userId, uuidSegment: $uuidSegment}';
  }
}
