/// Nombre botánico para visor: latín primero, común entre paréntesis.
class SpeciesName {
  final String scientific;
  final String? common;

  const SpeciesName({required this.scientific, this.common});

  factory SpeciesName.fromParts(String? scientific, String? common) {
    final sci = scientific?.trim() ?? '';
    final com = common?.trim() ?? '';
    if (sci.isNotEmpty) {
      return SpeciesName(
        scientific: sci,
        common: com.isEmpty || _same(sci, com) ? null : com,
      );
    }
    return SpeciesName(scientific: com);
  }

  /// Acepta "Latín (Común)" o un nombre suelto.
  factory SpeciesName.parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const SpeciesName(scientific: '');
    final match = RegExp(r'^(.*?)\s*\((.+)\)\s*$').firstMatch(text);
    if (match != null) {
      return SpeciesName.fromParts(match.group(1), match.group(2));
    }
    return SpeciesName(scientific: text);
  }

  bool get hasDistinctCommon {
    final com = common?.trim();
    if (com == null || com.isEmpty) return false;
    return !_same(scientific, com);
  }

  /// Texto estable: `Maytenus boaria (Maitén)`.
  String get displayText {
    if (!hasDistinctCommon) return scientific;
    return '$scientific ($common)';
  }

  static String normalize(String value) {
    final lower = value.trim().toLowerCase();
    final decomposed = lower.replaceAllMapped(RegExp(r'[áàäâ]'), (_) => 'a');
    return decomposed
        .replaceAllMapped(RegExp(r'[éèëê]'), (_) => 'e')
        .replaceAllMapped(RegExp(r'[íìïî]'), (_) => 'i')
        .replaceAllMapped(RegExp(r'[óòöô]'), (_) => 'o')
        .replaceAllMapped(RegExp(r'[úùüû]'), (_) => 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool _same(String a, String b) => normalize(a) == normalize(b);
}
