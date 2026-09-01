import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/qr_service.dart';

/// Pantalla para escanear códigos QR
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  String? scannedData;
  bool isProcessing = false;
  final QRService _qrService = QRService();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null && !isProcessing) {
                    _processQRCode(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isProcessing)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Procesando QR...'),
                      ],
                    )
                  else if (scannedData != null)
                    Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'QR Escaneado',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scannedData!,
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: Colors.grey[600],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Apunta la cámara al código QR',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'El escaneo se realizará automáticamente',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processQRCode(String qrData) async {
    setState(() {
      isProcessing = true;
      scannedData = qrData;
    });

    // Pausar la cámara mientras procesamos
    await controller.stop();

    try {
      final userId = await _qrService.resolveUserId(qrData);
      if (userId != null && mounted) {
        Navigator.of(context).pop(userId);
        return;
      }

      if (_isValidUrl(qrData)) {
        debugPrint('[QR] URL detectada: $qrData');
        await _openUrlInBrowser(qrData);
        return;
      }

      if (mounted) {
        _showResultDialog(
          title: 'QR no reconocido',
          content:
              'El código no corresponde a un perfil de MeliAPP Cloud.\n\n$qrData',
          isSuccess: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog(
          title: '❌ Error',
          content: 'Error procesando QR: $e',
          isSuccess: false,
        );
      }
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  /// Verifica si el texto es una URL válida
  bool _isValidUrl(String text) {
    try {
      final uri = Uri.parse(text);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Abre una URL en el navegador por defecto
  Future<void> _openUrlInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      debugPrint('[QR] Intentando abrir URL en navegador: $url');

      // Intentar lanzar la URL directamente
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Abre en navegador externo
      );

      if (launched) {
        debugPrint('[QR] ✅ URL abierta exitosamente en navegador');
        if (mounted) {
          // Cerrar el scanner directamente sin mostrar diálogo
          // El usuario ya está viendo el navegador
          Navigator.of(context).pop();
        }
      } else {
        throw 'No se pudo lanzar la URL';
      }
    } catch (e) {
      debugPrint('[QR] ❌ Error abriendo URL: $e');
      if (mounted) {
        _showResultDialog(
          title: '❌ Error',
          content:
              'No se pudo abrir la URL en el navegador:\n\nNo se puede abrir la URL: $url',
          isSuccess: false,
        );
      }
    }
  }

  void _showResultDialog({
    required String title,
    required String content,
    required bool isSuccess,
    bool closeAfterConfirm = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          if (!closeAfterConfirm)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetScanner();
              },
              child: const Text('Escanear Otro'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar dialog
              if (closeAfterConfirm) {
                Navigator.of(context).pop(); // Cerrar scanner
              }
            },
            child: Text(closeAfterConfirm ? 'OK' : 'Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetScanner() async {
    setState(() {
      scannedData = null;
      isProcessing = false;
    });
    await controller.start();
  }
}
