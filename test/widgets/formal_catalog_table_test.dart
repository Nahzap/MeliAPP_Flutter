import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/services/botanical_service.dart';
import 'package:meliapp_flutter/widgets/formal_catalog_table.dart';
import 'package:meliapp_flutter/widgets/species_catalog_table.dart';

void main() {
  test('catalogRoman numera tablas en romano', () {
    expect(catalogRoman(1), 'I');
    expect(catalogRoman(2), 'II');
    expect(catalogRoman(4), 'IV');
    expect(catalogRoman(12), 'XII');
    expect(catalogCaption(1, 'Arbustos'), 'Tabla I. Arbustos');
  });

  testWidgets('tabla de clase botánica enumera especies en grilla', (
    tester,
  ) async {
    const group = BotanicalClassGroup(
      clase: 'Arbustos',
      titulo: 'Arbustos',
      descripcion: 'Plantas leñosas de tamaño mediano.',
      cantidad: 2,
      especies: [
        BotanicalSpecies(
          nombreComun: 'Michay',
          nombreCientifico: 'Berberis darwinii',
        ),
        BotanicalSpecies(
          nombreComun: 'Paramela',
          nombreCientifico: 'Adesmia longipes',
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BotanicalClassTable(tableIndex: 1, group: group),
          ),
        ),
      ),
    );

    expect(find.text('Tabla I. Arbustos (n = 2)'), findsOneWidget);
    expect(find.text('Nº'), findsOneWidget);
    expect(find.text('NOMBRE CIENTÍFICO'), findsOneWidget);
    expect(find.text('NOMBRE COMÚN'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Berberis darwinii'), findsOneWidget);
    expect(find.text('Michay'), findsOneWidget);
    expect(find.text('Adesmia longipes'), findsOneWidget);
    expect(find.text('Paramela'), findsOneWidget);
  });

  testWidgets('en el stack solo una tabla de clase queda ampliada', (
    tester,
  ) async {
    const groups = [
      BotanicalClassGroup(
        clase: 'Arbustos',
        titulo: 'Arbustos',
        descripcion: 'Leñosas medianas.',
        cantidad: 1,
        especies: [
          BotanicalSpecies(
            nombreComun: 'Michay',
            nombreCientifico: 'Berberis darwinii',
          ),
        ],
      ),
      BotanicalClassGroup(
        clase: 'Arboles',
        titulo: 'Árboles',
        descripcion: 'Leñosas grandes.',
        cantidad: 1,
        especies: [
          BotanicalSpecies(
            nombreComun: 'Lenga',
            nombreCientifico: 'Nothofagus pumilio',
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CatalogTableStack(firstTableIndex: 2, groups: groups),
          ),
        ),
      ),
    );

    expect(find.text('Ampliar'), findsOneWidget);
    expect(find.text('Ocultar'), findsOneWidget);
    expect(find.text('Berberis darwinii'), findsOneWidget);
    expect(find.text('Nothofagus pumilio'), findsNothing);

    await tester.tap(find.text('Ampliar'));
    await tester.pumpAndSettle();

    expect(find.text('Nothofagus pumilio'), findsOneWidget);
    expect(find.text('Berberis darwinii'), findsNothing);
  });
}
