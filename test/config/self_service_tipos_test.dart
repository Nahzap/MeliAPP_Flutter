import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/config/self_service_tipos.dart';

void main() {
  test('los tipos self-service coinciden con Cloud', () {
    expect(kSelfServiceTipos.map((t) => t.value).toSet(), {
      'apicultor',
      'prestador_servicios',
      'proveedor',
      'regular',
    });
  });
}
