import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../models/search_models.dart';

/// Muestra por qué un perfil apareció en los resultados.
///
/// Replica el código de color de `templates/pages/search.html` para que la
/// misma coincidencia se lea igual en el visor y en meliapp.cl.
class MatchEvidencePills extends StatelessWidget {
  final List<SearchMatch> matches;
  final int maxVisible;

  const MatchEvidencePills({
    super.key,
    required this.matches,
    this.maxVisible = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();

    final visibles = matches.take(maxVisible).toList();
    final restantes = matches.length - visibles.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visibles.map(_buildPill),
        if (restantes > 0)
          _pill('+$restantes', AppTheme.slate100, AppTheme.slate600),
      ],
    );
  }

  Widget _buildPill(SearchMatch match) {
    final colores = _colorsFor(match);
    return _pill(match.display, colores.$1, colores.$2);
  }

  static Widget _pill(String texto, Color fondo, Color textoColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          color: textoColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// (fondo, color de texto) según la categoría de la coincidencia.
  static (Color, Color) _colorsFor(SearchMatch match) {
    // La flora de zona es una señal indirecta: se atenúa a propósito para no
    // confundirla con polen certificado en un lote.
    if (match.isZoneFlora) {
      return (AppTheme.slate100, AppTheme.slate600);
    }
    switch (match.category) {
      case KeywordCategory.tipoMiel:
        return (AppTheme.amber100, const Color(0xFF92400E)); // amber-800
      case KeywordCategory.polen:
        return (const Color(0xFFD1FAE5), const Color(0xFF065F46)); // emerald
      case KeywordCategory.lugar:
        return (const Color(0xFFE0F2FE), const Color(0xFF075985)); // sky
      case KeywordCategory.especie:
        return (const Color(0xFFEDE9FE), const Color(0xFF5B21B6)); // violet
      case KeywordCategory.apicultor:
        return (AppTheme.amber50, const Color(0xFF92400E));
      default:
        return (AppTheme.slate100, AppTheme.slate700);
    }
  }
}
