# Plan: alineación del visor Flutter con el buscador por palabras clave

**Proyecto:** visor Flutter (`MeliAPP_Flutter`) + MeliAPP Cloud (`MeliAPP_v2`)
**Versión:** 1.1.0
**Estado:** EJECUTADO — fases F0 a F3 y F5 completadas; pendiente F4 (paridad en producción)
**Creado:** 1 septiembre 2026
**Sucede a:** `PLAN_BUSCADOR_PALABRAS_CLAVE.md` v1.0.0 (diseño previo a la implementación)
**Referencia Cloud:** `MeliAPP_v2` en `9ddb51a` (`148c`)

---

## 0. Estado de ejecución (1 septiembre 2026)

| Fase | Estado | Evidencia |
|---|---|---|
| F0 — API REST en Cloud | hecho | `148c`: `GET/POST /api/search/keywords`, `GET /api/search/suggest`, tronco común con `/buscar`, 22 tests nuevos |
| F0b — facetas temporada y clase botánica | **no ejecutada** | Decisión abierta; `primavera` y `arbol` siguen como categoría `libre` |
| F1 — modelos y servicio Flutter | hecho | `lib/models/search_models.dart`, `lib/services/keyword_search_service.dart` |
| F2 — interfaz de chips | hecho | `search_screen.dart` reescrita, `keyword_chip_field.dart`, `match_evidence_pills.dart` |
| F3 — baja de PII y del modelo embebido | hecho | `SearchResult` eliminado; la tarjeta ya no pide correo ni teléfono |
| F4 — paridad web-móvil en producción | **pendiente** | Requiere el despliegue de `148c` y la app instalada |
| F5 — cierre documental | hecho | Este documento |

Indicadores de proceso al cierre: P1 7/7, P2 2/2, P3 1 petición por consulta (debounce de 300 ms), P4 100 %, P5 0 campos PII, P6 sí, P7 0 por diseño, P8 3 archivos de test, P10 `flutter analyze` sin avisos.

Suites: **86 tests en Cloud** (`pytest tests/`) y **102 en Flutter** (`flutter test`), todas en verde.

---

## 1. Veredicto

El buscador por palabras clave **ya está implementado en Cloud y funciona**, pero **solo por la web**. El motor (`ApicolaSearch`) es alcanzable únicamente a través de `/buscar`, que responde HTML renderizado con Jinja. **No existe ningún endpoint JSON que devuelva perfiles apícolas.**

Por eso el visor Flutter no está "desactualizado": está **arquitectónicamente incapaz** de alcanzar paridad. Ninguna cantidad de trabajo en `search_screen.dart` cambia eso mientras el motor no tenga una salida JSON.

La corrección tiene dos tramos y un orden obligatorio:

1. **Cloud (bloqueante, pequeño):** exponer el motor existente como JSON. Sin lógica nueva de búsqueda.
2. **Flutter (grueso):** reescribir la capa de búsqueda para consumir ese contrato con chips, rechazo de frases y evidencia de coincidencia.

Se detectaron además dos facetas del diseño original que **no llegaron a implementarse en Cloud** (temporada y clase botánica). Se documentan como trabajo explícito, no como supuesto.

---

## 2. Estado verificado (1 septiembre 2026)

### 2.1 Cloud — qué existe hoy

| Componente | Archivo | Qué hace |
|---|---|---|
| Parser | `services/keyword_parser.py` | `normalize`, `looks_like_sentence`, `extract_keywords`, `parse_query`, `parse_keyword_list`. Máximo 5 palabras clave. |
| Catálogo | `services/search_catalog.py` | Carga `data/clases.csv` (comuna, región, nombre común, científico, clase) + términos estáticos. `suggest_terms`, `popular_terms`, `comunas_for_term`. |
| Motor | `services/apicola_search.py` | `ApicolaSearch`: snapshot con TTL 60 s, intersección AND entre palabras clave, puntaje por pesos, `matches[]` con evidencia. |
| Rutas | `routes/searcher_routes.py` | `/search` (HTML), `/buscar` (HTML), `/sugerir` (JSON). |
| UI web | `static/js/keyword-search.js` | Chips, debounce 250 ms, navegación con teclado, validación en servidor antes de crear el chip. |
| Tests | `tests/test_keyword_parser.py`, `tests/test_keyword_search.py`, `tests/test_apicola_search.py` | Parser, rutas y cliente inyectado. |

Catálogo real medido: **461 términos** — especie 204, tipo de miel 155, polen 152, lugar 39, apicultor 7 (un término puede tener varias categorías).

Categorías efectivamente implementadas (7): `apicultor`, `tipo_miel`, `polen`, `especie`, `lugar`, `zona`, `libre`.

Tablas consultadas por el motor: `info_contacto`, `usuarios`, `ubicaciones`, `origenes_botanicos`.

### 2.2 El contrato móvil quedó congelado a propósito

`GET /sugerir` tiene dos modos:

| Llamada | Respuesta | Consumidor |
|---|---|---|
| `/sugerir?q=ulmo` | `{suggestions: [{id, nombre, especialidad}]}` — solo personas | App móvil publicada |
| `/sugerir?modo=keywords&q=ulmo` | Veredicto del parser + `keywords[]` + `suggestions[]` del catálogo y de personas | Web |

El test `test_sugerir_default_keeps_mobile_contract` fija ese comportamiento. Fue una decisión correcta: las versiones instaladas no se rompen. Pero significa que **hoy el visor es un autocompletado de nombres**, sin acceso a especie, polen, tipo de miel ni lugar.

### 2.3 Flutter — qué hay hoy

`lib/screens/search_screen.dart` (459 líneas, todo en un archivo):

- Llama `GET /sugerir?q=` directamente en `onChanged`, **sin debounce**. Una consulta de 10 caracteres dispara 9 peticiones HTTP.
- Nunca envía `modo=keywords`, así que recibe el contrato legado.
- El modelo `SearchResult` vive dentro de la pantalla y declara 9 campos (`email`, `telefono`, `empresa`, `comuna`, `role`, …). El endpoint envía 3. Los seis restantes son siempre `null` y el bloque de contacto de la tarjeta es **código muerto**.
- Ese bloque pide `email` y `telefono`, que el diseño acordado clasifica como PII que no debe indexarse ni exponerse en resultados.
- No hay chips, ni AND entre términos, ni rechazo de frases, ni `matches[]`.
- `lib/config/api_config.dart` no declara ningún endpoint de búsqueda: la ruta está escrita a mano en la pantalla.
- `test/` no contiene ninguna prueba de búsqueda.

### 2.4 Brecha por faceta

Comparación de lo que cada cliente puede encontrar hoy:

| Faceta | Web | Flutter |
|---|---|---|
| Apicultor (nombre, empresa, usuario, rol) | sí | sí (solo nombre y empresa) |
| Tipo de miel (`nombre_miel`, monofloral, `miel de X`) | sí | no |
| Polen (composición certificada, `polen de X`) | sí | no |
| Especie (nombre común y científico) | sí | no |
| Lugar (comuna, región, apiario) | sí | no |
| Flora de zona (especie → comunas del CSV) | sí | no |
| Palabra libre | sí | no |
| Rechazo de frases con sugerencias | sí | no |
| Evidencia de coincidencia (`matches[]`) | sí | no |

**Cobertura del visor: 1 de 7 categorías, y de forma parcial.**

---

## 3. Causa raíz

No es la interfaz. Son tres decisiones de acoplamiento:

1. **El motor no tiene salida JSON.** `/buscar` devuelve una página. La lógica y la presentación quedaron unidas.
2. **El cliente móvil se preservó congelando el endpoint**, no versionándolo. La compatibilidad se logró dejando a la app fuera de la funcionalidad nueva.
3. **El visor duplica el contrato en la pantalla.** Sin modelo ni servicio propios, no hay dónde escribir una prueba que hubiera detectado que seis campos dejaron de llegar.

---

## 4. Divergencias respecto al plan v1.0 (ratificar antes de codificar)

El plan anterior describía un diseño; la implementación tomó otras decisiones. Se documentan para que el plan nuevo describa la realidad, no la intención.

| Tema | Plan v1.0 | Implementación real | Propuesta |
|---|---|---|---|
| Nombres de faceta | 8: persona, rol, geo, tipo_miel, polen, taxon, temporada, clase_botanica | 7: apicultor, tipo_miel, polen, especie, lugar, zona, libre | **Adoptar los nombres reales.** Flutter no inventa nombres propios. |
| Persona y rol | facetas separadas | fusionadas en `apicultor` | Aceptar la fusión. |
| Parser en el cliente | espejo Python + Dart, casos gemelos | la web no reimplementa: valida contra `/sugerir` | **Adoptar servidor autoritativo.** Ver sección 5. |
| Endpoints | `/api/search/keyword-suggest` y `/api/search/keywords` | solo `/sugerir?modo=keywords` | Reutilizar `/sugerir?modo=keywords` para sugerir; **crear solo el endpoint de búsqueda**. |
| Faceta temporada | prevista | **no implementada** | Ver 6.2. |
| Faceta clase botánica | prevista | **no implementada** | Ver 6.2. |
| Corte de resultados | AND estricto | AND estricto (`_intersect_ids`) | Sin cambio. |

---

## 5. Principio de corrección: el servidor es la autoridad

El plan v1.0 pedía un parser espejo en Dart. **Se descarta.** Un parser duplicado en dos lenguajes deriva en silencio: la lista `SENTENCE_VERBS` tiene 40 entradas, `STOPWORDS` 50 y el catálogo se genera desde un CSV que cambia. Mantener dos copias sincronizadas cuesta más que la latencia que ahorra.

La regla queda:

- **El veredicto de "esto es una frase" y la categoría de cada chip los da el servidor**, igual que en la web.
- Flutter conserva solo guardas locales baratas y no ambiguas: mínimo 2 caracteres, máximo 5 chips, sin duplicados, mensaje sin conexión.
- Si el servidor no responde, el borrador se acepta como chip `libre` (mismo comportamiento que el `catch` de `keyword-search.js`), nunca se bloquea al usuario por un fallo de red.

Beneficio medible: el indicador P7 (divergencia de veredicto entre cliente y servidor) queda estructuralmente en cero en vez de ser algo que hay que vigilar.

---

## 6. Trabajo en Cloud (bloqueante)

### 6.1 Endpoint JSON de búsqueda (F0)

Es la única pieza que falta para desbloquear a Flutter. `search_bp` ya monta bajo `url_prefix='/api'`, así que la ruta nace en el espacio correcto.

```
GET /api/search/keywords?k=ulmo&k=valdivia&limit=20
```

Alternativa equivalente para chips con categoría ya resuelta:

```
POST /api/search/keywords
{ "keywords": [ {"term": "Ulmo", "category": "especie"} ] }
```

Respuesta correcta (200):

```
{
  "ok": true,
  "query_type": "keyword",
  "keywords": [ {"term": "Ulmo", "normalized": "ulmo", "category": "especie", "label": "Especie"} ],
  "count": 3,
  "results": [
    {
      "auth_user_id": "…",
      "nombre": "…",
      "nombre_empresa": "…",
      "username": "…",
      "role": "Apicultor",
      "comuna": "Valdivia",
      "region": "Los Ríos",
      "score": 8,
      "matches": [
        {"category": "polen", "term": "ulmo", "evidence": "Ulmo (62%)",
         "confidence": "certified_pollen", "label": "Polen"}
      ]
    }
  ]
}
```

Respuesta rechazada (400):

```
{ "ok": false, "query_type": "sentence", "reason": "…",
  "keywords": [], "suggestions": [ … ] }
```

Implementación: reutilizar `_parse_search_request()` / `parse_keyword_list()` y `searcher.search_apicola_profiles()`. **Cero lógica de búsqueda nueva.** El cuerpo del handler es esencialmente el de `buscar()` cambiando `render_template` por `jsonify`.

Refactor recomendado en la misma fase: extraer el tronco común de `buscar()` a una función que devuelva `(parsed, resultados, error)` y que las dos rutas (HTML y JSON) la consuman. Así la paridad web-móvil deja de depender de disciplina y pasa a ser estructural.

**Regla de privacidad:** el serializador JSON expone exactamente los campos del índice de perfil (`_profile_index`). No se añaden `email`, `telefono`, `rut`, `registro_sag` ni `direccion`.

### 6.2 Facetas faltantes (F0b, puede ir después de F1)

Verificado ejecutando el parser contra el catálogo real:

- `parse_query('primavera')` devuelve categoría `libre`, no `temporada`. La columna `temporada` se lee en `PUBLIC_LOTE_COLS` pero `_match_honey_and_pollen` solo compara contra `nombre_miel` y `composicion`; `temporada` se usa únicamente para decorar la evidencia. **Buscar "primavera" nunca encuentra un lote cuya temporada es Primavera.**
- `parse_query('arbol')` devuelve `libre`. La columna `Clase` del CSV se lee, pero solo para añadir alias de miel y polen a los árboles; nunca se registra como término buscable.

Corrección propuesta (pequeña, en Cloud):

1. `search_catalog`: registrar las cuatro estaciones y los valores distintos de `Clase` como términos con categoría `temporada` y `clase_botanica`.
2. `apicola_search`: comparar `temporada` en `_match_honey_and_pollen` y resolver clase botánica vía especie → clase.
3. `WEIGHTS` y `CATEGORY_LABELS`: añadir ambas categorías.

**Si esto no se hace, el plan sigue siendo válido**, pero los indicadores de cobertura se calculan sobre 7 categorías, no 9. Decisión explícita, no omisión.

---

## 7. Trabajo en Flutter

### 7.1 Archivos

| Archivo | Acción | Contenido |
|---|---|---|
| `lib/models/search_models.dart` | nuevo | `KeywordChip`, `SearchMatch`, `ApicolaProfile`, `SuggestResponse`. Serialización pura, sin Flutter. |
| `lib/services/keyword_search_service.dart` | nuevo | `suggest(String q)` → `/sugerir?modo=keywords`; `search(List<KeywordChip>)` → `/api/search/keywords`. Debounce y cancelación de peticiones en vuelo. |
| `lib/config/api_config.dart` | editar | Declarar `sugerirEndpoint` y `keywordSearchEndpoint`. Se acaban las rutas escritas a mano. |
| `lib/screens/search_screen.dart` | reescribir | Solo presentación. `SearchResult` desaparece de aquí. |
| `lib/widgets/keyword_chip_field.dart` | nuevo | Campo con chips, borrado con retroceso, límite de 5. |
| `lib/widgets/match_evidence_pills.dart` | nuevo | Pills de `matches[]` con el mismo código de color que la web. |
| `test/models/search_models_test.dart` | nuevo | Fixtures JSON capturados del servidor real. |
| `test/services/keyword_search_service_test.dart` | nuevo | Debounce, rechazo, degradación sin red. |
| `test/widgets/keyword_chip_field_test.dart` | nuevo | Alta y baja de chips, tope de 5. |

### 7.2 UX (espejo de `keyword-search.js`)

1. Campo único. Sugerencia: `Ej: ulmo, Valdivia, polen de tineo` — el mismo texto que la web.
2. Debounce **300 ms** antes de pedir sugerencias; nada por debajo de 2 caracteres.
3. Enter o coma confirma el borrador como chip, validando primero contra el servidor.
4. Chips bajo el campo, con `x` para quitar. Retroceso con campo vacío borra el último. Al cambiar los chips se relanza la búsqueda.
5. Sugerencias mezcladas: términos del catálogo y personas. Tocar una persona (`item.id` presente y categoría `apicultor`) navega directo al perfil, igual que hace la web con `window.location.href`.
6. Frase detectada: banner con `reason` del servidor, el borrador no se convierte en chip, y las `suggestions[]` se ofrecen para un toque.
7. Resultados: nombre, rol, comuna y región, empresa, y hasta 4 pills de evidencia. **Sin correo ni teléfono.**
8. Estado inicial: chips de `popular_terms()` (Ulmo, Tineo, Avellano, Valdivia, Apicultor, Polen). No buscan solos.
9. Toque en resultado → `Navigator.pushNamed('/profile', arguments: auth_user_id)`, que ya existe en `main.dart`.

---

## 8. Fases

| Fase | Repo | Entrega | Señal de salida | Esfuerzo |
|---|---|---|---|---|
| F0 | Cloud | `GET/POST /api/search/keywords` + refactor del tronco común + tests | Test de contrato JSON verde; `/buscar` sigue igual | 0.5 d |
| F0b | Cloud | Facetas `temporada` y `clase_botanica` | `primavera` y `arbol` dejan de ser `libre` | 0.5 d |
| F1 | Flutter | Modelos + servicio + endpoints en `ApiConfig` | Deserializa fixtures reales; P1 y P2 en verde | 0.5 d |
| F2 | Flutter | Campo de chips, debounce, banner de rechazo, pills | Lista de comprobación de la sección 11 | 1.5 d |
| F3 | Flutter | Baja de PII y del modelo embebido | P5 y P6 en verde; `flutter analyze` limpio | 0.5 d |
| F4 | ambos | Paridad: mismo conjunto de casos en web y visor | R1, R2 y R3 en verde | 0.5 d |
| F5 | ambos | Instrumentación, CHANGELOG, cierre de planes | Indicadores K definidos y emitiendo | 0.5 d |

**Orden obligatorio:** F0 antes que F1. F2 no arranca sin F1 verde. F0b puede solaparse con F1 y F2.

**Total: 4 a 4.5 días efectivos.** F0b es opcional y añade 0.5 d.

Este trabajo no se mezcla con `PLAN_PLAY_STORE.md` ni con la edición de lotes. Si hay que publicar antes de F2, se publica el visor actual: funciona, solo que limitado a nombres.

---

## 9. Indicadores y métricas

Cuatro capas separadas. No se colapsan en una sola "tasa de éxito".

### 9.1 Proceso (P) — se miden en el repositorio y en CI

Estos son los indicadores del trabajo, no del usuario. Se revisan al cerrar cada fase.

| ID | Indicador | Cómo se mide | Baseline (1 sep) | Objetivo | Fase |
|---|---|---|---|---|---|
| P1 | Categorías consultables desde el visor | Categorías que el cliente puede enviar y renderizar | 1 / 7 | 7 / 7 | F1–F2 |
| P2 | Endpoints JSON del motor | Rutas que devuelven perfiles o veredicto en JSON | 1 / 2 (falta búsqueda) | 2 / 2 | F0 |
| P3 | Peticiones HTTP por consulta de 10 caracteres | Contador en prueba de widget con debounce simulado | 9 | ≤ 3 | F2 |
| P4 | Campos del modelo que el servidor realmente envía | Campos declarados vs campos presentes en la respuesta | 3 / 9 (33 %) | 100 % | F1 |
| P5 | Campos PII solicitados por el cliente | Referencias a `email`, `telefono` en la pantalla de búsqueda | 2 | 0 | F3 |
| P6 | Contrato fuera de la capa de presentación | `SearchResult` definido en `lib/models/` | no | sí | F1 |
| P7 | Divergencia de veredicto cliente-servidor | Parser duplicado en Dart | riesgo abierto | 0 por diseño (sección 5) | F1 |
| P8 | Pruebas de búsqueda en el visor | Archivos en `test/` que cubren búsqueda | 0 | ≥ 3 archivos | F1–F2 |
| P9 | Cobertura de líneas del servicio y los modelos | `flutter test --coverage` sobre los archivos nuevos | 0 % | ≥ 85 % | F3 |
| P10 | `flutter analyze` | Avisos nuevos introducidos | — | 0 | F3 |

### 9.2 Paridad web-móvil (R) — la métrica que define "alineado"

Se ejecuta el mismo conjunto de casos contra el mismo entorno, en la web y en el visor, y se comparan las respuestas. Esto es lo que el usuario pidió: que la app quede alineada.

| ID | Indicador | Definición | Objetivo | Fase |
|---|---|---|---|---|
| R1 | Identidad de resultados | Perfiles del top 10 idénticos y en el mismo orden entre `/buscar` y `/api/search/keywords` para los 14 casos de 10.1 | 14 / 14 | F4 |
| R2 | Identidad de veredicto | Mismo `query_type` y mismo `reason` para los casos de rechazo de 10.2 | 4 / 4 | F4 |
| R3 | Identidad de evidencia | Mismas `matches[].category` y `matches[].evidence` en los 3 primeros perfiles | 100 % | F4 |
| R4 | Deriva de vocabulario | Etiquetas de categoría escritas a mano en Dart en lugar de tomadas de `label` del servidor | 0 | F2 |

R1 y R2 se automatizan con un script que golpea ambos endpoints y compara; no es inspección visual.

### 9.3 Motor y datos (Q) — límites reales ya presentes en Cloud

Estos no los introduce este plan; los hereda. Se miden porque afectan a lo que el visor mostrará.

| ID | Indicador | Estado actual | Umbral de alarma | Acción si se cruza |
|---|---|---|---|---|
| Q1 | Falso rechazo sobre el catálogo | **0 de 461 términos** (verificado ejecutando `looks_like_sentence` sobre todos los `display` del catálogo) | > 0 | Revisar `SENTENCE_VERBS` |
| Q2 | Cobertura del snapshot | `SNAPSHOT_LIMIT = 1000` filas por tabla | filas reales > 800 en cualquier tabla | Paginar o mover el filtro a la consulta |
| Q3 | Frescura del índice | `CACHE_TTL_SECONDS = 60` | reclamos por lote nuevo no encontrado | Invalidar caché al crear lote |
| Q4 | Tamaño del catálogo de lugares | 39 términos (solo comunas y regiones presentes en `clases.csv`) | consultas de comuna sin resultado | Cargar el listado completo de comunas |
| Q5 | Latencia p95 de `/api/search/keywords` | sin medir (no existe) | > 400 ms | Índices `pg_trgm`, no antes |

Q1 es el resultado empírico más tranquilizador del análisis: el detector de frases **no** rompe ningún término real del catálogo, incluidos nombres compuestos como `Los Lagos` y binomios científicos como `Quillaja saponaria`.

Q2 es el riesgo silencioso más serio: por encima de 1000 filas la búsqueda deja de encontrar perfiles **sin ningún error visible**.

### 9.4 Producto (K) — 14 días después de publicar

Eventos a emitir, sin texto libre cuando el veredicto es rechazo: `keyword_count`, `categories[]`, `rejected`, `result_count`, `latency_ms`, `source` (`web` o `mobile`).

| ID | Indicador | Objetivo | Lectura si se sale del rango |
|---|---|---|---|
| K1 | Tasa de rechazo de frases en móvil | 5 % a 25 % | Por encima de 40 %: detector agresivo. Cerca de 0 %: la validación no se está llamando. |
| K2 | Chips creados desde sugerencia | ≥ 40 % | Catálogo poco relevante o lista de sugerencias poco visible |
| K3 | Búsquedas válidas con cero resultados | ≤ 30 % | Con K6 alto: faltan datos en lotes, no es fallo de interfaz |
| K4 | Conversión a perfil | ≥ 50 % | Tarjetas poco claras o `matches` vacíos |
| K5 | Búsquedas con 2 o más chips | ≥ 15 % | El AND no se entiende; revisar el estado inicial |
| K6 | Chip principal distinto de `apicultor` | ≥ 35 % | Sigue usándose como buscador de nombres: el trabajo no cambió el comportamiento |
| K7 | p95 de `/api/search/keywords` | ≤ 400 ms | Abrir índices, no antes |
| K8 | Peticiones de sugerencia por sesión móvil | ≤ 40 % del volumen actual | Debounce ausente o mal configurado |

**K6 es el indicador que decide si este trabajo valió la pena.** Todo lo demás puede estar en verde y, si K6 sigue bajo, el visor seguirá siendo en la práctica un buscador de nombres.

---

## 10. Conjunto de aceptación

Casos verificados contra el parser real. Los marcados con resultado observado ya se ejecutaron durante este análisis.

### 10.1 Deben aceptarse y buscar

| # | Entrada | Categoría observada hoy | Debe encontrar por |
|---|---|---|---|
| G1 | `ulmo` | `especie` | especie, polen certificado, flora de zona |
| G2 | `miel de ulmo` | `tipo_miel` | `nombre_miel` |
| G3 | `polen de tineo` | `polen` | composición certificada |
| G4 | `Valdivia` | `lugar` | comuna de contacto o de apiario |
| G5 | `apicultor` | `apicultor` | rol |
| G6 | `monofloral` | `tipo_miel` | denominación del lote |
| G7 | `Quillaja saponaria` | `especie` | nombre científico |
| G8 | `Los Lagos` | `lugar` | región (nombre compuesto, no se parte) |
| G9 | `Erika Poblete` | 2 chips `libre` | intersección sobre `nombre_completo` |
| G10 | `prestador de servicios` | 2 chips `libre` | `tipo_usuario` o `role` |
| G11 | `ulmo`, `Valdivia` | `especie` + `lugar` | AND: solo perfiles con ambos |
| G12 | `primavera` | `libre` — **pendiente F0b** | `temporada` del lote |
| G13 | `arbol` | `libre` — **pendiente F0b** | clase botánica de la especie |
| G14 | nombre exacto de `nombre_miel` de un lote de prueba | `libre` o `tipo_miel` | lote |

G12 y G13 **fallan hoy por diseño incompleto en Cloud**, no por el visor. Se excluyen de R1 si no se ejecuta F0b.

### 10.2 Deben rechazarse

| # | Entrada | Veredicto observado | Debe sugerir |
|---|---|---|---|
| S1 | `quiero miel de ulmo cerca de Valdivia` | `sentence` | Ulmo, Valdivia |
| S2 | `donde hay apicultores` | `sentence` | apicultor |
| S3 | `qué mieles monoflorales hay cerca` | `sentence` | monofloral |
| S4 | `necesito encontrar un apicultor` | `sentence` | apicultor |

### 10.3 Guardas del cliente (sin red)

| # | Situación | Comportamiento esperado |
|---|---|---|
| C1 | Sexto chip | Mensaje de tope, no se añade |
| C2 | Chip duplicado | Se ignora en silencio |
| C3 | Un carácter | No se pide sugerencia |
| C4 | Servidor caído al confirmar chip | Se acepta como `libre`, no se bloquea |
| C5 | Servidor caído al buscar | Mensaje de error, chips intactos |

---

## 11. Lista de comprobación manual

Misma máquina, `flutter run`, cuenta de prueba con lotes certificados.

1. Abrir Buscar. La sugerencia del campo menciona palabras clave y da ejemplos, no dice "nombre o usuario".
2. Escribir `ulm` y esperar. Llega **una** petición, no tres. Aparece `Ulmo` etiquetado como Especie.
3. Tocar `Ulmo`. Se convierte en chip. Aparecen perfiles con pill de Polen o Especie.
4. Añadir `Valdivia`. La lista se reduce. Quitar el chip la amplía de nuevo.
5. Pegar `quiero miel de ulmo cerca de Valdivia`. No busca. Aparece el motivo y se ofrecen `Ulmo` y `Valdivia`. Un toque los convierte en chips.
6. Escribir `miel de ulmo` y confirmar. **No se rechaza**, entra como un solo chip de Tipo de miel.
7. Ninguna tarjeta muestra correo ni teléfono.
8. Tocar una tarjeta abre el perfil correcto.
9. Escribir el nombre de una persona: aparece en sugerencias con su especialidad y tocarla va directo al perfil, sin crear chip.
10. Activar modo avión y confirmar un chip: no se bloquea la interfaz.
11. Repetir los puntos 2 a 8 en meliapp.cl y comparar resultado por resultado.

---

## 12. Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Se implementa Flutter antes que el endpoint JSON | media | alto: retrabajo completo | Orden de fases explícito; F1 no arranca sin F0 |
| El snapshot de 1000 filas oculta perfiles sin avisar | media | alto: resultados falsamente vacíos | Q2 con umbral en 800 filas |
| La web y el visor divergen otra vez | alta a largo plazo | medio | Tronco común en Cloud (F0) e indicador R4 |
| Nombres largos consumen los 5 chips | baja | bajo | G9 y G10 en el conjunto de aceptación |
| Versiones antiguas de la app en Play Store | cierta | bajo | El contrato por defecto de `/sugerir` no se toca nunca |
| Catálogo de lugares con solo 39 términos | alta | medio | Q4; ampliar desde el listado oficial de comunas |
| F0b se pospone y se olvida | media | bajo | G12 y G13 quedan marcados como fallo conocido, no se borran |

---

## 13. Decisiones pendientes

1. **¿Se ejecuta F0b?** Sin ella el objetivo de cobertura es 7 categorías; con ella, 9. No bloquea nada más.
2. **¿`GET` con `k` repetido o `POST` con cuerpo?** `GET` es cacheable y se comparte por enlace; `POST` evita el límite de longitud de URL. Recomendación: implementar `GET` y añadir `POST` solo si aparece un caso real de URL larga.
3. **¿El visor guarda búsquedas recientes?** Fuera de alcance en esta versión. Si se añade, se almacenan chips, nunca texto libre.
4. **¿Se amplía el catálogo de comunas ahora o después?** Afecta a Q4 y a la percepción de K3.

---

## 14. Relación con otros planes

- `PLAN_BUSCADOR_PALABRAS_CLAVE.md` — diseño original. Conviene marcarlo como **superado en su parte de implementación**; sus secciones de gramática y privacidad siguen vigentes y este plan las respeta.
- `PLAN_PARIDAD_VISOR_CLOUD.md` — el destino canónico sigue siendo el perfil (`auth_user_id`). Este plan solo cambia cómo se llega allí.
- `PLAN_PLAY_STORE.md` — independiente. No se bloquea la publicación por este trabajo.
