import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../models/lote_model.dart';
import '../models/species_name.dart';
import 'api_service.dart';

class TaxonRecord {
  final String nombreComun;
  final String nombreCientifico;
  final String? clase;

  const TaxonRecord({
    required this.nombreComun,
    required this.nombreCientifico,
    this.clase,
  });
}

/// Catálogo en memoria para resolver común → científico (mismo criterio que Cloud).
class TaxaCatalog {
  final List<TaxonRecord> records;

  const TaxaCatalog(this.records);

  static const empty = TaxaCatalog([]);

  SpeciesName resolve(String raw, {Lote? lote}) {
    final parsed = SpeciesName.parse(raw);
    if (lote != null) {
      final pollen =
          _pollenMatch(raw, lote) ?? _pollenMatch(parsed.scientific, lote);
      if (pollen != null) {
        final common = pollen.$1;
        final taxon = pollen.$2;
        if (taxon.isNotEmpty) {
          return SpeciesName.fromParts(taxon, common);
        }
        final fromTable = common.isNotEmpty ? _fromTable(common) : null;
        if (fromTable != null) {
          return SpeciesName.fromParts(fromTable.nombreCientifico, common);
        }
        return SpeciesName.fromParts(null, common);
      }
    }

    final fromTable =
        _fromTable(parsed.scientific) ??
        (parsed.hasDistinctCommon ? _fromTable(parsed.common!) : null);
    if (fromTable != null) {
      final lookedUpScientific = _matches(
        SpeciesName.normalize(raw),
        fromTable.nombreCientifico,
      );
      final common = parsed.hasDistinctCommon
          ? parsed.common
          : (lookedUpScientific ? fromTable.nombreComun : raw.trim());
      return SpeciesName.fromParts(fromTable.nombreCientifico, common);
    }

    return parsed;
  }

  Map<String, double> labeledComposition(
    Map<String, double> source, {
    Lote? lote,
  }) {
    final result = <String, double>{};
    for (final entry in source.entries) {
      final label = resolve(entry.key, lote: lote).displayText;
      result[label] = (result[label] ?? 0) + entry.value;
    }
    return result;
  }

  (String common, String taxon)? _pollenMatch(String raw, Lote lote) {
    final needle = SpeciesName.normalize(raw);
    if (needle.isEmpty) return null;
    for (final pollen in lote.polenesIdentificados) {
      final common = '${pollen['nombre_comun'] ?? ''}'.trim();
      final taxon = '${pollen['taxon'] ?? ''}'.trim();
      if (_matches(needle, common) || _matches(needle, taxon)) {
        return (common, taxon);
      }
    }
    return null;
  }

  TaxonRecord? _fromTable(String raw) {
    final needle = SpeciesName.normalize(raw);
    if (needle.isEmpty || records.isEmpty) return null;

    for (final record in records) {
      if (_matches(needle, record.nombreComun) ||
          _matches(needle, record.nombreCientifico)) {
        return record;
      }
    }

    TaxonRecord? partial;
    for (final record in records) {
      final common = SpeciesName.normalize(record.nombreComun);
      final sci = SpeciesName.normalize(record.nombreCientifico);
      if (common.isNotEmpty &&
          (needle.contains(common) || common.contains(needle))) {
        return record;
      }
      if (partial == null &&
          sci.isNotEmpty &&
          (needle.contains(sci) || sci.contains(needle))) {
        partial = record;
      }
    }
    return partial;
  }

  bool _matches(String needle, String candidate) {
    final value = SpeciesName.normalize(candidate);
    return value.isNotEmpty && value == needle;
  }
}

/// Carga `/api/taxas` una vez (clases.csv de Cloud).
class TaxaService extends ChangeNotifier {
  TaxaService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;
  TaxaCatalog _catalog = TaxaCatalog.empty;
  bool _loaded = false;
  Future<TaxaCatalog>? _inFlight;

  TaxaCatalog get catalog => _catalog;
  bool get isLoaded => _loaded;

  static TaxaCatalog catalogOf(BuildContext context, {bool listen = true}) {
    try {
      return Provider.of<TaxaService>(context, listen: listen).catalog;
    } on ProviderNotFoundException {
      return TaxaCatalog.empty;
    }
  }

  Future<TaxaCatalog> ensureLoaded() {
    if (_loaded) return Future.value(_catalog);
    _inFlight ??= _load();
    return _inFlight!;
  }

  Future<TaxaCatalog> _load() async {
    try {
      final response = await _api.dio.get('/api/taxas');
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final raw = data['taxas'] as List? ?? [];
        _catalog = TaxaCatalog(
          raw
              .whereType<Map>()
              .map((row) {
                final map = Map<String, dynamic>.from(row);
                return TaxonRecord(
                  nombreComun:
                      '${map['Nombre Comun'] ?? map['nombre_comun'] ?? ''}'
                          .trim(),
                  nombreCientifico:
                      '${map['Nombre Cientifico'] ?? map['nombre_cientifico'] ?? ''}'
                          .trim(),
                  clase: (map['Clase'] ?? map['clase'])?.toString(),
                );
              })
              .where(
                (t) =>
                    t.nombreComun.isNotEmpty || t.nombreCientifico.isNotEmpty,
              )
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('[TAXA] Error cargando taxas: $e');
    } finally {
      _loaded = true;
      _inFlight = null;
      notifyListeners();
    }
    return _catalog;
  }
}
