import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/models/lote_model.dart';

Lote buildLote({
  String id = 'lote-1',
  String authUserId = 'user-1',
  int ordenMiel = 1,
  String nombreMiel = 'Miel de Maitén',
  String temporada = '2024 - 2025',
  double? kgProducidos = 120,
  String? composicion = 'Maitén:40, Notro:30, Michay:20, Avellano Chileno:10',
  DateTime? fechaRegistro,
  DateTime? fechaActualizacion,
}) {
  return Lote(
    id: id,
    authUserId: authUserId,
    ordenMiel: ordenMiel,
    nombreMiel: nombreMiel,
    temporada: temporada,
    kgProducidos: kgProducidos,
    composicion: composicion,
    fechaRegistro: fechaRegistro,
    fechaActualizacion: fechaActualizacion,
  );
}

void main() {
  group('Lote.fromJson', () {
    test('parsea un payload completo del backend', () {
      final lote = Lote.fromJson({
        'id': 'abc-123',
        'auth_user_id': 'user-uuid',
        'orden_miel': 3,
        'nombre_miel': 'Miel de Ulmo',
        'temporada': '2023 - 2024',
        'kg_producidos': 85.5,
        'composicion': 'Ulmo:70, Tineo:30',
        'fecha_registro': '2024-01-15T10:00:00.000Z',
        'fecha_actualizacion': '2024-02-01T12:00:00.000Z',
      });

      expect(lote.id, 'abc-123');
      expect(lote.authUserId, 'user-uuid');
      expect(lote.ordenMiel, 3);
      expect(lote.nombreMiel, 'Miel de Ulmo');
      expect(lote.temporada, '2023 - 2024');
      expect(lote.kgProducidos, 85.5);
      expect(lote.composicion, 'Ulmo:70, Tineo:30');
      expect(lote.fechaRegistro, DateTime.parse('2024-01-15T10:00:00.000Z'));
      expect(
        lote.fechaActualizacion,
        DateTime.parse('2024-02-01T12:00:00.000Z'),
      );
    });

    test('acepta kg_producidos como string numérico', () {
      final lote = Lote.fromJson({
        'id': '1',
        'auth_user_id': 'u',
        'orden_miel': 1,
        'nombre_miel': 'Miel',
        'temporada': '2024',
        'kg_producidos': '42.75',
      });

      expect(lote.kgProducidos, 42.75);
    });

    test('deja kg_producidos nulo si no viene en el JSON', () {
      final lote = Lote.fromJson({
        'id': '1',
        'auth_user_id': 'u',
        'orden_miel': 1,
        'nombre_miel': 'Miel',
        'temporada': '2024',
      });

      expect(lote.kgProducidos, isNull);
      expect(lote.composicion, isNull);
      expect(lote.fechaRegistro, isNull);
    });
  });

  group('Lote.parseComposicion', () {
    test('parsea CSV de especies y porcentajes', () {
      final lote = buildLote();

      expect(lote.parseComposicion(), {
        'Maitén': 40.0,
        'Notro': 30.0,
        'Michay': 20.0,
        'Avellano Chileno': 10.0,
      });
    });

    test('retorna mapa vacío si composición es nula o vacía', () {
      expect(buildLote(composicion: null).parseComposicion(), isEmpty);
      expect(buildLote(composicion: '').parseComposicion(), isEmpty);
    });

    test('ignora items malformados o especie vacía', () {
      final lote = buildLote(composicion: 'Maitén:40, Notro, Michay:abc, :20');
      expect(lote.parseComposicion(), {'Maitén': 40.0});
    });

    test('parsea CSV certificado con signo de porcentaje', () {
      final lote = buildLote(composicion: 'Poleo: 65.6%, Arrayan: 34.4%');
      expect(lote.parseComposicion(), {'Poleo': 65.6, 'Arrayan': 34.4});
    });

    test('usa polen de datos_certificado si está presente', () {
      final lote = Lote.fromJson({
        'id': 'c1',
        'auth_user_id': 'u',
        'orden_miel': 4,
        'nombre_miel': 'test04',
        'temporada': 'PRIMAVERA',
        'composicion': 'Poleo: 65.6%, Arrayan: 34.4%',
        'datos_certificado': {
          'analisis_melisopalinologico': {
            'metodo': 'Microscopía',
            'polenes_identificados': [
              {'nombre_comun': 'Poleo', 'proporcion_pct': 65.6},
              {'nombre_comun': 'Arrayan', 'proporcion_pct': 34.4},
            ],
          },
        },
      });
      expect(lote.hasCertificado, isTrue);
      expect(lote.puedeMostrarCertificado, isTrue);
      expect(lote.parseComposicion()['Poleo'], 65.6);
      expect(lote.metodoAnalisis, 'Microscopía');
    });

    test('detecta certificado por CSV con porcentaje', () {
      final lote = buildLote(composicion: 'Poleo: 65.6%, Arrayan: 34.4%');
      expect(lote.puedeMostrarCertificado, isTrue);
      expect(lote.hasCertificado, isFalse);
    });

    test('detecta estado de certificación y no lo parsea como CSV', () {
      final lote = buildLote(composicion: 'Pendiente de Análisis');
      expect(lote.isEstadoCertificacion, isTrue);
      expect(lote.parseComposicion(), isEmpty);
    });
  });

  group('Lote composición helpers', () {
    test('suma el total de composición', () {
      expect(buildLote().getTotalComposicion(), 100.0);
    });

    test('considera válida una composición cerca de 100%', () {
      expect(buildLote().isComposicionValida(), isTrue);
      expect(
        buildLote(composicion: 'Maitén:50, Notro:50').isComposicionValida(),
        isTrue,
      );
      expect(
        buildLote(composicion: 'Maitén:80').isComposicionValida(),
        isFalse,
      );
    });

    test('ordena especies por porcentaje descendente', () {
      final especies = buildLote().getEspeciesOrdenadas();

      expect(especies.map((e) => e.key).toList(), [
        'Maitén',
        'Notro',
        'Michay',
        'Avellano Chileno',
      ]);
    });

    test('retorna la especie predominante', () {
      expect(buildLote().getEspeciePredominante(), 'Maitén');
      expect(buildLote(composicion: null).getEspeciePredominante(), isNull);
    });
  });

  group('Lote temporadas y copia', () {
    test('separa temporadas por " - "', () {
      expect(buildLote().getTemporadas(), ['2024', '2025']);
    });

    test('igualdad se basa en el id', () {
      final a = buildLote(id: 'same', nombreMiel: 'A');
      final b = buildLote(id: 'same', nombreMiel: 'B');
      final c = buildLote(id: 'other');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect({a, b}.length, 1);
    });

    test('copyWith reemplaza solo los campos indicados', () {
      final original = buildLote();
      final copy = original.copyWith(
        nombreMiel: 'Miel de Ulmo',
        kgProducidos: 10,
      );

      expect(copy.id, original.id);
      expect(copy.nombreMiel, 'Miel de Ulmo');
      expect(copy.kgProducidos, 10);
      expect(copy.temporada, original.temporada);
    });

    test('toJson round-trip conserva campos principales', () {
      final original = buildLote(fechaRegistro: DateTime.utc(2024, 1, 15));
      final restored = Lote.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.nombreMiel, original.nombreMiel);
      expect(restored.kgProducidos, original.kgProducidos);
      expect(restored.composicion, original.composicion);
      expect(restored.fechaRegistro, original.fechaRegistro);
    });
  });
}
