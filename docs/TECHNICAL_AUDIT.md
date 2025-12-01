# Auditoría Técnica: MeliAPP Cloud
**Fecha**: 1 Diciembre 2025  
**Scope**: Backend + Flutter + Base de Datos

---

## 🔍 Executive Summary

### ✅ Fortalezas
- Arquitectura modular bien estructurada (Blueprints)
- Autenticación robusta (Supabase Auth + OAuth)
- RLS implementado en tablas existentes
- Flutter app funcional con Clean Architecture
- Tema visual unificado (Amber + Emerald)
- 14 iconos custom de alta calidad

### ⚠️ Gaps Críticos
1. **Password Reset**: Backend implementado pero SIN endpoint API REST
2. **Análisis Polínico**: Sistema NO existe (tablas, endpoints, UI)
3. **Modo Offline**: NO implementado (crítico para campo)
4. **Visualizaciones**: NO existen (gráficos, mapas, dashboards)
5. **Iconos**: NO integrados en Flutter

---

## 📊 Análisis de Base de Datos

### Tablas Existentes (5)

#### `usuarios` (auth_user_id PK)
```sql
username VARCHAR UNIQUE NOT NULL
tipo_usuario VARCHAR DEFAULT 'regular'
role VARCHAR DEFAULT 'regular'
status VARCHAR DEFAULT 'active'
activo BOOLEAN DEFAULT true
fecha_registro TIMESTAMPTZ
last_login TIMESTAMPTZ
```
**RLS**: ✅ Habilitado  
**Relaciones**: 1:1 con auth.users

#### `info_contacto` (id PK, auth_user_id FK UNIQUE)
```sql
nombre_completo VARCHAR NOT NULL
nombre_empresa VARCHAR NULL
correo_principal VARCHAR NULL
telefono_principal VARCHAR NULL
direccion VARCHAR NULL
comuna VARCHAR NULL
region VARCHAR NULL
```
**RLS**: ✅ Habilitado  
**Relaciones**: 1:1 con usuarios

#### `ubicaciones` (id PK, auth_user_id FK)
```sql
nombre VARCHAR NOT NULL
latitud FLOAT8 NOT NULL
longitud FLOAT8 NOT NULL
norma_geo VARCHAR DEFAULT 'WGS84'
descripcion TEXT NULL
```
**RLS**: ✅ Habilitado  
**Relaciones**: 1:N con usuarios

#### `origenes_botanicos` (id PK, auth_user_id FK)
```sql
orden_miel INTEGER NOT NULL
nombre_miel VARCHAR NOT NULL
temporada VARCHAR CHECK (temporada ~ '^(VERANO|OTOÑO|INVIERNO|PRIMAVERA)( - ...)*$')
kg_producidos NUMERIC CHECK (kg_producidos >= 0)
composicion TEXT CHECK (composicion ~ '^([a-zA-Z0-9...]+:[0-9]+)(, ...)*$')
fecha_registro TIMESTAMPTZ DEFAULT NOW()
fecha_actualizacion TIMESTAMPTZ DEFAULT NOW()
```
**RLS**: ✅ Habilitado  
**Nota**: Esta tabla es para PRODUCCIÓN, NO para análisis polínico

#### `solicitudes_apicultor` (id PK, auth_user_id FK)
```sql
nombre_completo VARCHAR NOT NULL
nombre_empresa VARCHAR NULL
region VARCHAR NOT NULL
comuna VARCHAR NOT NULL
telefono VARCHAR NOT NULL
descripcion_miel TEXT NULL
temporada VARCHAR NULL
ubicacion_apiario VARCHAR NULL
token_temporal VARCHAR NULL
token_expiry TIMESTAMPTZ NULL
status VARCHAR DEFAULT 'pending'
```
**RLS**: ✅ Habilitado  
**Propósito**: Solicitudes de nuevos apicultores

### ❌ Tablas Faltantes (CRÍTICO)

El sistema de **análisis polínico** requiere 3 tablas nuevas:

```sql
-- 1. Lotes de muestras de miel
CREATE TABLE lotes_muestras (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    codigo_lote VARCHAR(50) UNIQUE NOT NULL,
    fecha_cosecha DATE NOT NULL,
    ubicacion_id UUID REFERENCES ubicaciones(id) ON DELETE SET NULL,
    peso_kg NUMERIC(10,2) CHECK (peso_kg > 0),
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'procesando', 'completado', 'error')),
    notas TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_lotes_auth_user ON lotes_muestras(auth_user_id);
CREATE INDEX idx_lotes_estado ON lotes_muestras(estado);
CREATE INDEX idx_lotes_fecha ON lotes_muestras(fecha_cosecha DESC);

-- RLS
ALTER TABLE lotes_muestras ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own lotes"
ON lotes_muestras FOR SELECT
USING (auth.uid() = auth_user_id);

CREATE POLICY "Users create own lotes"
ON lotes_muestras FOR INSERT
WITH CHECK (auth.uid() = auth_user_id);

CREATE POLICY "Users update own lotes"
ON lotes_muestras FOR UPDATE
USING (auth.uid() = auth_user_id);

-- 2. Muestras individuales (imágenes de microscopio)
CREATE TABLE muestras_polen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lote_id UUID NOT NULL REFERENCES lotes_muestras(id) ON DELETE CASCADE,
    codigo_muestra VARCHAR(50) UNIQUE NOT NULL,
    fecha_analisis DATE NOT NULL,
    imagen_microscopio_url TEXT,
    estado_procesamiento VARCHAR(20) DEFAULT 'pendiente' CHECK (estado_procesamiento IN ('pendiente', 'analizando', 'completado', 'error')),
    validado_por_experto BOOLEAN DEFAULT false,
    notas_validacion TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_muestras_lote ON muestras_polen(lote_id);
CREATE INDEX idx_muestras_estado ON muestras_polen(estado_procesamiento);

-- RLS (a través de lote_id)
ALTER TABLE muestras_polen ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own muestras"
ON muestras_polen FOR SELECT
USING (
    lote_id IN (
        SELECT id FROM lotes_muestras WHERE auth_user_id = auth.uid()
    )
);

CREATE POLICY "Users create own muestras"
ON muestras_polen FOR INSERT
WITH CHECK (
    lote_id IN (
        SELECT id FROM lotes_muestras WHERE auth_user_id = auth.uid()
    )
);

-- 3. Resultados del clasificador de polen
CREATE TABLE resultados_polinicos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    muestra_id UUID NOT NULL REFERENCES muestras_polen(id) ON DELETE CASCADE,
    especie_floral VARCHAR(100) NOT NULL,
    porcentaje NUMERIC(5,2) NOT NULL CHECK (porcentaje >= 0 AND porcentaje <= 100),
    confidence_score NUMERIC(4,3) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    validado_por_humano BOOLEAN DEFAULT false,
    correccion_humana NUMERIC(5,2) CHECK (correccion_humana >= 0 AND correccion_humana <= 100),
    metadata JSONB, -- {model_version, processing_time_ms, etc.}
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_resultados_muestra ON resultados_polinicos(muestra_id);
CREATE INDEX idx_resultados_especie ON resultados_polinicos(especie_floral);

-- RLS
ALTER TABLE resultados_polinicos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own resultados"
ON resultados_polinicos FOR SELECT
USING (
    muestra_id IN (
        SELECT mp.id FROM muestras_polen mp
        JOIN lotes_muestras lm ON mp.lote_id = lm.id
        WHERE lm.auth_user_id = auth.uid()
    )
);

-- 4. (OPCIONAL) Regiones botánicas para mapas
CREATE TABLE regiones_botanicas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(100) NOT NULL,
    codigo_region VARCHAR(20) UNIQUE NOT NULL,
    poligono_geojson JSONB NOT NULL, -- GeoJSON Polygon
    flora_predominante VARCHAR[] DEFAULT '{}',
    temporada_floracion VARCHAR[] DEFAULT '{}',
    altitud_promedio NUMERIC(7,2),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_regiones_codigo ON regiones_botanicas(codigo_region);
-- Índice espacial (requiere PostGIS)
-- CREATE INDEX idx_regiones_geom ON regiones_botanicas USING GIST ((poligono_geojson::geometry));

-- RLS: Lectura pública, escritura admin
ALTER TABLE regiones_botanicas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view regiones"
ON regiones_botanicas FOR SELECT
TO public
USING (true);

CREATE POLICY "Admin can manage regiones"
ON regiones_botanicas FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM usuarios
        WHERE auth_user_id = auth.uid() AND role = 'admin'
    )
);
```

**Total**: 4 tablas nuevas con 12 políticas RLS

---

## 🌐 Análisis de Backend (Flask)

### Arquitectura Actual

```
MeliAPP_v2/
├── app.py                      # Main app + blueprint registration
├── auth_manager.py             # Clase AuthManager (auth logic)
├── auth_manager_routes.py      # API REST endpoints de auth
├── searcher_routes.py          # Búsqueda de usuarios
├── lotes_routes.py             # Gestión de lotes (origenes_botanicos)
├── profile_routes.py           # Rutas de perfil
├── web_routes.py               # Rutas web (HTML)
├── supabase_client.py          # Singleton de Supabase
└── modify_DB.py                # Operaciones de BD
```

### Endpoints Existentes (26)

#### Autenticación (auth_manager_routes.py)
- `POST /api/login` - Login JSON
- `POST /api/auth/login` - Login JSON (alternativo)
- `POST /api/auth/register` - Registro
- `POST /api/auth/logout` - Logout
- `GET /api/auth/session` - Verificar sesión
- `GET/POST /api/auth/confirm` - Confirmar email
- `POST /api/auth/resend-confirmation` - Reenviar email

#### Búsqueda (searcher_routes.py)
- `GET /api/search` - Búsqueda general
- `GET /api/sugerir` - Autocompletado
- `GET /profile/<auth_user_id>` - Perfil público
- `GET /api/profile/me` - Perfil completo (usuarios + info_contacto)

#### Lotes (lotes_routes.py)
- `GET /api/lote/<lote_id>` - Obtener lote (origenes_botanicos)
- `GET /api/lote/composicion/<lote_id>` - Composición
- `PUT /api/lote/<lote_id>` - Actualizar lote
- `DELETE /api/lote/<lote_id>` - Eliminar lote
- `GET /usuario/<uuid_segment>/qr` - QR de usuario
- `GET /lote/<lote_id>/qr` - QR de lote

#### QR (searcher_routes.py)
- `GET /api/usuario/<uuid_segment>/qr` - Generar QR de usuario

### ❌ Endpoints Faltantes (14+)

#### Password Reset
```python
# auth_manager_routes.py
@auth_bp.route('/api/auth/forgot-password', methods=['POST'])
def api_forgot_password():
    """
    POST /api/auth/forgot-password
    Body: {"email": "user@example.com"}
    Returns: {"success": true, "message": "Email enviado"}
    """
    pass

@auth_bp.route('/api/auth/reset-password', methods=['POST'])
def api_reset_password():
    """
    POST /api/auth/reset-password
    Body: {"token": "XXX", "new_password": "XXX"}
    Returns: {"success": true}
    """
    pass
```

#### Lotes de Muestras
```python
# lotes_muestras_routes.py (NUEVO)
POST   /api/lotes/create              # Crear lote
GET    /api/lotes/user                # Listar lotes del usuario
GET    /api/lotes/{lote_id}           # Detalle de lote
PUT    /api/lotes/{lote_id}           # Actualizar lote
DELETE /api/lotes/{lote_id}           # Eliminar lote
GET    /api/lotes/{lote_id}/muestras  # Muestras de un lote
```

#### Muestras
```python
# muestras_routes.py (NUEVO)
POST   /api/muestras/create           # Crear muestra
POST   /api/muestras/upload-image     # Subir imagen (multipart/form-data)
POST   /api/muestras/{id}/analyze     # Enviar a clasificador
GET    /api/muestras/{id}/status      # Estado del análisis
PUT    /api/muestras/{id}/validate    # Validar por experto
GET    /api/muestras/{id}             # Detalle de muestra
```

#### Resultados
```python
# resultados_routes.py (NUEVO)
GET    /api/resultados/{muestra_id}   # Resultados de una muestra
PUT    /api/resultados/{id}/correct   # Corregir porcentaje
POST   /api/resultados/export-pdf     # Generar PDF
```

#### Regiones (opcional)
```python
# regiones_routes.py (NUEVO)
GET    /api/regiones/list             # Lista de regiones
GET    /api/regiones/{id}             # Detalle de región
GET    /api/regiones/mapa             # GeoJSON para heatmap
```

---

## 📱 Análisis de Flutter App

### Estructura Actual

```
lib/
├── config/
│   ├── api_config.dart           # URLs y endpoints
│   └── theme_config.dart         # Tema unificado (Amber + Emerald)
├── models/
│   ├── user_model.dart           # Modelo de usuario (15 campos)
│   ├── auth_response.dart
│   ├── session_response.dart
│   └── qr_response.dart
├── providers/
│   └── auth_provider.dart        # Estado de autenticación
├── screens/
│   ├── login_screen.dart         # ✅ Funcional
│   ├── register_screen.dart      # ✅ Funcional
│   ├── home_screen.dart          # ✅ Muestra perfil
│   └── qr_scanner_screen.dart    # ✅ Escanea URLs + códigos
├── services/
│   ├── api_service.dart          # HTTP client (Dio)
│   ├── auth_service.dart         # Lógica de auth
│   └── qr_service.dart           # Procesar QR
└── main.dart
```

### Dependencias Actuales (pubspec.yaml)

```yaml
dependencies:
  flutter_sdk: ^3.9.2
  
  # HTTP & State
  dio: ^5.4.0
  dio_cookie_manager: ^3.1.1
  cookie_jar: ^4.0.8
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  
  # QR & URL
  mobile_scanner: ^5.1.1
  url_launcher: ^6.2.4
  
  # JSON
  json_annotation: ^4.8.1
```

### ❌ Dependencias Faltantes

```yaml
dependencies:
  # === MODO OFFLINE ===
  hive: ^2.2.3              # DB local rápida
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1
  connectivity_plus: ^5.0.2 # Detectar internet
  
  # === IMÁGENES ===
  image_picker: ^1.0.7      # Cámara
  image: ^4.1.7             # Comprimir
  cached_network_image: ^3.3.1  # Cache de imágenes
  
  # === VISUALIZACIONES ===
  fl_chart: ^0.66.2         # Gráficos (pie, bar, line)
  syncfusion_flutter_charts: ^24.2.8  # Charts avanzados
  
  # === MAPAS ===
  google_maps_flutter: ^2.5.3  # Google Maps
  geolocator: ^10.1.0       # GPS
  geocoding: ^2.1.1         # Coords -> Dirección
  permission_handler: ^11.1.0  # Permisos
  
  # === OTROS ===
  intl: ^0.19.0             # Formateo de fechas
  share_plus: ^7.2.2        # Compartir archivos
  pdf: ^3.10.8              # Generar PDFs
  printing: ^5.12.0         # Imprimir PDFs
```

### ❌ Pantallas Faltantes (12+)

```
lib/screens/
├── forgot_password_screen.dart        # NUEVO
├── lotes/
│   ├── lotes_list_screen.dart         # NUEVO - Lista de lotes
│   ├── lote_detail_screen.dart        # NUEVO - Detalle de lote
│   ├── create_lote_screen.dart        # NUEVO - Crear lote
│   └── edit_lote_screen.dart          # NUEVO
├── muestras/
│   ├── muestra_detail_screen.dart     # NUEVO - Detalle con gráfico
│   ├── capture_image_screen.dart      # NUEVO - Capturar foto
│   ├── validate_results_screen.dart   # NUEVO - Validar por experto
│   └── muestra_history_screen.dart    # NUEVO
├── dashboard/
│   ├── dashboard_screen.dart          # NUEVO - Métricas generales
│   └── analytics_screen.dart          # NUEVO - Gráficos avanzados
└── map_screen.dart                    # NUEVO - Mapa con pins
```

### ❌ Modelos Faltantes (4)

```dart
// lib/models/lote_model.dart
class Lote {
  final String id;
  final String codigoLote;
  final DateTime fechaCosecha;
  final String? ubicacionId;
  final double? pesoKg;
  final String estado;
  // ...
}

// lib/models/muestra_model.dart
class Muestra {
  final String id;
  final String loteId;
  final String codigoMuestra;
  final DateTime fechaAnalisis;
  final String? imagenUrl;
  final String estadoProcesamiento;
  final bool validadoPorExperto;
  // ...
}

// lib/models/resultado_polinico_model.dart
class ResultadoPolinico {
  final String id;
  final String muestraId;
  final String especieFloral;
  final double porcentaje;
  final double confidenceScore;
  final bool validadoPorHumano;
  final double? correccionHumana;
  // ...
}

// lib/models/ubicacion_model.dart
class Ubicacion {
  final String id;
  final String nombre;
  final double latitud;
  final double longitud;
  final String normaGeo;
  // ...
}
```

### ❌ Servicios Faltantes (6)

```dart
lib/services/
├── offline_service.dart           # NUEVO - Caché y cola de sync
├── lotes_service.dart             # NUEVO - CRUD lotes
├── muestras_service.dart          # NUEVO - CRUD muestras
├── resultados_service.dart        # NUEVO - CRUD resultados
├── image_service.dart             # NUEVO - Captura y upload
└── location_service.dart          # NUEVO - GPS
```

---

## 🔴 Issues Críticos Identificados

### 1. Password Reset NO Expuesto (Prioridad: Alta)

**Problema**: Backend tiene la función pero no el endpoint REST

**Ubicación**: `auth_manager.py:842`
```python
@staticmethod
def request_password_reset(email: str):
    db.client.auth.api.reset_password_for_email(email)
    # ✅ Funcional pero sin endpoint API
```

**Impacto**: Usuarios bloqueados sin forma de recuperar acceso

**Fix Rápido**:
```python
# auth_manager_routes.py
@auth_bp.route('/api/auth/forgot-password', methods=['POST'])
def api_forgot_password():
    try:
        data = request.get_json()
        email = data.get('email')
        result = AuthManager.request_password_reset(email)
        return jsonify(result), 200 if result['success'] else 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
```

**Tiempo estimado**: 2 horas (backend) + 4 horas (Flutter)

---

### 2. Sistema de Análisis Polínico NO EXISTE (Prioridad: Crítica)

**Problema**: El core del producto no está implementado

**Faltantes**:
- 4 tablas de BD
- 14+ endpoints API
- 12+ pantallas Flutter
- 4 modelos Dart
- 6 servicios Dart
- Integración con clasificador ML

**Impacto**: Sistema no cumple su propósito principal

**Tiempo estimado**: 8-10 semanas (ver roadmap)

---

### 3. Modo Offline NO EXISTE (Prioridad: Alta)

**Problema**: App inútil en zonas rurales sin internet

**Faltantes**:
- Base de datos local (Hive/SQLite)
- Cola de sincronización
- Detección de conectividad
- UI para indicar estado offline

**Impacto**: No usable en campo (caso de uso principal)

**Tiempo estimado**: 2-3 semanas

---

### 4. Iconos NO Integrados (Prioridad: Baja)

**Problema**: 14 iconos PNG en carpeta pero no en Flutter

**Fix**:
1. Copiar `MeliAPP_icons/*.png` a `assets/icons/`
2. Agregar en `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/icons/
```
3. Usar en código:
```dart
Image.asset('assets/icons/bee.png', width: 48)
```

**Tiempo estimado**: 30 minutos

---

## 📈 Métricas de Complejidad

### Backend
- **Líneas de código actuales**: ~3,500
- **Líneas de código estimadas necesarias**: ~2,000
- **Nuevos módulos**: 4 (lotes_muestras, muestras, resultados, regiones)
- **Nuevas migraciones**: 4 tablas + 12 políticas RLS
- **Edge Functions necesarias**: 1 (clasificador)

### Flutter
- **Líneas de código actuales**: ~2,800
- **Líneas de código estimadas necesarias**: ~4,500
- **Nuevas pantallas**: 12
- **Nuevos modelos**: 4
- **Nuevos servicios**: 6
- **Nuevas dependencias**: 15

### Testing
- **Tests unitarios pendientes**: 40+
- **Tests de integración pendientes**: 20+
- **Tests E2E pendientes**: 10+

---

## 🎯 Acciones Inmediatas (Esta Semana)

### Día 1-2: Password Reset
- [ ] Crear endpoint `/api/auth/forgot-password` (2h)
- [ ] Crear pantalla Flutter `forgot_password_screen.dart` (3h)
- [ ] Configurar deep linking para reset (2h)
- [ ] Testing completo (2h)

### Día 3-4: Migraciones de BD
- [ ] Crear migration `create_lotes_muestras_table` (1h)
- [ ] Crear migration `create_muestras_polen_table` (1h)
- [ ] Crear migration `create_resultados_polinicos_table` (1h)
- [ ] Aplicar migraciones en Supabase (30m)
- [ ] Verificar RLS (1h)

### Día 5: Integración de Iconos
- [ ] Copiar iconos a `assets/icons/` (10m)
- [ ] Actualizar `pubspec.yaml` (5m)
- [ ] Crear widget `AppIcon` reutilizable (1h)
- [ ] Actualizar pantallas con iconos custom (2h)

### Día 6-7: Setup Offline
- [ ] Agregar dependencias (hive, connectivity_plus) (30m)
- [ ] Crear `OfflineService` básico (4h)
- [ ] Integrar en `main.dart` (1h)
- [ ] Testing offline simple (2h)

**Total horas semana 1**: ~28h

---

## 📋 Checklist de Documentación

- [x] STRATEGIC_PLAN.md (este documento)
- [x] TECHNICAL_AUDIT.md (documento técnico detallado)
- [x] CHANGELOG.md (ya existe, actualizar)
- [ ] API_DOCS.md (documentar todos los endpoints)
- [ ] OFFLINE_GUIDE.md (guía de modo offline)
- [ ] DEPLOYMENT.md (guía de deploy Vercel)
- [ ] TESTING.md (estrategia de tests)

---

## 🚀 Siguientes Pasos

1. **Revisar con el equipo**: ¿Está alineado con la visión?
2. **Priorizar sprints**: ¿Orden correcto?
3. **Asignar recursos**: ¿Quién hace qué?
4. **Configurar CI/CD**: Automatizar tests y deploys
5. **Iniciar Sprint 1**: Password Reset + BD Structure

---

**Preparado por**: Cascade AI  
**Revisado por**: @Nahzap  
**Próxima revisión**: Fin de Sprint 1
