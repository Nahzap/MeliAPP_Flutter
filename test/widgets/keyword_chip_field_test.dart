import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/models/search_models.dart';
import 'package:meliapp_flutter/widgets/keyword_chip_field.dart';
import 'package:meliapp_flutter/widgets/match_evidence_pills.dart';

KeywordChip _chip(String term, [String category = 'especie']) => KeywordChip(
  term: term,
  normalized: term.toLowerCase(),
  category: category,
  label: KeywordCategory.labelFor(category),
);

void main() {
  group('KeywordChipField', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    Future<void> pump(
      WidgetTester tester, {
      required List<KeywordChip> chips,
      ValueChanged<KeywordChip>? onRemove,
      VoidCallback? onSubmitted,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KeywordChipField(
              chips: chips,
              controller: controller,
              focusNode: focusNode,
              onChanged: (_) {},
              onSubmitted: onSubmitted ?? () {},
              onRemove: onRemove ?? (_) {},
              onBackspaceEmpty: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('muestra un chip por palabra clave', (tester) async {
      await pump(tester, chips: [_chip('Ulmo'), _chip('Valdivia', 'lugar')]);

      expect(find.text('Ulmo'), findsOneWidget);
      expect(find.text('Valdivia'), findsOneWidget);
    });

    testWidgets('el ejemplo del campo coincide con el de la web', (tester) async {
      await pump(tester, chips: []);

      expect(find.text('Ej: ulmo, Valdivia, polen de tineo'), findsOneWidget);
    });

    testWidgets('con chips pide otra palabra clave', (tester) async {
      await pump(tester, chips: [_chip('Ulmo')]);

      expect(find.text('Añade otra palabra clave'), findsOneWidget);
    });

    testWidgets('tocar la x quita ese chip', (tester) async {
      KeywordChip? quitado;
      await pump(
        tester,
        chips: [_chip('Ulmo'), _chip('Tineo')],
        onRemove: (chip) => quitado = chip,
      );

      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pump();

      expect(quitado?.term, 'Tineo');
    });

    testWidgets('con 5 chips se bloquea la entrada y se avisa', (tester) async {
      await pump(
        tester,
        chips: [
          _chip('Ulmo'),
          _chip('Tineo'),
          _chip('Avellano'),
          _chip('Quillay'),
          _chip('Valdivia', 'lugar'),
        ],
      );

      expect(find.text('Máximo 5 palabras clave'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('enviar desde el teclado confirma el borrador', (tester) async {
      var confirmado = false;
      await pump(tester, chips: [], onSubmitted: () => confirmado = true);

      await tester.enterText(find.byType(TextField), 'ulmo');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(confirmado, isTrue);
    });
  });

  group('MatchEvidencePills', () {
    Future<void> pumpPills(WidgetTester tester, List<SearchMatch> matches) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MatchEvidencePills(matches: matches)),
        ),
      );
    }

    SearchMatch match(String category, String evidence, {String? confidence}) =>
        SearchMatch(
          category: category,
          term: 'ulmo',
          evidence: evidence,
          confidence: confidence ?? 'direct',
          label: KeywordCategory.labelFor(category),
        );

    testWidgets('muestra la etiqueta y la evidencia', (tester) async {
      await pumpPills(tester, [match('polen', 'Ulmo (62%)')]);

      expect(find.text('Polen: Ulmo (62%)'), findsOneWidget);
    });

    testWidgets('sin coincidencias no ocupa espacio', (tester) async {
      await pumpPills(tester, []);

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.textContaining(':'), findsNothing);
    });

    testWidgets('resume las coincidencias que exceden el máximo', (tester) async {
      await pumpPills(tester, [
        match('polen', 'a'),
        match('tipo_miel', 'b'),
        match('lugar', 'c'),
        match('especie', 'd'),
        match('zona', 'e', confidence: 'zone_flora'),
        match('libre', 'f'),
      ]);

      expect(find.text('+2'), findsOneWidget);
    });
  });
}
