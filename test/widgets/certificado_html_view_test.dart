import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/widgets/certificado_html_view.dart';

void main() {
  test('oculta el control flotante de Cloud al incrustar el IEEE', () {
    const raw = '''
<!DOCTYPE html><html><head><title>Certificado de Origen - IEEE Style Preview</title>
</head><body><div class="controls"><button>print</button></div></body></html>
''';
    final prepared = prepareCertificadoHtml(raw);
    expect(prepared, contains('.controls{display:none'));
    expect(prepared, contains('IEEE Style Preview'));
  });
}
