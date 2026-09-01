# Plan: buscador por palabras clave (perfil apícola)

**Proyecto:** MeliAPP Cloud (`MeliAPP_v2`) + visor Flutter (`MeliAPP_Flutter`)  
**Versión:** 1.0.0  
**Estado:** IMPLEMENTADO EN CLOUD (solo web) — la parte de visor está superada por `PLAN_ALINEACION_BUSCADOR_FLUTTER.md`  
**Creado:** 1 septiembre 2026  
**Complementa a:** `PLAN_PARIDAD_VISOR_CLOUD.md` (el visor ya abre perfil desde `/search`; este plan cambia *cómo* se llega a ese perfil)

> **Nota de estado (1 sep 2026).** El motor se implementó en `MeliAPP_v2` con nombres de faceta y decisiones distintas a las de este documento: 7 categorías (`apicultor`, `tipo_miel`, `polen`, `especie`, `lugar`, `zona`, `libre`) en vez de 8; sin parser espejo en Dart (el servidor es autoritativo); sin endpoints `/api/search/*` (solo `/sugerir?modo=keywords` y `/buscar` en HTML); y sin las facetas `temporada` ni `clase_botanica`.
>
> Las secciones de **gramática, privacidad y dominios** de este plan siguen vigentes. Las de **contrato de API, fases, métricas y UX de Flutter** están sustituidas por `PLAN_ALINEACION_BUSCADOR_FLUTTER.md`, que parte del código real.

---

## 1. Objetivo

Que el usuario encuentre un **perfil apícola** con palabras clave (apicultor, tipo de miel, polen, especie, territorio, rol), y que **no pueda buscar con oraciones**.

El resultado canónico sigue siendo un perfil (`auth_user_id` → `ProfileViewScreen` / `/profile/{id}`). Lotes, polen y taxones son *razones de coincidencia*, no destinos separados.

### Qué significa “palabra clave”

Una etiqueta corta, normativa o de catálogo, no una pregunta. Ejemplos válidos:

| Palabra clave | Faceta |
|---------------|--------|
| `Quillay` | taxón / polen |
| `Eucryphia cordifolia` | taxón científico |
| `Lonquimay` | comuna |
| `monofloral` | tipo de miel (NCh2981) |
| `Erika` | persona |
| `apicultor` | rol |
| `primavera` | temporada / floración |

Ejemplos prohibidos (sentencia / intención):

- `quiero miel de ulmo cerca de Temuco`
- `qué apicultores tienen polen de quillay`
- `dónde hay miel monofloral`

Esas entradas se rechazan y, si se puede, se **sugieren** las claves extraídas (`Ulmo`, `Temuco`, `monofloral`).

---

## 2. Principio (no negociable)

Un parser. Un contrato de API. Los dos clientes (web y Flutter) lo consumen. El servidor no confía en el cliente.

| En Cloud | En Flutter / web |
|----------|------------------|
| Gramática, catálogo, búsqueda y rechazo de sentencias | Chips, sugerencias, mismo parser para UX inmediata |
| Fuente de verdad: tablas públicas ya existentes | Pintar perfiles + facetas de coincidencia |
| Logs de métricas (sin PII) | Eventos de UI alineados a los mismos nombres |

**Fuera de alcance:** LLM, Elasticsearch, tablas nuevas (`resultados_polinicos` y similares están obsoletas), buscar RUT / email / teléfono / SAG como clave pública.

---

## 3. Estado actual (causa en código)

Hoy el buscador **no es un buscador de perfil apícola**. Es autocompletado de nombre.

| Superficie | Qué hace | Límite |
|------------|----------|--------|
| Flutter `SearchScreen` | `GET /sugerir?q=` en cada tecla, mínimo 2 caracteres | Sin debounce, sin chips, sin facetas |
| Cloud `templates/pages/search.html` | Igual: `/sugerir` + `POST /buscar` | Placeholder: “Busca por nombre” |
| Cloud `sugerir()` | `info_contacto.nombre_completo ILIKE %q%`, límite 10 | Solo nombre; N+1 a `usuarios.tipo_usuario` |
| `Searcher.search_users_by_query` | `usuarios.username ILIKE` | No se usa en Flutter |
| `Searcher.search_fields` | Declara ubicaciones, orígenes botánicos, solicitudes | **No está cableado** a `/sugerir` |

El visor ya sabe interpretar el perfil: lotes (`nombre_miel`, `composicion`, `datos_certificado.polenes_identificados`), taxones (`GET /api/taxas` ← `data/clases.csv`), flora por comuna (`GET /api/botanical-classes/{comuna}`), tipos NCh2981 (monofloral si polen dominante ≥ 45 %). Nada de eso entra al índice de búsqueda.

**Brecha de cobertura:** 1 de 8 facetas (persona-nombre). El resto es cero.

---

## 4. Gramática (única, espejo Python / Dart)

### 4.1 Tokenización

1. Recortar extremos.
2. Separar por `,` `;` o salto de línea. Cada fragmento es un candidato a chip.
3. Si no hay separador, el texto entero es un solo candidato (no se parte por espacios: `Erika Poblete` y `miel de ulmo` son una clave).

Límites:

- 1 a 5 chips activos
- 2 a 40 caracteres por chip (después de normalizar espacios)
- Normalización de comparación: la misma que `SpeciesName.normalize` (minúsculas, sin tildes, `ñ` → `n`)

### 4.2 Detector de sentencia (rechazo)

Se rechaza el candidato si cumple **cualquiera**:

1. Contiene `?` o `¿`.
2. Tiene 7 o más tokens separados por espacio.
3. Coincide con patrón de intención (palabra completa, no subcadena):  
   `quiero`, `busco`, `necesito`, `donde`, `dónde`, `cuales`, `cuáles`, `quien`, `quién`, `hay`, `muestrame`, `muéstrame`, `encuentra`, `encontrar`, `dame`, `lista`, `apicultores que`, `mieles que`.
4. El texto sin separar tiene 4 o más tokens **y** al menos dos stopwords de función:  
   `el`, `la`, `los`, `las`, `un`, `una`, `que`, `para`, `con`, `por`, `como`, `cerca`, `sobre`.

No se rechaza solo por contener `de` o `del`: son parte de frases de catálogo (`miel de ulmo`, `Los Ríos`).

Si se rechaza:

- HTTP 400 en API (`code: sentence_rejected`)
- UI: mensaje corto + chips sugeridos (claves de catálogo que aparecen como subcadena)

Falsos positivos a vigilar (set de oro): `miel de ulmo`, `Los Lagos`, `prestador de servicios`.

### 4.3 Clasificación de faceta (best effort)

Cada chip aceptado se etiqueta con **una** faceta, en este orden (primer hit gana):

1. `tipo_miel` — catálogo cerrado: `monofloral`, `multifloral`, `miel monofloral`, `miel multifloral`, `bifloral` (alias de multifloral si no hay umbral propio)
2. `rol` — `apicultor`, `prestador de servicios`, `prestador_servicios`, `proveedor`, `usuario general`, `regular`
3. `geo` — comuna o región de `clases.csv` / `GET /api/comunas` / `GET /api/regiones`
4. `taxon` — nombre común o científico de `GET /api/taxas`
5. `temporada` — `primavera`, `verano`, `otoño`, `invierno` y periodos del CSV (`Periodo de Floracion`)
6. `clase_botanica` — `Arbol`, `Arbusto`, etc. (columna `Clase`)
7. `persona` — resto (nombre, username, empresa). No exige catálogo.

La clasificación alimenta sugerencias y ranking. **La búsqueda no descarta** un chip si la faceta se equivoca: el backend sigue buscando ese texto en todos los campos públicos (con pesos distintos).

---

## 5. Dominios del perfil apícola (qué se indexa)

Solo campos que el perfil público ya puede mostrar. Sin PII de contacto.

| Faceta | Fuente | Campo |
|--------|--------|-------|
| Persona | `info_contacto`, `usuarios` | `nombre_completo`, `nombre_empresa`, `username` |
| Rol | `usuarios` | `tipo_usuario`, `role` |
| Geo | `info_contacto`, `ubicaciones` | `comuna`, `region`, `nombre` de apiario |
| Tipo de miel | `origenes_botanicos` + JSON certificado | `nombre_miel`; `datos_certificado.clasificacion_origen.tipo` / `resultado.denominacion`; fallback: polen dominante ≥ 45 % → monofloral |
| Polen / especie | mismo lote | `composicion` (CSV), `polenes_identificados[].nombre_comun` y `.taxon` |
| Temporada | lote + CSV flora | `temporada`, `anio_cosecha`; periodo de floración del taxón |
| Clase botánica | `clases.csv` vía taxón resuelto | `Clase` |
| Flora de comuna | no se “busca la comuna en el CSV” como resultado | Si el chip es taxón, también matchea apicultores cuya **comuna** lista esa especie en flora de referencia (señal débil, peso bajo) |

Privacidad: no indexar `email`, `telefono`, `rut`, `registro_sag`, `direccion` completa, ni `observaciones_revisor`.

---

## 6. Contrato de API

Un endpoint nuevo. `/sugerir` se mantiene hasta que Flutter y web migren; no se le añade más debug de contactos.

### 6.1 Sugerir claves (mientras escribe)

```
GET /api/search/keyword-suggest?q={texto}&limit=8
```

Respuesta:

```
{
  "query": "qui",
  "rejected": false,
  "suggestions": [
    { "text": "Quillay", "facet": "taxon", "scientific": "Quillaja saponaria" },
    { "text": "Quilpué", "facet": "geo" }
  ]
}
```

Si `q` es sentencia: `rejected: true`, `code: sentence_rejected`, `suggestions` = claves extraídas (máx. 5). HTTP 200 (es asistencia, no error de búsqueda).

### 6.2 Buscar perfiles

```
GET /api/search/keywords?k=quillay&k=lonquimay&limit=20
```

- Cada `k` es un chip ya aceptado.
- Semántica: **AND entre chips** (intersección de `auth_user_id`).
- Si algún `k` falla la gramática: HTTP 400, ningún resultado parcial (evita “búsqueda de oración” por la puerta de atrás).

Respuesta:

```
{
  "keywords": [
    { "text": "quillay", "facet": "taxon" },
    { "text": "lonquimay", "facet": "geo" }
  ],
  "results": [
    {
      "id": "<auth_user_id>",
      "nombre": "Erika Poblete",
      "especialidad": "apicultor",
      "comuna": "Lonquimay",
      "region": "La Araucanía",
      "score": 12.4,
      "matches": [
        { "facet": "taxon", "field": "composicion", "value": "Quillay" },
        { "facet": "geo", "field": "comuna", "value": "Lonquimay" }
      ]
    }
  ]
}
```

Flutter deja de adivinar `email` / `telefono` en la card. La ficha completa sigue en el perfil.

### 6.3 Ranking (determinista)

Puntaje = suma de pesos de coincidencias, un máximo por chip:

| Tipo de hit | Peso |
|-------------|------|
| Exacto en catálogo (taxón, geo, tipo, rol) | 5 |
| Prefijo de nombre de persona / empresa | 4 |
| Subcadena en `composicion` / polen certificado | 3 |
| Subcadena en `nombre_miel` / denominación | 3 |
| Flora de comuna (CSV, no lote) | 1 |

Desempate: más facetas distintas, luego nombre A–Z.

### 6.4 Implementación backend (v1, sin tabla nueva)

Servicio nuevo `services/keyword_search.py`:

1. Parse + reject (misma gramática).
2. Resolver catálogo en memoria (taxas + comunas; cache de proceso, TTL 1 h).
3. Consultas acotadas a Supabase (`ilike` + `limit`), **por chip**, union de ids por chip, luego intersección.
4. Hidratar nombre / rol / comuna (como hoy hace `/sugerir`, sin log de filas).
5. Adjuntar `matches` recorriendo solo los lotes de los ids finalistas (no escanear toda la tabla dos veces).

Si el volumen crece y p95 > SLO: índice `pg_trgm` en `composicion`, `nombre_completo`, `nombre_miel`. No se abre esa puerta en v1.

---

## 7. UX

### Flutter (`SearchScreen`)

1. Campo único. Hint: `Palabras clave: especie, comuna, miel…`
2. Debounce 300 ms para `/keyword-suggest` (hoy no hay debounce).
3. Enter / coma confirma un chip si el parser acepta.
4. Chips bajo el campo; tap en X los quita; al cambiar chips se relanza `/keywords`.
5. Lista de sugerencias de **claves** (no de personas) mientras el foco está en el input.
6. Lista de **perfiles** debajo, con pills de `matches` (p. ej. `Polen · Quillay`).
7. Sentencia: banner, input no se convierte en chip, se ofrecen las claves extraídas para un tap.

Empty state: 6–8 chips de ejemplo del catálogo (Ulmo, Quillay, Lonquimay, monofloral, primavera, apicultor). No son búsquedas automáticas.

### Web (`search.html`)

El mismo contrato y la misma gramática. El formulario deja de enviar una oración a `/buscar`.

---

## 8. Fases de implementación (proceso)

No se mezcla con Play Store ni con edición de lotes.

| Fase | Qué cierra | Dueño | Señal de salida |
|------|------------|-------|-----------------|
| 0 Instrumentar | Contadores en `/sugerir` actual (q_len, is_sentence heurística offline, hits, latencia) | Cloud | 7 días de baseline o 100 búsquedas, lo que ocurra primero |
| 1 Gramática | Módulo parser + tests (Python y Dart, mismos casos) | ambos | 100 % del set de gramática en verde |
| 2 Catálogo | `/keyword-suggest` sobre taxas, geo, tipos, roles | Cloud | Sugerir `Quillay` ante `qui` |
| 3 Búsqueda | `/keywords` + AND + `matches` | Cloud | Set de oro de perfiles ≥ umbral (sección 10) |
| 4 Flutter | Chips, debounce, cards con facetas, tap → perfil | Flutter | Checklist manual (sección 12) |
| 5 Web | Paridad de `search.html` | Cloud | Misma checklist en meliapp.cl |
| 6 Cierre | Deprecar uso de `/sugerir` en clientes; métricas vs target; CHANGELOG | ambos | Indicadores de sección 9 en verde |

Orden: 0 puede correr en paralelo a 1. 4 no empieza hasta que 3 pase el set de oro en staging (o contra Cloud con cuenta de prueba).

Estimación: fases 1–4 en 4–6 días de trabajo efectivo; fase 5 medio día; fase 0+6 un día extra (instrumentación y umbrales).

---

## 9. Métricas e indicadores

Hay tres capas. No se usa una sola “tasa de éxito”.

### 9.1 Indicadores de proceso (este trabajo)

Se revisan al terminar cada fase. Fuente: checklist + CI, no producción.

| ID | Indicador | Cómo se mide | Baseline | Target de cierre |
|----|-----------|--------------|----------|------------------|
| P1 | Facetas cableadas | Conteos en código del servicio de búsqueda | 1 / 8 | 8 / 8 |
| P2 | Clientes en el contrato nuevo | Flutter y web llaman `/keywords` | 0 / 2 | 2 / 2 |
| P3 | Casos de gramática | Tests compartidos (archivo de casos) | 0 | ≥ 30, 100 % pass |
| P4 | Set de oro perfiles | Queries de sección 10 contra staging | 0 / 16 | ≥ 14 / 16 (87.5 %) |
| P5 | Falso rechazo de frase válida | `miel de ulmo`, `Los Lagos`, `prestador de servicios`, nombres de 2 palabras | n/d | 0 / 6 |
| P6 | Cobertura de tests del parser | `flutter test` + pytest del módulo nuevo | 0 % | ≥ 90 % líneas del parser |
| P7 | Debounce en UI | Hay timer; no hay request por tecla | 0 | 1 (sí) |

### 9.2 Indicadores de producto (producción, post-despliegue)

Eventos (sin texto libre de búsqueda en logs si parece sentencia; sí `keyword_count`, `facets[]`, `rejected`, `result_count`, `latency_ms`).

| ID | Indicador | Definición | Ventana | Target 14 días |
|----|-----------|------------|---------|----------------|
| K1 | Tasa de rechazo de sentencia | `rejected=true` / búsquedas intentadas | 14 d | 5–25 % (hay rechazo, no es el modo normal) |
| K2 | Tasa de aceptación de sugerencia | chips creados desde suggest / chips totales | 14 d | ≥ 40 % |
| K3 | Tasa de cero resultados | `result_count=0` y `rejected=false` | 14 d | ≤ 30 % |
| K4 | Conversión a perfil | tap perfil / búsquedas con resultados | 14 d | ≥ 50 % |
| K5 | Uso multi-clave | búsquedas con ≥ 2 chips / búsquedas válidas | 14 d | ≥ 15 % (el AND se usa) |
| K6 | Diversidad de faceta | búsquedas cuyo chip principal no es `persona` | 14 d | ≥ 35 % |
| K7 | Latencia p95 `/keywords` | servidor | 14 d | ≤ 400 ms |
| K8 | Reducción de requests | requests search / sesión vs baseline fase 0 | 14 d | ≤ 40 % del volumen por tecla actual |

Si K1 > 40 %: el detector es agresivo (revisar P5). Si K1 ≈ 0 %: el detector no está en el cliente o nadie pega oraciones (revisar copy). Si K3 > 30 % con K6 alto: faltan datos en lotes, no es un bug de UI.

### 9.3 Indicadores de calidad de ranking (laboratorio, no usuario)

Sobre el set de oro (sección 10):

| ID | Indicador | Target |
|----|-----------|--------|
| Q1 | Precision@5 | ≥ 0.80 |
| Q2 | Recall de perfiles esperados (lista corta por query) | ≥ 0.85 |
| Q3 | NDCG@5 si hay orden esperado | ≥ 0.75 |
| Q4 | `matches[].facet` correcto en el primer resultado | ≥ 0.90 |

Fórmula Precision@5 = (relevantes en los 5 primeros) / min(5, |resultados|). Un perfil es relevante si está en la lista esperada de esa query.

---

## 10. Set de oro (aceptación de búsqueda)

Queries que deben existir como tests de integración (staging). Perfiles esperados se anclan a datos reales de prueba (p. ej. Erika / Lonquimay / lotes con polen conocido); si el dato no está, se carga un fixture, no se relaja el test.

### 10.1 Deben encontrar perfil

| # | Chips | Faceta esperada en `matches` |
|---|-------|------------------------------|
| G1 | `quillay` | taxon / polen |
| G2 | `Eucryphia` o científico completo de un lote fixture | taxon |
| G3 | `Lonquimay` | geo |
| G4 | `monofloral` | tipo_miel |
| G5 | `apicultor` | rol |
| G6 | `primavera` | temporada (lote o floración) |
| G7 | `ulmo`, `Valdivia` (AND) | taxon + geo |
| G8 | nombre de pila de un usuario fixture | persona |
| G9 | `nombre_miel` exacto de un lote fixture | tipo_miel / nombre |
| G10 | clase `Arbol` si hay taxón de esa clase en composición | clase_botanica |

### 10.2 Deben rechazarse (cero búsqueda)

| # | Texto | Extraer sugerencia |
|---|-------|--------------------|
| R1 | `quiero miel de ulmo` | `Ulmo` |
| R2 | `dónde hay apicultores` | `apicultor` |
| R3 | `qué mieles monoflorales hay cerca` | `monofloral` |
| R4 | `busca polen de quillay en la araucanía por favor` | `Quillay`, geo si aplica |

### 10.3 Deben aceptarse (no son sentencia)

| # | Texto |
|---|-------|
| A1 | `miel de ulmo` |
| A2 | `Los Lagos` |
| A3 | `prestador de servicios` |
| A4 | `Erika Poblete` |
| A5 | `Quillaja saponaria` |
| A6 | `miel monofloral` |

Cierre de fase 3: G1–G10 con Q1–Q2; R1–R4 con `sentence_rejected`; A1–A6 sin rechazo (P5).

---

## 11. Archivos previstos (cuando se autorice código)

**Cloud**

- `services/keyword_search.py` (nuevo)
- `services/keyword_grammar.py` (nuevo, puro)
- `routes/searcher_routes.py` (dos GET)
- tests: `tests/test_keyword_grammar.py`, `tests/test_keyword_search_gold.py`
- `templates/pages/search.html` + JS (fase 5)
- Instrumentación fase 0 en `sugerir()`: log estructurado `search_suggest` **sin** volcar filas de contacto

**Flutter**

- `lib/services/keyword_grammar.dart`
- `lib/services/search_service.dart`
- `lib/models/search_models.dart` (hoy `SearchResult` vive en la pantalla)
- `lib/screens/search_screen.dart`
- `test/services/keyword_grammar_test.dart` (mismos casos que Python)
- `test/screens/search_screen_test.dart` (sentencia, chips, empty)

Los casos de gramática deben ser un JSON compartido o tablas gemelas; si divergen, gana el test que falle.

---

## 12. Criterio de aceptación (manual)

Misma máquina, `flutter run`, usuario de prueba con lotes certificados.

1. Abrir Buscar. El hint habla de palabras clave, no de “nombre o usuario”.
2. Escribir `qui` → aparece `Quillay` (taxon). Elegirlo → chip. Hay perfiles o empty honesto.
3. Añadir `Lonquimay` → la lista se reduce (AND). Quitar chip → se amplia.
4. Pegar `quiero miel de ulmo` → no busca; sugiere `Ulmo`. Un tap busca.
5. `miel de ulmo` como chip único → no se rechaza.
6. Card muestra faceta (Polen / Comuna / Tipo), no email.
7. Tap → `ProfileViewScreen` del id correcto (regresión de paridad).
8. En web, los mismos 7 puntos.

---

## 13. Riesgos

| Riesgo | Mitigación |
|--------|------------|
| `ilike` sobre `composicion` lento | Solo ids candidatos; SLO K7; trgm después |
| `datos_certificado` JSON no filtrable en PostgREST | Extraer polen en Python sobre lotes ya filtrados por `composicion` / `nombre_miel` |
| RLS oculta lotes ajenos | Usar el mismo cliente/RPC que el perfil público de lotes (`GET /api/lotes/{id}`) |
| Nombres compuestos vs sentencias | Set A1–A6; no partir por espacios |
| `/sugerir` actual loguea PII | Fase 0 no imprime `contacts`; el endpoint nuevo tampoco |

---

## 14. Decisión pendiente (no bloquea el plan)

AND estricto vs “AND de geo + OR de taxones”. v1 es AND de todos los chips. Si K3 sube y K5 es alto, se evalúa OR dentro de la misma faceta en un seguimiento, no en este plan.
