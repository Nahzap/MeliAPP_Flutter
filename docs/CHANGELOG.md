# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

---

## [2.0.9] - 1 Diciembre 2025

### 🔌 Endpoint de Consulta de Perfiles Públicos

**Autor**: Rodrigo Jofré Cerda

#### 🌐 Backend: Nuevo Endpoint `/api/profile/<user_id>`
- ✅ **Consulta de información pública de usuarios**
  - Endpoint: `GET /api/profile/{user_id}`
  - Permite consultar datos de contacto de otros usuarios
  - Campos: nombre completo, empresa, email, teléfono, ubicación
  - Soporta UUID completo o segmento de 8 caracteres
  - **Crítico para contacto entre apicultores**

#### 📱 Integración Flutter Completa
- ✅ **ApiService.getUserById()**
  - Consume endpoint `/api/profile/{user_id}`
  - Retorna User model completo
  - Manejo de errores robusto

- ✅ **LotesListScreen con info de usuario**
  - Carga automática de perfil del productor
  - Card elegante con datos de contacto
  - Aparece sobre el gráfico polínico
  - UX profesional y funcional

#### 🔒 Seguridad y Privacidad
- ✅ **Solo datos públicos**
  - Nombre, empresa, ubicación
  - Email y teléfono (necesarios para contacto comercial)
  - NO expone datos sensibles (passwords, sesiones)
  - Permite comunicación entre usuarios de la plataforma

---

## [2.0.8] - 1 Diciembre 2025

### 🎨 Correcciones Críticas de UI/UX

**Autor**: Rodrigo Jofré Cerda

#### 🏠 Logo Colmena en LoginScreen
- ✅ **Logo QR reemplazado por colmena.png**
  - Antes: Ícono QR code feo
  - Ahora: Logo colmena.png elegante
  - Tamaño: 100x100px con padding
  - Consistente con SplashScreen

#### 👤 Info de Contacto en Lotes de Otros Usuarios
- ✅ **Header con información completa**
  - Aparece sobre el gráfico polínico
  - Muestra: Nombre completo, Empresa, Email, Teléfono, Ubicación
  - Ícono apicultor.png destacado
  - Card con gradiente suave y bordes elegantes
  - Diseño con fondo blanco para los campos de contacto
  - Crítico para identificación y contacto de productores

#### 🎨 Diseño HomeScreen Mejorado
- ✅ **Contraste optimizado**
  - Antes: Fondo naranja con campos naranja (ilegible)
  - Ahora: Fondo naranja con campos BLANCOS sólidos
  - Sombras sutiles para profundidad
  - Texto gris oscuro (mejor legibilidad)
  - Iconos gris 600 (profesional)
  - Armonioso y elegante

#### 🔧 Arquitectura
- ✅ **Método ApiService.getUserById()**
  - Endpoint: `/api/profile/{userId}`
  - Obtiene info completa de usuario
  - Usado en LotesListScreen

---

## [2.0.7] - 1 Diciembre 2025

### 🔧 Ajustes Finales de UX y Tamaños

**Autor**: Rodrigo Jofré Cerda

#### 📏 Ajustes de Tamaño
- ✅ **Icono honey02 aumentado 70%**
  - Antes: 40x40px
  - Ahora: 68x68px
  - Medalla emoji aumentada a 28px
  - Mucho más visible e impactante

- ✅ **Gráfico polínico aumentado 20%**
  - Antes: 200px
  - Ahora: 240px (200 * 1.2)
  - Mejor visibilidad de porcentajes
  - Layout horizontal sigue funcionando perfecto

#### 🏷️ Correcciones de Texto
- ✅ **Título corregido: "Top 3 Lotes"**
  - Antes: "Top 3 Productores" (incorrecto)
  - Ahora: "Top 3 Lotes" (correcto)
  - Refleja correctamente que son lotes, no personas

#### 🖱️ Interactividad Mejorada
- ✅ **TOP 3 clickeable**
  - InkWell wrapper con onTap
  - Navega a detalle del lote
  - Importante para acceso rápido en listas grandes
  - Ejemplo: 9999 lotes → TOP 3 accesible fácilmente

#### 📐 Espacio Horizontal Optimizado
- ✅ **Lista de especies redimensionada**
  - Row con gráfico (240px) + Expanded leyenda
  - Lista vertical ocupa menos espacio horizontal
  - Mejor balance visual

---

## [2.0.6] - 1 Diciembre 2025

### 🎨 Iconografía Custom y UX Profesional

**Autor**: Rodrigo Jofré Cerda

#### 🌟 Logo e Identidad Visual
- ✅ **Logo principal cambiado a colmena.png**
  - Splash screen con icono de colmena (antes: QR code feo)
  - Título simplificado a "MeliAPP"
  - Subtítulo: "Sistema Profesional de Análisis Polínico"
  - Color blanco sobre fondo amber

#### 📊 Rediseño de Gráfico Polínico
- ✅ **Gráfico al LADO de la leyenda** (layout horizontal)
  - Antes: Gráfico arriba, lista abajo
  - Ahora: Gráfico izquierda (200px), leyenda derecha (expandida)
  - Mejor aprovechamiento del espacio
  - Diseño más profesional y armonioso

#### 🏆 Iconos Custom en Ranking TOP 3
- ✅ **honey02.png con medalla encima**
  - Stack con icono de miel + emoji medalla (🥇🥈🥉)
  - Coloreado según posición (oro/plata/cobre)
  - Diseño único como imagen compuesta

#### 👤 Información Completa de Usuario
- ✅ **HomeScreen expandido con TODOS los campos**
  - **Sobre mí:** Username, Rol, Estado
  - **Información de Contacto:** Nombre Completo, Empresa, Email, Teléfono, Ubicación
  - Usa datos de `usuarios` + `info_contacto` (completo)
  - Icono custom `apiario01.png` para ubicación

#### 🔍 SearchScreen con Info de Contacto
- ✅ **Resultados de búsqueda expandidos**
  - Avatar con `apicultor.png` (icono custom)
  - Rol del usuario (PROVEEDOR/PRODUCTOR)
  - Empresa, Email, Teléfono, Comuna (si disponible)
  - Layout vertical con divider y sección de contacto
  - Mejor identificación para contactar apicultores

#### 🎨 Iconografía Aplicada
```
✅ colmena.png     → Logo principal (splash)
✅ apicultor.png   → Usuarios apicultores
✅ apiario01.png   → Ubicación/comuna
✅ honey02.png     → TOP 3 (con medalla encima)
📋 honey01.png     → Lotes individuales (pendiente)
📋 leaf01.png      → Secciones info (pendiente)
📋 bee01-03.png    → Adornos (pendiente)
📋 pollen01-03.png → Adornos (pendiente)
```

#### 📐 Arquitectura de Assets
- Carpeta `MeliAPP_icons/` agregada a `pubspec.yaml`
- Soporte para Image.asset() en toda la app
- Coloreado dinámico con parámetro `color:`

---

## [2.0.5] - 1 Diciembre 2025

### 🏆 Diseño Premium y Ranking TOP 3

**Autor**: Rodrigo Jofré Cerda

#### 🎨 Mejoras de Diseño Visual
- ✅ **Leyenda de especies rediseñada**
  - Lista vertical ordenada (antes: horizontal desordenada)
  - Cards individuales con bordes y fondos
  - Spacing armonioso entre elementos
  - Porcentajes con color de la especie
  - Diseño elegante y profesional

#### 🏆 Ranking TOP 3 de Producción
- ✅ **Nueva sección entre gráfico y resumen**
  - Muestra los 3 lotes con mayor producción
  - **Medallas emoji:** 🥇 Oro | 🥈 Plata | 🥉 Bronce
  - Gradientes de color según posición
  - Nombre del lote + orden + kg producidos
  - Badge con número de posición (#1, #2, #3)
  - Colores premium: #FFD700 (oro), #C0C0C0 (plata), #CD7F32 (cobre)

#### 📐 Jerarquía Visual Optimizada
```
┌─────────────────────────────────┐
│ 🌿 Composición Polínica Total   │
│    [Gráfico de anillo]          │
│    [Leyenda vertical elegante]  │ ← Rediseñado
├─────────────────────────────────┤
│ 🏆 Top 3 Productores            │ ← NUEVO
│    🥇 test7 - 7,897 kg          │
│    🥈 test4 - 4,999 kg          │
│    🥉 test8 - 3,434 kg          │
├─────────────────────────────────┤
│ 📊 Resumen de Producción        │
│    9 lotes | 25,391 kg          │
└─────────────────────────────────┘
```

---

## [2.0.4] - 1 Diciembre 2025

### 🌺 Visualización Polínica Empresarial

**Autor**: Rodrigo Jofré Cerda

#### 📊 Gráficos de Composición Polínica (Solicitud de Jefatura)
- ✅ **Gráfico consolidado en lista de lotes**
  - Muestra composición polínica total de TODOS los lotes del apicultor
  - Se calcula sumando porcentajes de todas las especies
  - Aparece PRIMERO en la pantalla (antes de scroll)
  - Diseño profesional con icono 🌿 y descripción
- ✅ **Gráfico movido al inicio en detalle de lote**
  - Composición polínica aparece justo después del header
  - Usuario ve análisis inmediatamente sin hacer scroll
  - Cumple con requisito de impresionar visualmente

#### 🚫 Eliminaciones UX
- ✅ **Botón "Nuevo Lote" eliminado completamente**
  - Removido FAB de lista de lotes
  - Removido botón "Crear Primer Lote" de empty state
  - App configurada solo para visualización
  - Mensaje: "Para crear/editar, usar plataforma web"

#### 🏷️ Mejoras de Navegación
- ✅ **Títulos dinámicos según contexto**
  - "Mis Lotes" → cuando ves tu perfil
  - "Lotes Disponibles" → cuando ves perfil de otro usuario
  - Detección automática con AuthProvider

---

## [2.0.3] - 1 Diciembre 2025

### 🐛 Corrección de Errores Críticos

**Autor**: Rodrigo Jofré Cerda

#### 🔧 Error de Login Mejorado
- ✅ Mensajes de error limpios y comprensibles
  - Antes: Stack trace completo de DioException
  - Ahora: "Credenciales incorrectas" (simple y claro)
- ✅ Detección de errores de conexión
- ✅ UX mejorado en pantalla de login

#### 🔍 Búsqueda Corregida
- ✅ **Fix crítico**: Búsqueda ahora muestra datos del usuario correcto
  - Problema: Al buscar usuario, se mostraban los lotes propios
  - Solución: `onGenerateRoute` ahora pasa `userId` correctamente
- ✅ Navegación con argumentos funcional
- ✅ Perfiles de otros usuarios accesibles desde búsqueda

---

## [2.0.2] - 1 Diciembre 2025

### 🔍 Búsqueda Completa y Ajustes UX

**Autor**: Rodrigo Jofré Cerda

#### ✅ Búsqueda de Usuarios Implementada
- ✅ **SearchScreen** - Pantalla dedicada con sugerencias en tiempo real
  - Consume endpoint `GET /sugerir?q={query}` (corregido)
  - Validación mínimo 2 caracteres
  - Sugerencias automáticas mientras escribes
  - Empty states informativos
  - Navegación a perfiles de usuarios encontrados
  - Response format: `{suggestions: [{id, nombre, especialidad}]}`
- ✅ Cards de resultados con avatar y especialidad
- ✅ Manejo robusto de errores de API
- ✅ Estados de loading y empty state

#### 🎯 Mejoras de Navegación
- ✅ **Eliminado card duplicado de QR Scanner**
  - Decisión basada en normas de marketing de social media
  - **Solo FAB (Floating Action Button)** en esquina inferior derecha
  - Mayor visibilidad y acceso rápido según Material Design
- ✅ Flujo de navegación optimizado
- ✅ Ruta `/search` agregada a `main.dart`

#### 🎨 Mejoras Visuales
- Cards de resultados con diseño consistente
- Avatares circulares con colores de marca
- Badges de especialidad en resultados
- Iconos de navegación en cards

---

## [2.0.1] - 1 Diciembre 2025

### 🎨 Mejoras UX/UI y Refinamiento

**Autor**: Rodrigo Jofré Cerda

#### 🔧 Correcciones de Linter
- ✅ Eliminados imports innecesarios de `foundation.dart`
- ✅ Corregidos statements sin bloques en `if`
- ✅ Eliminadas variables no utilizadas
- ✅ Documentación con backticks para evitar errores HTML
#### 🎨 HomeScreen Rediseñado
- ✅ **Perfil de usuario mejorado** con diseño de tarjeta gradient
  - Avatar circular con sombra profesional
  - Información organizada en grid 2x2
  - Badges visuales para rol y estado
  - Colores según identidad de marca (Amber)
- ✅ **Sección "Pruebas de API" eliminada** - ya no necesaria
- ✅ **Card de búsqueda de usuarios** agregada
  - Diseño atractivo con iconos coloreados
  - Placeholder para búsqueda con sugerencias (2+ caracteres)
  - Integración futura con `/api/sugerir`
- ✅ **Card de escáner QR** mejorada visualmente
- ✅ Diseño según principios de marketing e ingeniería IEEE

#### 📱 Mejoras de Visualización
- ✅ App configurada como **SOLO VISUALIZACIÓN**
- ✅ Eliminado botón "Editar" de pantalla de detalle de lote
- ✅ Mensaje claro: ediciones se hacen en la plataforma web
- ✅ Shadows y elevaciones profesionales en todos los cards
- ✅ Spacing consistente según guías de Material Design

#### 🔍 Preparación para Búsqueda
- Estructura lista para integrar endpoint `/api/sugerir`
- Dialog de búsqueda con TextField y validación de 2+ caracteres
- Diseño preparado para mostrar resultados y navegar a perfiles

---

## [2.0.0] - 1 Diciembre 2025

### ✅ Implementación Completa - Sprint 1 y 2

**Autor**: Rodrigo Jofré Cerda

### 📋 Planificación Estratégica REVISADA

**Documentos creados**:
- ~~`STRATEGIC_PLAN.md`~~ - ❌ OBSOLETO (análisis incorrecto)
- ~~`TECHNICAL_AUDIT.md`~~ - ❌ OBSOLETO (análisis incorrecto)
- `REVISED_STRATEGIC_PLAN.md` - ✅ **Plan corregido de 6 semanas**

### 🔄 Corrección de Análisis

**Error inicial**: Se propuso crear sistema completo de análisis polínico con ML cuando ya existe.

**Realidad identificada**:
- ✅ Tabla `origenes_botanicos` YA contiene lotes con composición
- ✅ Backend YA tiene endpoints `/api/lotes/<user_id>`, `/api/lote/<id>`
- ✅ Campo `composicion` usa formato CSV: "Especie:%, Especie:%"
- ✅ Web YA muestra clases botánicas y gráficos funcionando
- ❌ Flutter NO consume estos datos existentes

**Gaps reales corregidos**:
- ❌ Password reset sin endpoint API REST
- ❌ Flutter NO tiene modelos para `origenes_botanicos`
- ❌ Flutter NO parsea campo `composicion`
- ❌ Flutter NO muestra visualizaciones de lotes
- ❌ 14 iconos custom no integrados

**Roadmap corregido (6 semanas)**:
- Sprint 1 (sem 1-2): Password Reset + Iconos + Modelos de Lote
- Sprint 2 (sem 3-4): Pantallas de Lotes (lista, detalle, card)
- Sprint 3 (sem 5): Gráficos de composición (pie chart, bars)
- Sprint 4 (sem 6): Dashboard mejorado + Mapa de ubicaciones

**Sistema objetivo corregido**:
- Consumir endpoints existentes de lotes
- Parser de campo `composicion` (CSV a Map)
- Gráficos fl_chart para visualizar composición
- Lista y detalle de lotes del usuario
- Dashboard con métricas de producción
- Integración de 14 iconos custom

### 🎉 Implementado en Esta Versión

#### Backend (MeliAPP_v2)
- ✅ Endpoint `POST /api/auth/forgot-password` para recuperación de contraseña

#### Flutter - Modelos y Servicios
- ✅ `Lote` model con parser CSV de composición (`parseComposicion()`)
- ✅ `LotesService` con métodos CRUD completos
  - `getLotesUsuario()` - Lista lotes públicos
  - `getLote()` - Detalle de lote
  - `createLote()` - Crear lote
  - `updateLote()` - Actualizar lote
  - `deleteLote()` - Eliminar lote
  - `getStats()` - Estadísticas de usuario

#### Flutter - Widgets
- ✅ `AppIcon` - Widget reutilizable para iconos custom (14 iconos integrados)
- ✅ `LoteCard` - Card con preview de top 3 especies y validación
- ✅ `CompositionPieChart` - Gráfico de torta con fl_chart y leyenda

#### Flutter - Pantallas
- ✅ `ForgotPasswordScreen` - Recuperación de contraseña con estados
- ✅ `LotesListScreen` - Lista de lotes con:
  - Header de estadísticas (total lotes, kg, promedio)
  - Pull to refresh
  - Empty state
  - Navegación a detalle
- ✅ `LoteDetailScreen` - Detalle completo con:
  - Header decorativo
  - Info básica del lote
  - Gráfico de composición
  - Lista detallada de especies con progress bars
  - Validación de total (100%)

#### Flutter - Navegación
- ✅ `HomeScreen` actualizado con Card de "Mis Lotes de Miel"
- ✅ `LoginScreen` con link "¿Olvidaste tu contraseña?"
- ✅ `main.dart` con `onGenerateRoute` para rutas dinámicas:
  - `/forgot-password`
  - `/lotes` y `/lotes/list`
  - `/lotes/detail` (con parámetro loteId)

#### Dependencias Agregadas
- ✅ `fl_chart: ^0.66.2` - Gráficos (pie, bar, line charts)
- ✅ `intl: ^0.19.0` - Formateo de fechas

#### Assets
- ✅ 14 iconos PNG integrados en `assets/icons/`:
  - bee.png, bee02.png, bee03.png
  - colmena.png, colmena02.png
  - honey01.png, honey02.png
  - pollen01.png, pollen02.png, pollen03.png
  - apiario01.png, apicultor.png
  - leaf01.png, marker01.png

### 🔧 Mejoras Técnicas
- Parser de composición CSV a `Map<String, double>`
- Validación automática de composición (total ~100%)
- Ordenamiento de especies por porcentaje
- Cálculo de estadísticas de producción
- Arquitectura profesional con separación de concerns

### 📱 UX/UI Mejoradas
- Cards con elevation y border radius consistentes
- Color scheme Amber + Emerald mantenido
- Empty states informativos
- Loading states en todas las pantallas
- Error handling robusto
- Navegación fluida con `Navigator.pushNamed()`

---

## [1.0.0] - 2025-01-10

### 🎉 Lanzamiento Inicial

Primera versión estable de MeliAPP Flutter.

### ✨ Agregado

#### Autenticación
- Sistema completo de login con validaciones
- Registro de nuevos usuarios con formulario
- Persistencia de sesión con cookies y SharedPreferences
- Cierre de sesión con limpieza de datos locales
- Manejo de errores con mensajes informativos

#### Gestión de Usuarios
- Visualización de perfil completo (15 campos)
- Integración con endpoint `/api/profile/me`
- Combinación de datos: `usuarios` + `info_contacto`
- UI organizada en 3 secciones:
  - Información de Cuenta (8 campos)
  - Fechas (2 campos)
  - Información de Contacto (7 campos)

#### Scanner QR
- Escaneo de códigos QR y códigos de barras
- Detección automática de URLs
- Apertura de URLs en navegador externo
- Procesamiento de QR del sistema MeliAPP
- Controles de flash y cambio de cámara
- Detección de plataforma (solo Android/iOS)
- Mensaje informativo en plataformas no soportadas

#### UI/UX
- Material Design moderno y limpio
- Navegación fluida entre pantallas
- Indicadores de carga
- Validaciones en tiempo real
- Mensajes de error contextuales
- Botones de acción flotantes

#### Arquitectura
- Clean Architecture con separación de capas
- State management con Provider
- Comunicación HTTP con Dio
- Modelos de datos con JSON serialization
- Configuración centralizada

### 🔧 Técnico

#### Dependencias Principales
- Flutter SDK 3.9.2+
- Dart 3.0+
- dio ^5.4.0 (Cliente HTTP)
- provider ^6.1.1 (State management)
- mobile_scanner ^5.1.1 (Scanner QR)
- url_launcher ^6.2.4 (Apertura de URLs)
- shared_preferences ^2.2.2 (Storage local)

#### API Integration
- Backend: Flask + Supabase
- Deploy: Vercel (`https://meli-app-cloud.vercel.app`)
- Endpoints implementados:
  - `POST /api/auth/login`
  - `POST /api/auth/register`
  - `POST /api/auth/logout`
  - `GET /api/auth/session`
  - `GET /api/profile/me`
  - `GET /api/usuario/{uuid}/qr`

#### Plataformas Soportadas
- ✅ Android (minSdkVersion 21)
- ✅ iOS (iOS 12+)
- ⚠️ Web (funcionalidad limitada sin cámara)
- ⚠️ Windows/Linux/macOS (funcionalidad limitada sin cámara)

### 📚 Documentación
- README.md completo
- CONTRIBUTING.md con guías de contribución
- CHANGELOG.md para tracking de versiones
- Documentación técnica interna:
  - ANALISIS_REGISTRO.md
  - IMPLEMENTACION_FINAL.md
  - QR_SCANNER_IMPLEMENTADO.md
  - MIGRACION_MOBILE_SCANNER.md

### 🐛 Corregido
- Error de namespace en qr_code_scanner (migrado a mobile_scanner)
- Crash al intentar usar scanner QR en Windows
- Error de autenticación con cookies
- Validaciones faltantes en formularios

### 🔐 Seguridad
- Almacenamiento seguro de cookies de sesión
- Validaciones server-side en backend
- Timeout en requests HTTP (30s)
- Manejo seguro de credenciales

### ⚡ Rendimiento
- Carga lazy de imágenes
- Caché de datos de usuario
- Optimización de build size
- Hot reload para desarrollo

---

## [0.2.0] - 2025-01-08

### ✨ Agregado
- Scanner QR con mobile_scanner
- Detección de URLs en códigos QR
- Apertura automática en navegador

### 🔧 Cambiado
- Migración de qr_code_scanner a mobile_scanner
- Actualización de dependencias

### 🐛 Corregido
- Error de compilación en Android (namespace)
- Compatibilidad con Android Gradle Plugin moderno

---

## [0.1.0] - 2025-01-05

### ✨ Agregado
- Sistema de autenticación básico
- Login screen
- Register screen
- Home screen con datos básicos
- Integración con API REST

### 🔧 Configuración Inicial
- Estructura de proyecto Flutter
- Arquitectura Clean Architecture
- State management con Provider
- HTTP client con Dio

---

## Tipos de Cambios

- **Agregado** para nuevas funcionalidades
- **Cambiado** para cambios en funcionalidades existentes
- **Deprecado** para funcionalidades que serán removidas
- **Removido** para funcionalidades removidas
- **Corregido** para corrección de bugs
- **Seguridad** para parches de vulnerabilidades

---

## Links de Comparación

[1.0.0]: https://github.com/Nahzap/MeliAPP_Flutter/releases/tag/v1.0.0
[0.2.0]: https://github.com/Nahzap/MeliAPP_Flutter/releases/tag/v0.2.0
[0.1.0]: https://github.com/Nahzap/MeliAPP_Flutter/releases/tag/v0.1.0
