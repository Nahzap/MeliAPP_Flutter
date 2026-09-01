import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/models/search_models.dart';

/// Respuestas capturadas de la API real de MeliAPP Cloud el 1 sep 2026.
/// Si Cloud cambia el contrato, estos tests deben fallar.
const String _suggestUlmo = '''
{"ok": true, "valid": true, "query_type": "keyword", "reason": "",
 "keywords": [{"term": "Ulmo", "normalized": "ulmo", "category": "especie", "label": "Especie"}],
 "suggestions": [
   {"term": "Ulmo", "normalized": "ulmo", "category": "especie", "label": "Ulmo"},
   {"term": "miel de Ulmo", "normalized": "miel de ulmo", "category": "tipo_miel", "label": "miel de Ulmo"},
   {"term": "polen de Ulmo", "normalized": "polen de ulmo", "category": "polen", "label": "polen de Ulmo"}]}
''';

const String _suggestFrase = '''
{"ok": false, "valid": false, "query_type": "sentence",
 "reason": "El buscador solo acepta palabras clave (apicultor, miel, polen, especie, lugar). No uses frases ni preguntas.",
 "keywords": [],
 "suggestions": [
   {"term": "miel de Ulmo", "normalized": "miel de ulmo", "category": "tipo_miel", "label": "Tipo de miel"},
   {"term": "Valdivia", "normalized": "valdivia", "category": "lugar", "label": "Lugar"}]}
''';

const String _keywordsUlmo = '''
{"ok": true, "query_type": "keyword", "reason": "",
 "keywords": [{"term": "Ulmo", "normalized": "ulmo", "category": "especie", "label": "Especie"}],
 "suggestions": [], "count": 2, "limit": 20,
 "results": [
  {"auth_user_id": "6020cdaf-4853-4a18-b46b-50d4ee53a4c2", "nombre": "Javier Cesar",
   "nombre_empresa": "Apis sa", "username": "Javier Cesar", "role": "regular",
   "tipo_usuario": "regular", "comuna": "Puerto Montt", "region": "Los Lagos", "score": 6,
   "matches": [
     {"category": "tipo_miel", "term": "ulmo", "evidence": "ulmo puerto montt (PRIMAVERA - VERANO)",
      "confidence": "direct", "label": "Tipo de miel"},
     {"category": "zona", "term": "ulmo", "evidence": "Flora de la zona en Puerto Montt",
      "confidence": "zone_flora", "label": "Flora de zona"}]},
  {"auth_user_id": "006349d6-6620-4ffb-b5e9-d1d006524095", "nombre": "Paula Gonzalez",
   "nombre_empresa": "", "username": "Paula Gonzalez", "role": "regular",
   "tipo_usuario": "regular", "comuna": "", "region": "", "score": 5,
   "matches": [{"category": "tipo_miel", "term": "ulmo", "evidence": "Ulmo (PRIMAVERA)",
                "confidence": "direct", "label": "Tipo de miel"}]}]}
''';

Map<String, dynamic> _decode(String raw) =>
    jsonDecode(raw) as Map<String, dynamic>;

void main() {
  group('SuggestResult', () {
    test('lee el veredicto y las palabras clave de una consulta válida', () {
      final result = SuggestResult.fromJson(_decode(_suggestUlmo));

      expect(result.valid, isTrue);
      expect(result.isSentence, isFalse);
      expect(result.keywords, hasLength(1));
      expect(result.keywords.first.term, 'Ulmo');
      expect(result.keywords.first.category, KeywordCategory.especie);
      expect(result.suggestions, hasLength(3));
    });

    test('detecta una frase y conserva las claves sugeridas', () {
      final result = SuggestResult.fromJson(_decode(_suggestFrase));

      expect(result.isSentence, isTrue);
      expect(result.valid, isFalse);
      expect(result.reason, contains('palabras clave'));
      expect(result.keywords, isEmpty);
      expect(
        result.suggestions.map((s) => s.term),
        containsAll(['miel de Ulmo', 'Valdivia']),
      );
    });

    test('tolera una respuesta sin campos opcionales', () {
      final result = SuggestResult.fromJson({'query_type': 'empty'});

      expect(result.valid, isFalse);
      expect(result.keywords, isEmpty);
      expect(result.suggestions, isEmpty);
      expect(result.reason, isEmpty);
    });
  });

  group('KeywordSearchResult', () {
    late KeywordSearchResult result;

    setUp(() => result = KeywordSearchResult.fromJson(_decode(_keywordsUlmo)));

    test('deserializa los perfiles con su evidencia', () {
      expect(result.ok, isTrue);
      expect(result.count, 2);
      expect(result.results, hasLength(2));

      final primero = result.results.first;
      expect(primero.authUserId, '6020cdaf-4853-4a18-b46b-50d4ee53a4c2');
      expect(primero.nombre, 'Javier Cesar');
      expect(primero.nombreEmpresa, 'Apis sa');
      expect(primero.score, 6);
      expect(primero.matches, hasLength(2));
    });

    test('distingue la flora de zona de una coincidencia certificada', () {
      final matches = result.results.first.matches;

      expect(matches.first.isZoneFlora, isFalse);
      expect(matches.first.confidence, 'direct');
      expect(matches.last.isZoneFlora, isTrue);
    });

    test('compone la ubicación y la omite cuando el perfil no la tiene', () {
      expect(result.results.first.ubicacion, 'Puerto Montt, Los Lagos');
      expect(result.results.last.ubicacion, isNull);
    });

    test('los campos vacíos del servidor se leen como nulos', () {
      expect(result.results.last.nombreEmpresa, isNull);
      expect(result.results.last.comuna, isNull);
    });

    test('la evidencia se muestra como "Etiqueta: valor"', () {
      expect(
        result.results.last.matches.first.display,
        'Tipo de miel: Ulmo (PRIMAVERA)',
      );
    });

    test('la inicial del avatar sale del nombre', () {
      expect(result.results.first.inicial, 'J');
    });
  });

  group('KeywordChip', () {
    test('dos chips con el mismo término son iguales', () {
      const a = KeywordChip(
        term: 'Ulmo',
        normalized: 'ulmo',
        category: 'especie',
        label: 'Especie',
      );
      const b = KeywordChip(
        term: 'ulmo',
        normalized: 'ulmo',
        category: 'libre',
        label: 'Palabra clave',
      );

      expect(a, equals(b));
      expect({a, b}, hasLength(1));
    });

    test('solo envía término y categoría al servidor', () {
      final chip = KeywordChip.fromJson(_decode(_suggestUlmo)['keywords'][0]);

      expect(chip.toJson(), {'term': 'Ulmo', 'category': 'especie'});
    });

    test('usa una etiqueta de respaldo si el servidor no la envía', () {
      final chip = KeywordChip.fromJson({'term': 'x', 'category': 'polen'});

      expect(chip.label, 'Polen');
    });
  });

  group('KeywordSuggestion', () {
    test('una persona lleva id y abre el perfil', () {
      final persona = KeywordSuggestion.fromJson({
        'term': 'Erika Poblete',
        'category': 'apicultor',
        'label': 'Apicultor',
        'id': 'abc-123',
        'especialidad': 'Miel del Sur',
      });

      expect(persona.isPerson, isTrue);
      expect(persona.subtitle, 'Miel del Sur');
    });

    test('un término del catálogo no tiene id y se vuelve chip', () {
      final termino = KeywordSuggestion.fromJson({
        'term': 'Quillay',
        'category': 'especie',
      });

      expect(termino.isPerson, isFalse);
      expect(termino.subtitle, 'Especie');
      expect(termino.toChip().category, KeywordCategory.especie);
    });
  });
}
