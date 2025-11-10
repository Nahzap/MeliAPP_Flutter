# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

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
- Deploy: Vercel (`https://meli-app-v3.vercel.app`)
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
