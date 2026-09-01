import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

/// HTML de Cloud sin el botón flotante (la app pone Descargar).
String prepareCertificadoHtml(String html) {
  const hide = '<style>.controls{display:none !important}</style>';
  if (html.contains('</head>')) {
    return html.replaceFirst('</head>', '$hide</head>');
  }
  return '$hide$html';
}

/// Genera el PDF como Cloud (`window.print`) y lo comparte/guarda.
Future<bool> saveCertificadoDocument(String html) async {
  final prepared = prepareCertificadoHtml(html);
  try {
    final info = await Printing.info();
    if (info.canConvertHtml) {
      // Mismo HTML IEEE de Cloud, renderizado a PDF en el dispositivo.
      // ignore: deprecated_member_use
      final bytes = await Printing.convertHtml(
        html: prepared,
        format: PdfPageFormat.a4,
      );
      if (info.canShare) {
        return Printing.sharePdf(
          bytes: bytes,
          filename: 'Certificado-de-Origen.pdf',
        );
      }
      if (info.canPrint) {
        return Printing.layoutPdf(
          name: 'Certificado de Origen',
          onLayout: (_) async => bytes,
        );
      }
    }
  } catch (e) {
    debugPrint('[CERT] PDF: $e');
  }
  return _saveHtmlFallback(prepared);
}

Future<bool> _saveHtmlFallback(String html) async {
  if (kIsWeb || !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    return false;
  }
  final location = await getSaveLocation(
    suggestedName: 'Certificado de Origen.pdf.html',
    acceptedTypeGroups: const [
      XTypeGroup(label: 'HTML', extensions: ['html']),
    ],
  );
  if (location == null) return false;
  await File(location.path).writeAsBytes(utf8.encode(html), flush: true);
  return true;
}

/// Muestra el HTML IEEE de Cloud dentro del visor.
class CertificadoHtmlView extends StatelessWidget {
  final String html;

  const CertificadoHtmlView({super.key, required this.html});

  @override
  Widget build(BuildContext context) {
    final prepared = prepareCertificadoHtml(html);
    if (!kIsWeb && Platform.isWindows) {
      return _WindowsHtmlView(html: prepared);
    }
    return _MobileHtmlView(html: prepared);
  }
}

class _WindowsHtmlView extends StatefulWidget {
  final String html;

  const _WindowsHtmlView({required this.html});

  @override
  State<_WindowsHtmlView> createState() => _WindowsHtmlViewState();
}

class _WindowsHtmlViewState extends State<_WindowsHtmlView> {
  final _controller = WebviewController();
  Object? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(const Color(0xFF525659));
      await _controller.loadStringContent(widget.html);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(
          'No se pudo mostrar el certificado en la app.\n$_error',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Webview(_controller);
  }
}

class _MobileHtmlView extends StatefulWidget {
  final String html;

  const _MobileHtmlView({required this.html});

  @override
  State<_MobileHtmlView> createState() => _MobileHtmlViewState();
}

class _MobileHtmlViewState extends State<_MobileHtmlView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF525659))
      ..loadHtmlString(widget.html);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
