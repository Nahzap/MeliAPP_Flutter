# 🍯 MeliAPP Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](https://github.com/Nahzap/MeliAPP_Flutter)

Aplicación móvil para la gestión y trazabilidad de productos apícolas, construida con Flutter y conectada a un backend REST API en Flask/Supabase.

---

## 📱 Sobre el Proyecto

**MeliAPP Flutter** es la aplicación móvil oficial del ecosistema MeliAPP, diseñada para apicultores, prestadores de servicios y consumidores. Permite gestionar perfiles de usuarios, escanear códigos QR para trazabilidad de productos, y acceder a información completa de producción apícola.

### ✨ Características Principales

- 🔐 **Autenticación Segura**: Login y registro con sesiones persistentes
- 👤 **Gestión de Perfiles**: Visualización completa de datos de usuario (15+ campos)
- 📷 **Scanner QR Avanzado**: Escaneo de QR con detección automática de URLs
- 🌐 **Apertura de URLs**: Redirección automática al navegador desde códigos QR
- 💾 **Almacenamiento Local**: Persistencia de sesión con SharedPreferences
- 🎨 **UI Moderna**: Interfaz limpia y profesional con Material Design
- 📱 **Multi-Plataforma**: Compatible con Android e iOS

---

## 🏗️ Arquitectura

El proyecto sigue una arquitectura **Clean Architecture** con separación de capas:

```
lib/
├── config/          # Configuración centralizada (API endpoints, constantes)
├── models/          # Modelos de datos (User, AuthResponse, etc.)
├── providers/       # Gestión de estado con Provider
├── screens/         # Pantallas de la aplicación
├── services/        # Lógica de negocio y comunicación con API
└── main.dart        # Punto de entrada de la aplicación
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
| `provider` | ^6.1.1 | Gestión de estado |
| `shared_preferences` | ^2.2.2 | Almacenamiento local persistente |
| `mobile_scanner` | ^5.1.1 | Scanner QR/códigos de barras |
| `url_launcher` | ^6.2.4 | Apertura de URLs en navegador |
| `json_annotation` | ^4.8.1 | Serialización JSON |

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

- **Backend API**: MeliAPP_v2 corriendo en `https://meli-app-cloud.vercel.app`

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
  
  // Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String profileEndpoint = '/api/profile/me';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
}
```

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
| `/api/auth/login` | POST | Iniciar sesión |
| `/api/auth/register` | POST | Registrar nuevo usuario |
| `/api/auth/logout` | POST | Cerrar sesión |
| `/api/auth/session` | GET | Verificar sesión activa |
| `/api/profile/me` | GET | Obtener perfil completo |
| `/api/usuario/{uuid}/qr` | GET | Generar QR de usuario |

### Backend Repository

El backend está desarrollado en Flask y Supabase:
- **Repositorio**: [MeliAPP_v2](https://github.com/Nahzap/Meli_APP_v3)
- **Deploy**: Vercel (`https://meli-app-cloud.vercel.app`)
- **Base de Datos**: Supabase PostgreSQL

---

## 📱 Pantallas

### 1. Login Screen
- Email y contraseña
- Validación en tiempo real
- Botón "¿No tienes cuenta? Regístrate"
- Manejo de errores

### 2. Register Screen
- Formulario completo de registro
- Validaciones client-side
- Confirmación de contraseña
- Link "Ya tienes cuenta? Inicia sesión"

### 3. Home Screen
- Tarjeta de usuario con avatar
- 3 secciones de información
- Botón flotante de Scanner QR
- Botón "Cerrar Sesión"

### 4. QR Scanner Screen
- Vista de cámara con overlay
- Controles de flash y cambio de cámara
- Área de estado (Escaneando/Procesando/Escaneado)
- Dialogs informativos

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

## 📚 Documentación Adicional

El proyecto incluye documentación detallada:

- **[ANALISIS_REGISTRO.md](ANALISIS_REGISTRO.md)**: Sistema de registro de usuarios
- **[IMPLEMENTACION_FINAL.md](IMPLEMENTACION_FINAL.md)**: Endpoint `/api/profile/me`
- **[REGISTRO_IMPLEMENTADO.md](REGISTRO_IMPLEMENTADO.md)**: Flujo completo de registro
- **[QR_SCANNER_IMPLEMENTADO.md](QR_SCANNER_IMPLEMENTADO.md)**: Scanner QR con URLs
- **[MIGRACION_MOBILE_SCANNER.md](MIGRACION_MOBILE_SCANNER.md)**: Migración a mobile_scanner
- **[RESUMEN_COMPLETO_SESION.md](RESUMEN_COMPLETO_SESION.md)**: Resumen de implementaciones

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Para contribuir:

1. **Fork** el proyecto
2. Crea una **rama** para tu feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. **Push** a la rama (`git push origin feature/AmazingFeature`)
5. Abre un **Pull Request**

### Guías de Contribución

- Sigue el estilo de código Dart/Flutter
- Ejecuta `flutter analyze` antes de commit
- Añade tests para nuevas funcionalidades
- Actualiza documentación si es necesario

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

```
MIT License

Copyright (c) 2025 MeliAPP Flutter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

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

## ⭐ Soporte

Si este proyecto te fue útil, considera darle una ⭐ en GitHub!

---

<div align="center">

**Hecho con ❤️ y Flutter**

🍯 **MeliAPP** - Gestión de Producción Apícola 🐝

</div>
