import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/widgets/composition_pie_chart.dart';

void main() {
  testWidgets('muestra estado vacío cuando no hay composición', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CompositionPieChart(composicion: {})),
      ),
    );

    expect(find.text('Sin datos de composición'), findsOneWidget);
  });

  testWidgets('renderiza leyenda de especies cuando hay datos', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CompositionPieChart(composicion: {'Maitén': 60, 'Notro': 40}),
        ),
      ),
    );

    expect(find.textContaining('Maitén'), findsOneWidget);
    expect(find.textContaining('Notro'), findsOneWidget);
    expect(find.text('Sin datos de composición'), findsNothing);
  });
}
