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
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
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
      // PRIMERO: Verificar si es una URL
      if (_isValidUrl(qrData)) {
        print('[QR] URL detectada: $qrData');
        await _openUrlInBrowser(qrData);
        return;
      }

      // SEGUNDO: Si no es URL, intentar procesar como QR del sistema MeliAPP
      print('[QR] No es URL, procesando como QR de MeliAPP...');
      final userInfo = await _qrService.getUserInfoFromQR(qrData);

      if (userInfo != null && mounted) {
        // Mostrar resultado exitoso
        _showResultDialog(
          title: '✅ QR Válido',
          content:
              '''
UUID Segment: ${userInfo['uuid_segment']}
URL del Perfil: ${userInfo['profile_url']}
Escaneado: ${userInfo['scanned_at']}
          ''',
          isSuccess: true,
        );
      } else if (mounted) {
        // QR no válido o no es de nuestro sistema
        _showResultDialog(
          title: '❌ QR No Válido',
          content:
              '''
El código QR escaneado no pertenece al sistema MeliAPP.

Datos escaneados:
$qrData
          ''',
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
      print('[QR] Intentando abrir URL en navegador: $url');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Abre en navegador externo
        );
        
        if (mounted) {
          // Mostrar confirmación y cerrar scanner
          _showResultDialog(
            title: '🌐 URL Abierta',
            content: 'La URL ha sido abierta en tu navegador:\n\n$url',
            isSuccess: true,
            closeAfterConfirm: true,
          );
        }
      } else {
        throw 'No se puede abrir la URL: $url';
      }
    } catch (e) {
      print('[QR] Error abriendo URL: $e');
      if (mounted) {
        _showResultDialog(
          title: '❌ Error',
          content: 'No se pudo abrir la URL en el navegador:\n\n$e',
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
