# Informe: fallo de GitHub Actions "Flutter CI"

**Repositorio:** `Nahzap/MeliAPP_Flutter` (rama `main`)
**Fecha del análisis:** martes 1 de septiembre de 2026
**Hora de inicio:** 11:53 hrs (UTC-04:00)
**Hora de cierre:** 12:04 hrs (UTC-04:00)
**Estado final:** RESUELTO y verificado — commit `42731d4` (`11c`)
**Notificación original:** "Flutter CI: All jobs have failed" — job `test`, falló en 1 min 33 s, 2 anotaciones

---

## 1. Resumen ejecutivo

El pipeline falló por **dos problemas independientes**, no por uno.

El visible era de formato: `dart format` rechazó 4 archivos del commit `9c`. El grave estaba oculto detrás: **30 archivos de código y pruebas existían solo en tu computador y nunca se habían subido a GitHub**. El repositorio remoto era una copia incompleta de la aplicación.

Ambos quedaron corregidos en el commit `11c`. Lo verifiqué clonando el repositorio desde cero y ejecutando los cinco pasos del pipeline: todos pasan.

---

## 2. Qué hace el pipeline

Definido en `.github/workflows/flutter.yml`, se dispara con cada `push` a `main` o `develop`. Corre en Ubuntu con Flutter 3.35.7, la misma versión que tienes instalada, así que sus resultados son reproducibles localmente.

| # | Paso | Comando |
|---|---|---|
| 1 | Dependencias | `flutter pub get` |
| 2 | Formato | `dart format --output=none --set-exit-if-changed .` |
| 3 | Análisis | `flutter analyze` |
| 4 | Pruebas | `flutter test` |
| 5 | Compilación Android | `flutter build apk --debug` |
| 6 | Compilación web | `flutter build web` |

El paso 2 es el que suele sorprender: **no revisa que el código funcione, revisa que esté formateado**. Si un solo archivo tiene un espacio distinto al que `dart format` produciría, el job entero se marca en rojo aunque la aplicación compile y todas las pruebas pasen.

---

## 3. Causa 1: formato (la que se veía)

Reproduje el paso 2 en tu máquina antes de tocar nada:

```
Changed lib\screens\search_screen.dart
Changed lib\services\keyword_search_service.dart
Changed test\services\keyword_search_service_test.dart
Changed test\widgets\keyword_chip_field_test.dart
Formatted 62 files (4 changed) in 1.07 seconds.
EXITCODE=1
```

Los cuatro archivos son del commit `9c` (el buscador por palabras clave). Ninguno tenía un error real: solo diferencias de saltos de línea y sangría respecto a lo que `dart format` impone.

Dato relevante: los otros 58 archivos del proyecto pasaron limpios. Es decir, **el repositorio estaba correctamente formateado antes y fue mi commit el que rompió ese paso**.

---

## 4. Causa 2: archivos que nunca llegaron a GitHub (la grave)

Al preparar la corrección detecté que una gran cantidad de archivos figuraban como *sin trackear* en git. Eso significa que existían en tu disco, la aplicación compilaba localmente con ellos, pero **GitHub nunca los recibió**.

Eran **30 archivos**: 16 de código y 14 de pruebas.

### Código ausente en el remoto

```
lib/config/register_messages.dart
lib/config/self_service_tipos.dart
lib/models/oauth_callback.dart
lib/models/species_name.dart
lib/models/ubicacion_model.dart
lib/screens/lotes/certificado_document_screen.dart
lib/screens/profile_view_screen.dart
lib/services/botanical_service.dart
lib/services/certificado_builder.dart
lib/services/oauth_loopback.dart
lib/services/taxa_service.dart
lib/widgets/certificado_html_view.dart
lib/widgets/formal_catalog_table.dart
lib/widgets/google_sign_in_button.dart
lib/widgets/species_catalog_table.dart
lib/widgets/species_name_text.dart
```

### Pruebas ausentes en el remoto

```
test/config/api_config_test.dart
test/config/register_messages_test.dart
test/config/self_service_tipos_test.dart
test/models/api_models_test.dart
test/models/lote_model_test.dart
test/models/species_name_test.dart
test/models/user_model_test.dart
test/services/certificado_builder_test.dart
test/services/oauth_callback_test.dart
test/services/qr_service_test.dart
test/services/taxa_catalog_test.dart
test/widgets/certificado_html_view_test.dart
test/widgets/composition_pie_chart_test.dart
test/widgets/formal_catalog_table_test.dart
```

### Por qué esto importa más que el formato

Entre los archivos ausentes está `lib/screens/profile_view_screen.dart`, que es la pantalla de perfil a la que navega el buscador. También faltaban el generador de certificados, el servicio de taxones y el botón de inicio de sesión con Google.

Las consecuencias reales eran tres:

1. **El respaldo era falso.** Si perdías el equipo, perdías esos 30 archivos. GitHub no los tenía.
2. **Nadie más podía compilar el proyecto.** Un clon del repositorio no habría producido la aplicación que tú ves.
3. **CI medía una aplicación que no existe.** Aunque hubiera pasado en verde, no habría estado verificando tu app real.

Es el tipo de problema que no molesta mientras trabajas en un solo computador, y que se vuelve crítico exactamente el día que lo necesitas.

---

## 5. Corrección aplicada

**Commit `11c` — `42731d4`** (`df9b7ec..42731d4`)

| Acción | Alcance |
|---|---|
| Reformatear con `dart format .` | 4 archivos |
| Subir los archivos ausentes | 30 archivos nuevos |
| Actualizar archivos ya trackeados | 21 archivos |

---

## 6. Verificación

No me quedé en "pasa en mi máquina". Cloné el repositorio remoto en un directorio limpio y ejecuté los cinco pasos del pipeline sobre ese clon, que es exactamente lo que hace GitHub Actions.

Clon de `42731d4` desde `https://github.com/Nahzap/MeliAPP_Flutter.git`:

| # | Paso | Resultado |
|---|---|---|
| 1 | `flutter pub get` | 39 dependencias resueltas |
| 2 | `dart format --set-exit-if-changed` | `62 files (0 changed)` — salida 0 |
| 3 | `flutter analyze` | `No issues found!` |
| 4 | `flutter test` | `102 tests passed` |
| 5 | `flutter build apk --debug` | `Built app-debug.apk` (216 s) |
| 6 | `flutter build web` | `Built build\web` (31 s) |

Los seis pasos en verde. El directorio temporal se eliminó tras la comprobación.

**Limitación honesta:** no pude consultar los registros del run fallido en GitHub porque `gh` no tiene sesión iniciada en este equipo (`gh auth login`). El diagnóstico proviene de reproducir el pipeline localmente, no de leer los logs de Actions. La reproducción del paso 2 fue idéntica al fallo, y la verificación sobre el clon limpio es concluyente, pero conviene confirmar el resultado en la interfaz de GitHub.

---

## 7. Qué hacer ahora

1. Entrar a la pestaña **Actions** del repositorio y confirmar que el run de `11c` (`42731d4`) aparece en verde.
2. Si sigue en rojo, abrir el job `test` y decirme en qué paso se detiene. Con eso lo cierro.

Esto es independiente de la subida a Play Console: el `.aab` de tu Escritorio ya está compilado y firmado, y no depende de que CI esté en verde.

---

## 8. Cómo evitar que se repita

### Formato antes de commitear

Un solo comando previene el fallo del paso 2:

```bash
dart format .
```

Conviene ejecutarlo junto con las pruebas antes de cada push:

```bash
dart format . ; flutter analyze ; flutter test
```

### Detectar archivos sin subir

Este es el hábito que faltaba. Antes de dar por cerrada una sesión de trabajo:

```bash
git status --short
```

Las líneas que empiezan con `??` son archivos que **solo existen en tu computador**. Si alguna es código de la aplicación, no está respaldada.

### Recomendación de fondo

Al commitear, `git add -A` sobre las carpetas de código evita dejar archivos fuera. La alternativa que veníamos usando, nombrar archivo por archivo, es la que permitió que 30 quedaran atrás sin que nadie lo notara durante varios commits.

---

## 9. Estado del trabajo del buscador

Este fallo de CI es ajeno a la funcionalidad: no había ningún error de código. Para dejar constancia del estado real:

| Componente | Estado |
|---|---|
| API REST en Cloud (`148c`) | Desplegada y respondiendo 200 en producción |
| Visor Flutter (`9c`, `10c`, `11c`) | Completo, 102 pruebas en verde |
| Artefacto para Play Console | `MeliAPP-1.0.6-vc8.aab`, firmado, en el Escritorio |
| Pipeline CI | Verificado sobre clon limpio |
| Facetas temporada y clase botánica | Pendientes (fase F0b, decisión abierta) |
