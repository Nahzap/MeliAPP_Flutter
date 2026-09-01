import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/models/lote_model.dart';
import 'package:meliapp_flutter/services/taxa_service.dart';

void main() {
  final catalog = TaxaCatalog(const [
    TaxonRecord(
      nombreComun: 'Poleo',
      nombreCientifico: 'Mentha pulegium',
      clase: 'Hierba',
    ),
    TaxonRecord(
      nombreComun: 'Arrayan',
      nombreCientifico: 'Luma apiculata',
      clase: 'Arbol',
    ),
    TaxonRecord(
      nombreComun: 'Maiten',
      nombreCientifico: 'Maytenus boaria',
      clase: 'Arbol',
    ),
  ]);

  test('resuelve CSV común a latín (común)', () {
    final name = catalog.resolve('Maitén');
    expect(name.displayText, 'Maytenus boaria (Maitén)');
  });

  test('usa taxon del certificado si está presente', () {
    final lote = Lote.fromJson({
      'id': 'c1',
      'auth_user_id': 'u',
      'orden_miel': 4,
      'nombre_miel': 'test04',
      'temporada': 'PRIMAVERA',
      'datos_certificado': {
        'analisis_melisopalinologico': {
          'polenes_identificados': [
            {
              'taxon': 'Mentha pulegium',
              'nombre_comun': 'Poleo',
              'proporcion_pct': 65.6,
            },
          ],
        },
      },
    });

    final name = catalog.resolve('Poleo', lote: lote);
    expect(name.scientific, 'Mentha pulegium');
    expect(name.common, 'Poleo');
    expect(
      catalog
          .labeledComposition(lote.parseComposicion(), lote: lote)
          .keys
          .first,
      'Mentha pulegium (Poleo)',
    );
  });
}
