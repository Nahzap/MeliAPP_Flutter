import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/models/species_name.dart';

void main() {
  group('SpeciesName', () {
    test('latín primero y común entre paréntesis', () {
      final name = SpeciesName.fromParts('Mentha pulegium', 'Poleo');
      expect(name.displayText, 'Mentha pulegium (Poleo)');
      expect(name.hasDistinctCommon, isTrue);
    });

    test('omite el paréntesis si común y científico coinciden', () {
      final name = SpeciesName.fromParts('Ulmo', 'Ulmo');
      expect(name.displayText, 'Ulmo');
      expect(name.hasDistinctCommon, isFalse);
    });

    test('parsea el formato Cloud', () {
      final name = SpeciesName.parse('Maytenus boaria (Maitén)');
      expect(name.scientific, 'Maytenus boaria');
      expect(name.common, 'Maitén');
    });

    test('normaliza acentos para comparar Arrayán y Arrayan', () {
      expect(
        SpeciesName.normalize('Arrayán'),
        SpeciesName.normalize('Arrayan'),
      );
      expect(SpeciesName.normalize('Maitén'), SpeciesName.normalize('Maiten'));
    });
  });
}
