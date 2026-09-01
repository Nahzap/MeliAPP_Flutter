import 'package:flutter/foundation.dart';
import 'package:meliapp_flutter/services/api_service.dart';

/// Flora de referencia por comuna (CSV Cloud: /api/botanical-classes/{comuna}).
class BotanicalClasses {
  final String comuna;
  final int totalClasses;
  final int totalSpecies;
  final List<BotanicalClassGroup> classes;
  final List<BotanicalSpecies> allSpecies;

  const BotanicalClasses({
    required this.comuna,
    required this.totalClasses,
    required this.totalSpecies,
    required this.classes,
    required this.allSpecies,
  });

  /// Conteos por clase para un gráfico de visor.
  Map<String, double> get classCounts {
    final result = <String, double>{};
    for (final group in classes) {
      result[group.titulo] = group.cantidad.toDouble();
    }
    return result;
  }
}

class BotanicalClassGroup {
  final String clase;
  final String titulo;
  final String descripcion;
  final int cantidad;
  final List<BotanicalSpecies> especies;

  const BotanicalClassGroup({
    required this.clase,
    required this.titulo,
    required this.descripcion,
    required this.cantidad,
    required this.especies,
  });
}

class BotanicalSpecies {
  final String nombreComun;
  final String nombreCientifico;
  final String? clase;

  const BotanicalSpecies({
    required this.nombreComun,
    required this.nombreCientifico,
    this.clase,
  });
}

class BotanicalService {
  final ApiService _api = ApiService();

  Future<BotanicalClasses?> getByComuna(String? comuna) async {
    final name = comuna?.trim() ?? '';
    if (name.isEmpty) return null;

    try {
      final response = await _api.dio.get(
        '/api/botanical-classes/${Uri.encodeComponent(name)}',
      );
      final data = response.data;
      if (data is! Map || data['success'] != true) {
        debugPrint(
          '[FLORA] Comuna sin datos: $name ${data is Map ? data['message'] : ''}',
        );
        return null;
      }

      final classesRaw = data['classes'] as List? ?? [];
      final speciesRaw = data['all_species'] as List? ?? [];

      final groups = classesRaw.whereType<Map>().map((raw) {
        final map = Map<String, dynamic>.from(raw);
        final especies = (map['especies'] as List? ?? [])
            .whereType<Map>()
            .map(
              (e) => BotanicalSpecies(
                nombreComun: '${e['nombre_comun'] ?? ''}',
                nombreCientifico:
                    '${e['nombre_cientifico'] ?? e['nombre_comun'] ?? ''}',
                clase: map['clase']?.toString(),
              ),
            )
            .toList();
        return BotanicalClassGroup(
          clase: '${map['clase'] ?? ''}',
          titulo: '${map['titulo'] ?? map['clase'] ?? ''}',
          descripcion: '${map['descripcion'] ?? ''}',
          cantidad: map['cantidad'] is int
              ? map['cantidad'] as int
              : especies.length,
          especies: especies,
        );
      }).toList();

      final species = speciesRaw.whereType<Map>().map((e) {
        return BotanicalSpecies(
          nombreComun: '${e['nombre_comun'] ?? ''}',
          nombreCientifico:
              '${e['nombre_cientifico'] ?? e['nombre_comun'] ?? ''}',
          clase: e['clase']?.toString(),
        );
      }).toList();

      return BotanicalClasses(
        comuna: '${data['comuna'] ?? name}',
        totalClasses: data['total_classes'] is int
            ? data['total_classes'] as int
            : groups.length,
        totalSpecies: data['total_species'] is int
            ? data['total_species'] as int
            : species.length,
        classes: groups,
        allSpecies: species,
      );
    } catch (e) {
      debugPrint('[FLORA] Error: $e');
      return null;
    }
  }
}
