import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/models/lote_model.dart';
import 'package:meliapp_flutter/models/user_model.dart';
import 'package:meliapp_flutter/models/ubicacion_model.dart';
import 'package:meliapp_flutter/services/certificado_builder.dart';
import 'package:meliapp_flutter/services/taxa_service.dart';

void main() {
  final taxa = TaxaCatalog(const [
    TaxonRecord(nombreComun: 'Poleo', nombreCientifico: 'Mentha pulegium'),
    TaxonRecord(nombreComun: 'Arrayan', nombreCientifico: 'Luma apiculata'),
  ]);

  Lote certifiedLote() {
    return Lote.fromJson({
      'id': 'abcd1234-lote',
      'auth_user_id': 'user-1',
      'orden_miel': 4,
      'nombre_miel': 'test04',
      'temporada': 'PRIMAVERA',
      'anio_cosecha': 2025,
      'kg_producidos': 12.5,
      'composicion': 'Poleo: 65.6%, Arrayan: 34.4%',
      'revisor_nombre': 'Rod jofre cerda',
      'fecha_actualizacion': '2026-08-01T12:00:00.000Z',
      'datos_certificado': {
        'datos_muestra': {
          'peso_g': 250,
          'metodo_extraccion': 'Centrifugado',
          'fecha_recepcion': '2026-07-20',
        },
        'analisis_melisopalinologico': {
          'metodo': 'Microscopía óptica automatizada por IA',
          'total_granos_contados': 500,
          'polenes_identificados': [
            {
              'taxon': 'Mentha pulegium',
              'nombre_comun': 'Poleo',
              'proporcion_pct': 65.6,
              'categoria': 'Polen Dominante',
            },
            {
              'taxon': 'Luma apiculata',
              'nombre_comun': 'Arrayán',
              'proporcion_pct': 34.4,
              'categoria': 'Polen Secundario',
            },
          ],
        },
      },
    });
  }

  test('arma el JSON IEEE como Cloud para un lote monofloral', () {
    final user = User(
      id: 'user-1',
      username: 'erika',
      nombreCompleto: 'Erika Poblete',
      email: 'erika.poblete@apicultor.cl',
      telefono: '+56911111111',
      direccion: 'Lonquimay',
      comuna: 'Lonquimay',
      region: 'Araucanía',
      ubicaciones: const [
        Ubicacion(
          id: 'u1',
          nombre: 'Apiario Principal',
          latitud: -38.55,
          longitud: -71.13,
        ),
      ],
    );

    final data = CertificadoBuilder.build(
      lote: certifiedLote(),
      apicultor: user,
      taxa: taxa,
      now: DateTime(2026, 8, 19),
    );

    expect(
      data.certificado['tipo_documento'],
      'Certificado de Origen Botánico',
    );
    expect(data.certificado['id'], contains('CERT-ABCD1234'));
    expect(data.certificado['normativa_aplicable'], contains('NCh2981'));
    expect(data.laboratorio['analista_responsable'], 'Rod jofre cerda');
    expect(data.apicultor['nombre'], 'Erika Poblete');
    expect(data.lote['codigo_lote'], 'LOTE-4');
    expect(data.lote['fecha_cosecha'], 'Temporada PRIMAVERA 2025');
    expect(data.clasificacion['tipo'], 'Miel Monofloral');
    expect(data.clasificacion['umbral_aplicado_pct'], '65.6%');
    expect(data.resultado['denominacion'], 'Miel de Abeja Monofloral de Poleo');
    expect(data.polenes.first['taxon'], 'Mentha pulegium');
    expect(data.muestra['id_muestra'], 'M-ABCD12');
    expect(
      data.laboratorio['fecha_aprobacion'],
      '2026-08-01T12:00:00.000Z a las XXXX hrs',
    );
  });
}
