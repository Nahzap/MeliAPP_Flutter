import '../models/lote_model.dart';
import '../models/species_name.dart';
import '../models/user_model.dart';
import 'taxa_service.dart';

/// Payload del certificado IEEE, alineado con `gestionar_lote.html` → POST `/certificado-preview`.
class CertificadoData {
  final Map<String, dynamic> json;

  const CertificadoData(this.json);

  Map<String, dynamic> get certificado =>
      Map<String, dynamic>.from(json['certificado'] as Map);
  Map<String, dynamic> get laboratorio =>
      Map<String, dynamic>.from(json['laboratorio'] as Map);
  Map<String, dynamic> get apicultor =>
      Map<String, dynamic>.from(json['apicultor'] as Map);
  Map<String, dynamic> get lote =>
      Map<String, dynamic>.from(json['lote'] as Map);
  Map<String, dynamic> get muestra =>
      Map<String, dynamic>.from(json['muestra'] as Map);
  Map<String, dynamic> get analisis =>
      Map<String, dynamic>.from(json['analisis_melisopalinologico'] as Map);
  Map<String, dynamic> get clasificacion =>
      Map<String, dynamic>.from(json['clasificacion_origen'] as Map);
  Map<String, dynamic> get resultado =>
      Map<String, dynamic>.from(json['resultado'] as Map);

  List<Map<String, dynamic>> get polenes {
    final raw = analisis['polenes_identificados'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

class CertificadoBuilder {
  static const missing = 'XXXX';

  static CertificadoData build({
    required Lote lote,
    User? apicultor,
    TaxaCatalog taxa = TaxaCatalog.empty,
    DateTime? now,
  }) {
    final emitted = now ?? DateTime.now();
    final polenes = _polenes(lote, taxa);
    final classification = _classify(polenes);
    final idShort = lote.id.length >= 8
        ? lote.id.substring(0, 8).toUpperCase()
        : lote.id.toUpperCase();
    final sampleId = lote.id.length >= 6
        ? lote.id.substring(0, 6).toUpperCase()
        : lote.id.toUpperCase();

    final ubicacion = (apicultor?.ubicaciones.isNotEmpty ?? false)
        ? apicultor!.ubicaciones.first
        : null;
    final muestra = lote.datosMuestra;
    final analisis = lote.datosCertificado?['analisis_melisopalinologico'];
    final analisisMap = analisis is Map
        ? Map<String, dynamic>.from(analisis)
        : <String, dynamic>{};

    final vigencia = DateTime(emitted.year + 1, emitted.month, emitted.day);
    final fechaRecepcionRaw = muestra?['fecha_recepcion']?.toString();
    final fechaRecepcion =
        (fechaRecepcionRaw != null &&
            fechaRecepcionRaw.trim().isNotEmpty &&
            fechaRecepcionRaw != missing)
        ? _formatDate(
            DateTime.tryParse(fechaRecepcionRaw) ?? emitted,
            fechaRecepcionRaw,
          )
        : missing;

    return CertificadoData({
      'certificado': {
        'id': '$missing (CERT-$idShort)',
        'tipo_documento': 'Certificado de Origen Botánico',
        'fecha_emision': _isoDate(emitted),
        'pais': 'Chile',
        'normativa_aplicable': 'Norma Chilena Oficial NCh2981.Of2005',
      },
      'laboratorio': {
        'nombre': 'Laboratorio Melisopalinológico UdeC - USS',
        'rut': '70.123.456-7',
        'acreditacion': 'INN-1234',
        'analista_responsable':
            lote.revisorNombre ?? '$missing (Nombre de cuenta revisora)',
        'fecha_aprobacion':
            (lote.fechaActualizacionRaw != null &&
                lote.fechaActualizacionRaw!.trim().isNotEmpty)
            ? '${lote.fechaActualizacionRaw} a las XXXX hrs'
            : missing,
      },
      'apicultor': {
        'rut': _orMissing(apicultor?.rut, fallback: '$missing (No registrado)'),
        'nombre': _orMissing(
          apicultor?.nombreCompleto ?? apicultor?.username,
          fallback: '$missing (Apicultor no registrado)',
        ),
        'registro_sag': _orMissing(apicultor?.registroSag),
        'contacto': {
          'email': _orMissing(apicultor?.email),
          'telefono': _orMissing(apicultor?.telefono),
        },
        'direccion': {
          'calle': _orMissing(apicultor?.direccion),
          'comuna': _orMissing(apicultor?.comuna),
          'region': _orMissing(apicultor?.region),
          'pais': 'Chile',
        },
      },
      'lote': {
        'codigo_lote': 'LOTE-${lote.ordenMiel == 0 ? '001' : lote.ordenMiel}',
        'fecha_cosecha': lote.anioCosecha != null
            ? 'Temporada ${lote.temporada} ${lote.anioCosecha}'
            : missing,
        'cantidad_kg': lote.kgProducidos ?? missing,
        'numero_colmenas': missing,
        'apiario': {
          'nombre': ubicacion?.nombre.isNotEmpty == true
              ? ubicacion!.nombre
              : (lote.nombreMiel),
          'latitud': ubicacion?.latitud ?? missing,
          'longitud': ubicacion?.longitud ?? missing,
          'altitud_m': missing,
          'comuna': _orMissing(
            ubicacion?.comuna,
            fallback: _orMissing(apicultor?.comuna),
          ),
          'region': _orMissing(
            ubicacion?.region,
            fallback: _orMissing(apicultor?.region),
          ),
        },
      },
      'muestra': {
        'id_muestra': 'M-$sampleId',
        'peso_g': muestra?['peso_g'] ?? missing,
        'metodo_extraccion': muestra?['metodo_extraccion'] ?? missing,
        'fecha_recepcion': fechaRecepcion,
      },
      'analisis_melisopalinologico': {
        'metodo':
            analisisMap['metodo'] ?? 'Microscopía óptica automatizada por IA',
        'total_granos_contados':
            analisisMap['total_granos_contados'] ?? missing,
        'polenes_identificados': polenes,
      },
      'clasificacion_origen': classification,
      'resultado': {
        'certificado_origen': classification['origen_botanico'],
        'denominacion': classification['denominacion'],
        'observaciones':
            'El análisis automatizado indica la presencia de: ${lote.composicion ?? missing}',
        'validez_hasta': _formatDate(vigencia, null),
      },
    });
  }

  static List<Map<String, dynamic>> _polenes(Lote lote, TaxaCatalog taxa) {
    if (lote.polenesIdentificados.isNotEmpty) {
      final list = [
        for (final pollen in lote.polenesIdentificados)
          Map<String, dynamic>.from(pollen),
      ];
      list.sort((a, b) {
        final av = _toDouble(a['proporcion_pct']) ?? 0;
        final bv = _toDouble(b['proporcion_pct']) ?? 0;
        return bv.compareTo(av);
      });
      return list;
    }

    final csv = lote.parseComposicion();
    if (csv.isNotEmpty) {
      final entries = csv.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return entries.map((entry) {
        final name = taxa.resolve(entry.key, lote: lote);
        return {
          'taxon': name.scientific,
          'nombre_comun': name.common ?? entry.key,
          'granos_contados': ((entry.value / 100) * 500).round(),
          'proporcion_pct': entry.value,
          'categoria': _categoria(taxa, entry.key),
        };
      }).toList();
    }

    return [
      {
        'taxon': missing,
        'nombre_comun': lote.composicion ?? 'Sin datos',
        'granos_contados': missing,
        'proporcion_pct': 100,
        'categoria': 'Polen Detectado',
      },
    ];
  }

  static Map<String, dynamic> _classify(List<Map<String, dynamic>> polenes) {
    var tipo = 'Miel Multifloral';
    var taxonPrincipal = missing;
    var origenBotanico = 'Multifloral';
    var umbral = missing;
    var cumple = missing;
    var denominacion = 'Miel de Abeja Multifloral';

    if (polenes.isNotEmpty) {
      final principal = polenes.first;
      final pct = _toDouble(principal['proporcion_pct']) ?? 0;
      if (pct >= 45) {
        tipo = 'Miel Monofloral';
        taxonPrincipal = '${principal['taxon'] ?? missing}';
        origenBotanico = '${principal['nombre_comun'] ?? missing}';
        umbral = '$pct%';
        cumple = 'Sí';
        denominacion = 'Miel de Abeja Monofloral de $origenBotanico';
      }
    }

    return {
      'tipo': tipo,
      'origen_botanico': origenBotanico,
      'taxon_principal': taxonPrincipal,
      'umbral_aplicado_pct': umbral,
      'cumple_criterio': cumple,
      'denominacion': denominacion,
    };
  }

  static String _categoria(TaxaCatalog taxa, String key) {
    final needle = SpeciesName.normalize(key);
    for (final record in taxa.records) {
      if (SpeciesName.normalize(record.nombreComun) == needle ||
          SpeciesName.normalize(record.nombreCientifico) == needle) {
        return record.clase?.trim().isNotEmpty == true
            ? record.clase!
            : 'Polen Detectado';
      }
    }
    return 'Polen Detectado';
  }

  static String _orMissing(String? value, {String fallback = missing}) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String _isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _formatDate(DateTime date, String? original) {
    if (original != null && original.contains('/') && !original.contains('T')) {
      return original;
    }
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll('%', '').trim());
  }
}
