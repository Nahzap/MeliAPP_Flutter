# 🍯 MeliAPP Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/Version-2.0.9--dev-orange)](https://github.com/Nahzap/MeliAPP_Flutter)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows-lightgrey)](https://github.com/Nahzap/MeliAPP_Flutter)

> **⚠️ VERSIÓN DE DESARROLLO**  
> Esta aplicación está en fase de desarrollo y testing con usuarios. Algunas funcionalidades pueden estar incompletas o experimentar cambios.

Aplicación móvil profesional para la gestión, trazabilidad y análisis de producción apícola. Conecta apicultores, proveedores y compradores en un ecosistema digital completo.

---

## 📱 Sobre el Proyecto

**MeliAPP Flutter** es la aplicación móvil del ecosistema MeliAPP, diseñada para profesionalizar la gestión apícola. Facilita la conexión entre apicultores, proveedores de servicios y compradores, proporcionando herramientas para trazabilidad, análisis polínico y gestión de producción.

### ✨ Características Principales v2.0.9

#### 🔐 Autenticación y Perfiles
- **Login/Registro Seguro**: Sesiones persistentes con cookies
- **Perfiles Completos**: 15+ campos de información de usuario
- **Búsqueda de Usuarios**: Encuentra apicultores y proveedores
- **Información de Contacto Pública**: Email, teléfono, ubicación para facilitar contacto comercial

#### 🍯 Gestión de Lotes de Miel
- **Lista de Lotes**: Visualización completa de producción
- **Análisis Polínico**: Gráficos de composición botánica
- **Ranking TOP 3**: Lotes con mayor producción
- **Trazabilidad**: Información detallada por lote
- **Iconografía Personalizada**: Diseño profesional con iconos custom

#### 📊 Visualización de Datos
- **Gráficos de Torta**: Composición polínica por especie
- **Análisis Consolidado**: Composición total de múltiples lotes
- **Estadísticas**: Producción total, número de lotes, especies

#### 📷 Scanner QR
- **Escaneo de Códigos**: Compatibilidad con QR y códigos de barras
- **Detección de URLs**: Apertura automática en navegador
- **Trazabilidad de Productos**: Información de origen

#### 🎨 Experiencia de Usuario
- **UI Moderna**: Material Design con paleta de colores amber/naranja
- **Iconografía Custom**: Colmena, apicultor, miel, apiario
- **Contraste Optimizado**: Campos blancos sobre fondos de color
- **Multi-Plataforma**: Android, iOS, Windows

---

## 🏗️ Arquitectura

El proyecto sigue una arquitectura **Clean Architecture** con separación de capas:

```
lib/
├── config/              # Configuración (API, theme)
│   ├── api_config.dart
│   └── theme_config.dart
├── models/              # Modelos de datos
│   ├── user_model.dart
│   ├── lote_model.dart
│   └── auth_response.dart
├── providers/           # State management
│   └── auth_provider.dart
├── screens/             # Pantallas UI
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── search_screen.dart
│   ├── lotes/
│   │   ├── lotes_list_screen.dart
│   │   └── lote_detail_screen.dart
│   └── qr_scanner_screen.dart
├── services/            # Lógica de negocio
│   ├── api_service.dart
│   └── lotes_service.dart
├── widgets/             # Componentes reutilizables
│   ├── lote_card.dart
│   └── composition_pie_chart.dart
└── main.dart            # Entry point

MeliAPP_icons/           # Iconografía custom
├── colmena.png
├── apicultor.png
├── honey02.png
└── apiario01.png
```

### 📐 Capas de la Arquitectura

1. **Presentation Layer** (`screens/` + `providers/`)
   - UI components (Widgets)
   - State management (Provider)
   - Navegación entre pantallas

2. **Business Logic Layer** (`services/`)
   - Lógica de autenticación
   - Comunicación con API REST
   - Procesamiento de QR

3. **Data Layer** (`models/`)
   - Modelos de datos
   - Serialización/Deserialización JSON

4. **Configuration Layer** (`config/`)
   - URLs de API
   - Constantes globales
   - Configuración de timeouts

---

## 🛠️ Tecnologías y Dependencias

### Core Framework
- **Flutter**: 3.9.2+
- **Dart**: 3.0+

### Principales Dependencias

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `dio` | ^5.4.0 | Cliente HTTP con interceptores |
| `dio_cookie_manager` | ^3.1.1 | Gestión de cookies para sesiones |
| `cookie_jar` | ^4.0.8 | Almacenamiento de cookies |
| `provider` | ^6.1.1 | Gestión de estado (Provider pattern) |
| `shared_preferences` | ^2.2.2 | Persistencia local (session tokens) |
| `mobile_scanner` | ^5.1.1 | Scanner QR/códigos de barras |
| `url_launcher` | ^6.2.4 | Apertura de URLs externas |
| `fl_chart` | ^0.68.0 | Gráficos y visualizaciones |
| `intl` | ^0.19.0 | Formateo de fechas y números |

---

## 📋 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

- **Flutter SDK**: 3.9.2 o superior
  ```bash
  flutter --version
  ```

- **Dart SDK**: 3.0 o superior (incluido con Flutter)

- **Android Studio** o **Xcode** (para compilar en Android/iOS)

- **Git**: Para clonar el repositorio

- **Backend API**: MeliAPP_v2 desplegado en Vercel  
  URL: `https://meli-app-cloud.vercel.app`  
  Repositorio: [Meli_APP_v3](https://github.com/Nahzap/Meli_APP_v3)

---

## 🚀 Instalación

### 1. Clonar el Repositorio

```bash
git clone https://github.com/Nahzap/MeliAPP_Flutter.git
cd MeliAPP_Flutter
```

### 2. Instalar Dependencias

```bash
flutter pub get
```

### 3. Verificar Configuración

```bash
flutter doctor
```

Asegúrate de que todos los checks estén en ✓ (verde).

### 4. Ejecutar en Emulador/Dispositivo

**Android:**
```bash
flutter run
```

**iOS** (solo en macOS):
```bash
flutter run -d ios
```

**Modo Release** (optimizado):
```bash
flutter run --release
```

---

## ⚙️ Configuración

### API Backend

La URL del backend se configura en `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'https://meli-app-cloud.vercel.app';
  
  // Endpoints de autenticación
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String sessionEndpoint = '/api/auth/session';
  
  // Endpoints de usuario
  static const String profileEndpoint = '/api/profile/me';
  // Nota: No incluir endpoints específicos con IDs aquí
  // Construirlos dinámicamente en los servicios
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
```

> **⚠️ Nota de Seguridad:** La URL del backend es pública (Vercel). No incluyas API keys, tokens o secretos en este archivo.

Para cambiar el backend, modifica `baseUrl` y reconstruye la app.

### Permisos

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
```

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>Esta aplicación necesita acceso a la cámara para escanear códigos QR</string>
```

---

## 📂 Estructura del Proyecto

```
MeliAPP_Flutter/
│
├── android/                 # Proyecto Android nativo
├── ios/                     # Proyecto iOS nativo
├── lib/                     # Código fuente principal
│   ├── config/
│   │   └── api_config.dart           # Configuración de API
│   ├── models/
│   │   ├── user_model.dart           # Modelo de Usuario
│   │   ├── auth_response.dart        # Respuesta de autenticación
│   │   ├── session_response.dart     # Respuesta de sesión
│   │   └── qr_response.dart          # Respuesta de QR
│   ├── providers/
│   │   └── auth_provider.dart        # Provider de autenticación
│   ├── screens/
│   │   ├── login_screen.dart         # Pantalla de login
│   │   ├── register_screen.dart      # Pantalla de registro
│   │   ├── home_screen.dart          # Pantalla principal
│   │   └── qr_scanner_screen.dart    # Scanner de QR
│   ├── services/
│   │   ├── api_service.dart          # Servicio de API REST
│   │   ├── auth_service.dart         # Servicio de autenticación
│   │   └── qr_service.dart           # Servicio de QR
│   └── main.dart                     # Punto de entrada
│
├── test/                    # Tests unitarios e integración
├── web/                     # Proyecto Web (PWA)
├── windows/                 # Proyecto Windows nativo
├── linux/                   # Proyecto Linux nativo
├── macos/                   # Proyecto macOS nativo
│
├── pubspec.yaml             # Dependencias y configuración
├── analysis_options.yaml    # Opciones de análisis estático
├── .gitignore              # Archivos ignorados por Git
├── LICENSE                 # Licencia MIT
└── README.md               # Este archivo
```

---

## 🎯 Funcionalidades Detalladas

### 1. 🔐 Autenticación

#### Login
- Validación de email y contraseña
- Sesión persistente con cookies
- Manejo de errores con mensajes claros
- Indicador de carga durante login

#### Registro
- Formulario con validaciones client-side:
  - Nombre completo (mínimo 3 caracteres)
  - Email válido
  - Contraseña (mínimo 6 caracteres)
  - Confirmación de contraseña
- Creación automática en backend
- Sesión iniciada automáticamente después del registro

**Flujo:**
```
Usuario → Formulario → POST /api/auth/register 
       → Backend crea usuario + sesión 
       → GET /api/profile/me 
       → Guarda localmente 
       → Navega a HomeScreen
```

---

### 2. 👤 Gestión de Perfiles

La aplicación muestra **15 campos completos** del usuario combinando datos de las tablas `usuarios` e `info_contacto`:

**Datos de Cuenta (8 campos):**
- UUID del usuario
- Nombre de usuario
- Role (PROVEEDOR, REGULAR, ADMIN)
- Tipo de usuario
- Status
- Estado activo
- Fecha de registro
- Último login

**Datos de Contacto (7 campos):**
- Nombre completo
- Nombre de empresa
- Email principal
- Teléfono principal
- Dirección
- Comuna
- Región

**Endpoint:** `GET /api/profile/me`

**UI Organizada en 3 Secciones:**
1. 📋 Información de Cuenta
2. 📅 Fechas
3. 📇 Información de Contacto

---

### 3. 📷 Scanner QR

**Funcionalidad Inteligente:**

1. **Detección Automática de URLs**
   - Si el QR contiene una URL (`http://` o `https://`)
   - Abre automáticamente en el navegador por defecto
   - Muestra confirmación al usuario

2. **Procesamiento de QR del Sistema MeliAPP**
   - Si NO es URL, procesa como QR de usuario/producto
   - Consulta información del backend
   - Muestra datos del perfil/producto

**Tecnología:**
- `mobile_scanner`: Scanner moderno compatible con AGP
- `url_launcher`: Apertura de URLs en navegador externo

**Controles:**
- 💡 Toggle flash/linterna
- 📷 Cambiar entre cámaras
- ⏸️ Pausar/reanudar scanner

**Detección de Plataforma:**
- ✅ Android/iOS: Scanner funcional
- ⚠️ Windows/Linux/macOS/Web: Mensaje informativo

---

### 4. 💾 Persistencia de Datos

**SharedPreferences** para almacenamiento local:
- Token de sesión
- Datos del usuario
- Preferencias de la app

**Cookies** para sesiones HTTP:
- Cookie `meliapp_session` manejada automáticamente
- Sincronización con backend
- Expiración controlada por servidor

---

## 🌐 API Backend

### Endpoints Utilizados

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/api/auth/login` | POST | Iniciar sesión con email/password |
| `/api/auth/register` | POST | Registrar nuevo usuario |
| `/api/auth/logout` | POST | Cerrar sesión actual |
| `/api/auth/session` | GET | Verificar sesión activa |
| `/api/profile/me` | GET | Obtener perfil del usuario autenticado |
| `/api/profile/{user_id}` | GET | **[NUEVO]** Obtener perfil público de cualquier usuario |
| `/api/lotes/{user_id}` | GET | Obtener lotes de un usuario |
| `/api/lote/{lote_id}` | GET | Obtener detalle de un lote específico |
| `/api/lote/composicion/{lote_id}` | GET | Obtener composición polínica del lote |
| `/sugerir?q={query}` | GET | Buscar usuarios por nombre |

### Backend Repository

El backend está desarrollado en Flask y Supabase:
- **Repositorio**: [MeliAPP_v2](https://github.com/Nahzap/Meli_APP_v3)
- **Deploy**: Vercel (`https://meli-app-cloud.vercel.app`)
- **Base de Datos**: Supabase PostgreSQL

---

## 📱 Pantallas

### 1. Login Screen
- Logo profesional (colmena.png)
- Formulario: email y contraseña
- Validación en tiempo real
- Link de registro
- Manejo de errores con mensajes claros

### 2. Register Screen
- Formulario completo con validaciones
- Username, email, password
- Confirmación de contraseña
- Auto-login después del registro

### 3. Home Screen
- **Header con Perfil de Usuario**
  - Avatar con inicial
  - Nombre completo y username
  - Card gradient profesional
- **Secciones de Información** (fondos blancos con contraste)
  - Sobre mí: Username, Rol, Estado
  - Información de Contacto: Nombre, Empresa, Email, Teléfono, Ubicación (con icono apiario01.png)
- **Navegación Rápida**
  - Card "Mis Lotes" → Lista de lotes
  - Card "Buscar Productores" → Búsqueda de usuarios
- **FAB**: Scanner QR

### 4. Search Screen
- **Búsqueda de Usuarios**
  - Campo de búsqueda con sugerencias en tiempo real
  - Activación con 2+ caracteres
- **Resultados**
  - Avatar con icono apicultor.png
  - Nombre completo y rol
  - Empresa, email, teléfono, comuna (si disponible)
  - Click → Navega a lotes del usuario

### 5. Lotes List Screen
- **Header de Usuario** (solo para otros usuarios)
  - Card con información de contacto completa
  - Icono apicultor.png
  - Nombre, empresa, email, teléfono, ubicación
  - **CRÍTICO**: Permite contactar al productor
- **Gráfico Polínico Consolidado**
  - Pie chart (240px) + Leyenda
  - Layout horizontal
  - Análisis de múltiples lotes
- **Ranking TOP 3 Lotes**
  - Iconos honey02.png (68x68px) con medallas 🥇🥈🥉
  - Clickeable → Navega a detalle
  - Producción en kg
- **Lista de Lotes**
  - Cards con información resumida
  - Tap → Detalle del lote

### 6. Lote Detail Screen
- **Gráfico de Composición** (arriba)
  - Pie chart con porcentajes
  - Leyenda de especies
- **Información del Lote**
  - Nombre, orden, fecha análisis
  - Kg producidos
  - Composición detallada

### 7. QR Scanner Screen
- Cámara con overlay
- Controles de flash y cambio de cámara
- Detección automática de URLs
- Apertura en navegador externo

---

## 🧪 Testing

### Ejecutar Tests

```bash
# Tests unitarios
flutter test

# Tests de integración
flutter test integration_test/

# Coverage
flutter test --coverage
```

### Tests Implementados
- ✅ Modelos de datos
- ✅ Servicios de API
- ✅ Autenticación
- 🔄 Tests de UI (en progreso)

---

## 🔧 Build y Deploy

### Android APK

```bash
# Debug
flutter build apk

# Release (firmado)
flutter build apk --release

# Split por ABI (reduce tamaño)
flutter build apk --split-per-abi
```

**Salida**: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Google Play)

```bash
flutter build appbundle --release
```

**Salida**: `build/app/outputs/bundle/release/app-release.aab`

### iOS IPA

```bash
flutter build ios --release
```

Luego usar Xcode para archivar y subir a App Store.

---

## 🐛 Troubleshooting

### Error: Namespace not specified (Android)

Si usas una versión antigua de `qr_code_scanner`, migra a `mobile_scanner`:

```bash
flutter clean
flutter pub get
```

Ver documentación: [MIGRACION_MOBILE_SCANNER.md](MIGRACION_MOBILE_SCANNER.md)

### Error: No se puede conectar a la API

Verifica:
1. Backend está corriendo
2. URL en `api_config.dart` es correcta
3. Dispositivo tiene conexión a internet
4. No hay firewall bloqueando

### Scanner QR no funciona en Windows

Esto es esperado. `mobile_scanner` solo funciona en Android/iOS. La app muestra un mensaje informativo.

---

## 📚 Documentación

### Documentación Pública

- **[CHANGELOG.md](docs/CHANGELOG.md)**: Historial completo de versiones
- **[QR_SCANNER.md](docs/QR_SCANNER.md)**: Documentación del scanner QR

### Documentación de Desarrollo (Local)

> La documentación técnica interna se mantiene localmente y no se sube a GitHub para mantener el repositorio limpio.

Archivos de desarrollo (excluidos en `.gitignore`):
- Análisis de registro
- Implementaciones internas
- Notas de desarrollo
- Scripts de prueba

---

## 🤝 Contribuir

> **⚠️ PROYECTO EN DESARROLLO**  
> Esta aplicación está en fase de testing activo. Las contribuciones están siendo coordinadas internamente.

Si encuentras bugs o tienes sugerencias:
1. Abre un **Issue** describiendo el problema/sugerencia
2. Incluye capturas de pantalla si es posible
3. Especifica la plataforma (Android/iOS/Windows)
4. Incluye logs relevantes

### Roadmap

**v2.1.0 (Próxima versión)**
- [ ] Recuperación de contraseña
- [ ] Edición de perfil de usuario
- [ ] Creación de lotes
- [ ] Filtros de búsqueda avanzados
- [ ] Notificaciones push

**v2.2.0 (Futuro)**
- [ ] Modo offline
- [ ] Sincronización de datos
- [ ] Exportación de reportes
- [ ] Integración con sensores IoT

---

## 📄 Licencia

Este proyecto es propietario y está en desarrollo activo. Todos los derechos reservados.

Para consultas sobre licenciamiento comercial, contactar a los autores.

---

## 👥 Autores

- **Rodrigo Jofré Cerda** - *Developer* - [@askna](https://github.com/askna)

---

## 🙏 Agradecimientos

- [Flutter Team](https://flutter.dev) por el excelente framework
- [Supabase](https://supabase.com) por la plataforma backend
- Comunidad Flutter por los paquetes open-source
- Apicultores que inspiraron este proyecto

---

## 📞 Contacto

**Email**: rodrigoandresj@gmail.com

**Proyecto Backend**: [MeliAPP_v2](https://github.com/Nahzap/Meli_APP_v3)

**Proyecto Flutter**: [MeliAPP_Flutter](https://github.com/Nahzap/MeliAPP_Flutter)

---

## 🐛 Reporte de Bugs

**Versión actual:** 2.0.9-dev  
**Fase:** Testing con usuarios

Si encuentras problemas:
1. Verifica que estés usando la última versión
2. Revisa los [Issues](https://github.com/Nahzap/MeliAPP_Flutter/issues) existentes
3. Si es nuevo, crea un Issue con:
   - Descripción del problema
   - Pasos para reproducir
   - Capturas de pantalla
   - Plataforma y versión
   - Logs de error (si existen)

---

## 📊 Estado del Proyecto

**Última actualización:** Diciembre 2025  
**Estado:** 🟡 En desarrollo activo  
**Testing:** 🟢 Disponible para pruebas

### Changelog Reciente

**v2.0.9 (Actual)**
- ✅ Endpoint de perfiles públicos
- ✅ Información de contacto en búsqueda de usuarios
- ✅ Contraste mejorado en HomeScreen
- ✅ Logo colmena en LoginScreen
- ✅ TOP 3 clickeable con navegación

**v2.0.8**
- ✅ Correcciones críticas de UI/UX
- ✅ Card de usuario en lista de lotes

**v2.0.7**
- ✅ Ajustes de tamaños (iconos +70%, gráfico +20%)

Ver [CHANGELOG.md](docs/CHANGELOG.md) completo para más detalles.

---

<div align="center">

### 🍯 MeliAPP Flutter

**Profesionalizando la Apicultura Chilena** 🐝

Desarrollado con ❤️ usando Flutter

---

[![GitHub](https://img.shields.io/badge/GitHub-Nahzap%2FMeliAPP__Flutter-blue?logo=github)](https://github.com/Nahzap/MeliAPP_Flutter)
[![Backend](https://img.shields.io/badge/Backend-Meli__APP__v3-green?logo=github)](https://github.com/Nahzap/Meli_APP_v3)

</div>
