# Plan Estratégico: MeliAPP Cloud - Sistema de Análisis Polínico
**Versión**: 2.0.0  
**Fecha**: Diciembre 2025  
**Tipo**: Sistema de Campo para Análisis Botánico de Miel

---

## 📊 Análisis de Estado Actual

### ✅ Infraestructura Existente

#### Backend (MeliAPP_v2)
- **Framework**: Flask + Supabase (PostgreSQL)
- **Autenticación**: OAuth Google + Email/Password (Supabase Auth)
- **Deploy**: Vercel (`https://meli-app-cloud.vercel.app`)
- **Arquitectura**: Blueprints modulares (auth, search, lotes, profile, web)

#### Base de Datos Actual
```sql
usuarios (auth_user_id PK, username, tipo_usuario, role, status, activo, fecha_registro, last_login)
├── info_contacto (auth_user_id FK, nombre_completo, empresa, telefono, direccion, comuna, region)
├── ubicaciones (auth_user_id FK, nombre, latitud, longitud, norma_geo, descripcion)
├── origenes_botanicos (auth_user_id FK, orden_miel, nombre_miel, temporada, kg_producidos, composicion)
└── solicitudes_apicultor (auth_user_id FK, nombre_completo, region, comuna, telefono, descripcion_miel)
```

#### Flutter App (MeliAPP_Flutter)
- **Versión**: 1.0.0 (funcional)
- **Screens**: Login, Register, Home, QR Scanner
- **Arquitectura**: Clean Architecture + Provider
- **Características**:
  - Autenticación completa
  - Perfil de usuario (15 campos)
  - Scanner QR (URLs + códigos internos)
  - Tema unificado (Amber + Emerald)
- **Dependencias**: dio, provider, mobile_scanner, url_launcher, shared_preferences

#### Iconos Disponibles (MeliAPP_icons/)
14 iconos PNG de alta calidad:
- `bee.png`, `bee02.png`, `bee03.png` (Abejas)
- `colmena.png`, `colmena02.png` (Colmenas)
- `honey01.png`, `honey02.png` (Miel)
- `pollen01.png`, `pollen02.png`, `pollen03.png` (Polen)
- `apiario01.png`, `apicultor.png` (Apiarios/Apicultores)
- `leaf01.png`, `marker01.png` (Vegetación/Ubicación)

---

## ❌ Gaps Críticos Identificados

### 1. **🔐 Recuperación de Contraseña**
**Estado**: Implementado en backend pero NO expuesto como endpoint

**Backend** (`auth_manager.py:842`):
```python
@staticmethod
def request_password_reset(email: str):
    db.client.auth.api.reset_password_for_email(email)
    # ✅ Funcional pero sin endpoint API REST
```

**Faltante**:
- ❌ Endpoint `/api/auth/forgot-password` (POST)
- ❌ Pantalla "Forgot Password" en Flutter
- ❌ Deep linking para manejar el reset link

---

### 2. **📊 Sistema de Análisis Polínico - NO EXISTE**
**Estado**: CRÍTICO - El corazón del sistema no está implementado

#### Tablas de BD Faltantes:
```sql
-- NUEVA: Lotes de muestras de miel
lotes_muestras (
    id UUID PK,
    auth_user_id UUID FK,
    codigo_lote VARCHAR UNIQUE,
    fecha_cosecha DATE,
    ubicacion_id UUID FK,
    peso_kg NUMERIC,
    estado VARCHAR (pendiente|procesando|completado),
    notas TEXT,
    created_at TIMESTAMPTZ
)

-- NUEVA: Muestras individuales dentro de un lote
muestras_polen (
    id UUID PK,
    lote_id UUID FK,
    codigo_muestra VARCHAR UNIQUE,
    fecha_analisis DATE,
    imagen_microscopio_url TEXT,
    estado_procesamiento VARCHAR (pendiente|analizando|validado),
    validado_por_experto BOOLEAN,
    created_at TIMESTAMPTZ
)

-- NUEVA: Resultados del clasificador de polen
resultados_polinicos (
    id UUID PK,
    muestra_id UUID FK,
    especie_floral VARCHAR,
    porcentaje NUMERIC (CHECK porcentaje >= 0 AND <= 100),
    confidence_score NUMERIC, -- Confianza del modelo IA
    validado_por_humano BOOLEAN,
    correccion_humana NUMERIC, -- Si el experto corrigió el %
    metadata JSONB, -- Datos extra del clasificador
    created_at TIMESTAMPTZ
)

-- NUEVA: Regiones botánicas para mapas
regiones_botanicas (
    id UUID PK,
    nombre VARCHAR,
    codigo_region VARCHAR,
    poligono_geojson JSONB, -- Coordenadas del polígono
    flora_predominante VARCHAR[],
    temporada_floracion VARCHAR[],
    altitud_promedio NUMERIC
)
```

#### Endpoints API Faltantes:
```
POST   /api/lotes/create              - Crear lote de muestras
GET    /api/lotes/user/{user_id}      - Listar lotes del usuario
GET    /api/lotes/{lote_id}           - Detalle de lote

POST   /api/muestras/upload-image     - Subir imagen de microscopio (multipart/form-data)
POST   /api/muestras/{id}/analyze     - Enviar a clasificador (async)
GET    /api/muestras/{id}/status      - Estado del análisis (cola/procesando/listo)
PUT    /api/muestras/{id}/validate    - Validar/corregir resultado por experto

GET    /api/resultados/{muestra_id}   - Obtener resultados polínicos
POST   /api/resultados/export-pdf     - Generar certificado de origen

GET    /api/regiones/mapa             - Datos geográficos para heatmap
```

---

### 3. **📴 Modo Offline - NO IMPLEMENTADO**
**Estado**: CRÍTICO para uso en campo (zonas rurales sin internet)

**Requerimientos**:
- SQLite local para caché de datos
- Queue de sincronización para operaciones offline
- Compresión de imágenes antes de upload
- Indicador visual de estado de sincronización

**Paquetes Flutter necesarios**:
```yaml
sqflite: ^2.3.0           # BD local
path_provider: ^2.1.1     # Rutas de archivos
connectivity_plus: ^5.0.2 # Detectar conectividad
image_picker: ^1.0.7      # Capturar fotos
image: ^4.1.7             # Comprimir imágenes
```

---

### 4. **📈 Visualización de Datos - NO EXISTE**
**Estado**: Necesario para mostrar análisis complejos

**Paquetes Flutter sugeridos**:
```yaml
fl_chart: ^0.66.2         # Gráficos (pie, bar, line)
syncfusion_flutter_charts: ^24.2.8  # Charts profesionales (radar, donut)
google_maps_flutter: ^2.5.3  # Mapas con pins
flutter_map: ^6.1.0       # Alternativa open-source a Google Maps
latlong2: ^0.9.0          # Coordenadas geográficas
```

**Pantallas nuevas requeridas**:
- Dashboard con métricas (home mejorado)
- Gráfico de torta de composición floral
- Lista de historial de lotes (filtros por fecha/región)
- Mapa con pins de muestras
- Heatmap de regiones botánicas

---

### 5. **🌍 Geolocalización - NO INTEGRADO**
**Estado**: Parcialmente implementado (tabla `ubicaciones` existe)

**Faltante en Flutter**:
```yaml
geolocator: ^10.1.0       # GPS del dispositivo
geocoding: ^2.1.1         # Convertir coords a direcciones
permission_handler: ^11.1.0  # Permisos de ubicación
```

**Lógica requerida**:
- Auto-capturar GPS al crear muestra
- Guardar altitud, timestamp, precisión
- Mostrar en mapa la ubicación de cada lote

---

## 🎯 Roadmap de Implementación

### **FASE 1: Fundamentos Críticos** (2-3 semanas)

#### 1.1 Recuperación de Contraseña
**Prioridad**: Alta | **Complejidad**: Baja

**Backend**:
1. Crear endpoint en `auth_manager_routes.py`:
```python
@auth_bp.route('/api/auth/forgot-password', methods=['POST'])
def api_forgot_password():
    data = request.get_json()
    email = data.get('email')
    result = AuthManager.request_password_reset(email)
    return jsonify(result), 200 if result['success'] else 400
```

2. Configurar redirect URL en Supabase Dashboard:
   - `https://meliapp-cloud.vercel.app/reset-password`
   - Crear ruta web para procesar el token

**Flutter**:
1. Crear `lib/screens/forgot_password_screen.dart`:
   - Input de email
   - Llamar a `POST /api/auth/forgot-password`
   - Mostrar mensaje de confirmación

2. Implementar deep linking para `meliapp://reset-password?token=XXX`

**Testing**:
- [ ] Usuario puede solicitar reset desde login screen
- [ ] Email llega correctamente (verificar spam)
- [ ] Link redirige a la app y permite cambiar contraseña

---

#### 1.2 Modo Offline - Estructura Base
**Prioridad**: Alta | **Complejidad**: Media

**Pasos**:
1. Agregar dependencias en `pubspec.yaml`:
```yaml
sqflite: ^2.3.0
path_provider: ^2.1.1
connectivity_plus: ^5.0.2
hive: ^2.2.3  # Alternativa más rápida que SQLite
```

2. Crear `lib/services/offline_service.dart`:
```dart
class OfflineService {
  late Box _cacheBox;
  late Box _queueBox;
  
  Future<void> init() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox('cache');
    _queueBox = await Hive.openBox('sync_queue');
  }
  
  Future<void> cacheData(String key, dynamic data) async {
    await _cacheBox.put(key, data);
  }
  
  Future<dynamic> getCachedData(String key) async {
    return _cacheBox.get(key);
  }
  
  Future<void> queueAction(Map<String, dynamic> action) async {
    await _queueBox.add(action);
  }
  
  Future<void> processQueue() async {
    if (!await ConnectivityService.isOnline()) return;
    
    final items = _queueBox.values.toList();
    for (var item in items) {
      // Procesar cada acción pendiente
      await _syncAction(item);
      await _queueBox.delete(item.key);
    }
  }
}
```

3. Integrar en `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OfflineService().init();
  runApp(MyApp());
}
```

**Testing**:
- [ ] App funciona sin internet (muestra datos en caché)
- [ ] Acciones offline se guardan en cola
- [ ] Sincronización automática al recuperar internet

---

### **FASE 2: Sistema de Análisis Polínico** (4-6 semanas)

#### 2.1 Modelo de Datos y Migraciones
**Prioridad**: Crítica | **Complejidad**: Media

**Pasos**:
1. Crear migraciones en Supabase (usar MCP):
```sql
-- migration: create_lotes_muestras_table
CREATE TABLE lotes_muestras (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    codigo_lote VARCHAR(50) UNIQUE NOT NULL,
    fecha_cosecha DATE NOT NULL,
    ubicacion_id UUID REFERENCES ubicaciones(id),
    peso_kg NUMERIC(10,2),
    estado VARCHAR(20) DEFAULT 'pendiente',
    notas TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_lotes_auth_user ON lotes_muestras(auth_user_id);
CREATE INDEX idx_lotes_estado ON lotes_muestras(estado);

-- RLS Policies
ALTER TABLE lotes_muestras ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own lotes"
ON lotes_muestras FOR SELECT
USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can create their own lotes"
ON lotes_muestras FOR INSERT
WITH CHECK (auth.uid() = auth_user_id);
```

2. Repetir para `muestras_polen`, `resultados_polinicos`, `regiones_botanicas`

**Testing**:
- [ ] Tablas creadas correctamente
- [ ] RLS funciona (usuario solo ve sus datos)
- [ ] Foreign keys correctas

---

#### 2.2 Backend - Endpoints de Lotes
**Prioridad**: Alta | **Complejidad**: Media

**Crear** `lotes_muestras_routes.py`:
```python
from flask import Blueprint, request, jsonify, g
from auth_manager import AuthManager
from supabase_client import db

lotes_bp = Blueprint('lotes_muestras', __name__, url_prefix='/api')

@lotes_bp.route('/lotes/create', methods=['POST'])
@AuthManager.login_required
def create_lote():
    """
    POST /api/lotes/create
    Body: {
        "codigo_lote": "L2025-001",
        "fecha_cosecha": "2025-01-15",
        "ubicacion_id": "uuid",
        "peso_kg": 25.5,
        "notas": "Cosecha de verano"
    }
    """
    try:
        data = request.get_json()
        auth_user_id = g.user['id']
        
        # Validar campos requeridos
        required = ['codigo_lote', 'fecha_cosecha']
        if not all(k in data for k in required):
            return jsonify({'success': False, 'error': 'Campos requeridos faltantes'}), 400
        
        # Insertar en BD
        lote = db.client.table('lotes_muestras').insert({
            'auth_user_id': auth_user_id,
            **data
        }).execute()
        
        return jsonify({'success': True, 'lote': lote.data[0]}), 201
        
    except Exception as e:
        logger.error(f"Error creando lote: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@lotes_bp.route('/lotes/user', methods=['GET'])
@AuthManager.login_required
def get_user_lotes():
    """GET /api/lotes/user - Lista todos los lotes del usuario autenticado"""
    try:
        auth_user_id = g.user['id']
        
        lotes = db.client.table('lotes_muestras') \
            .select('*, ubicaciones(nombre, latitud, longitud)') \
            .eq('auth_user_id', auth_user_id) \
            .order('created_at', desc=True) \
            .execute()
        
        return jsonify({'success': True, 'lotes': lotes.data}), 200
        
    except Exception as e:
        logger.error(f"Error obteniendo lotes: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500
```

**Registrar en `app.py`**:
```python
from lotes_muestras_routes import lotes_bp
app.register_blueprint(lotes_bp)
```

**Testing**:
- [ ] POST `/api/lotes/create` funciona
- [ ] GET `/api/lotes/user` retorna solo lotes del usuario
- [ ] Validaciones funcionan correctamente

---

#### 2.3 Flutter - Pantallas de Lotes
**Prioridad**: Alta | **Complejidad**: Media-Alta

**Estructura de archivos**:
```
lib/
├── models/
│   ├── lote_model.dart
│   ├── muestra_model.dart
│   └── resultado_polinico_model.dart
├── screens/
│   ├── lotes_list_screen.dart
│   ├── lote_detail_screen.dart
│   ├── create_lote_screen.dart
│   └── muestra_detail_screen.dart
├── services/
│   └── lotes_service.dart
└── widgets/
    ├── lote_card.dart
    └── composition_chart.dart
```

**1. Modelo de Lote** (`lib/models/lote_model.dart`):
```dart
class Lote {
  final String id;
  final String codigoLote;
  final DateTime fechaCosecha;
  final String? ubicacionId;
  final double? pesoKg;
  final String estado; // pendiente, procesando, completado
  final String? notas;
  final DateTime createdAt;

  Lote({
    required this.id,
    required this.codigoLote,
    required this.fechaCosecha,
    this.ubicacionId,
    this.pesoKg,
    required this.estado,
    this.notas,
    required this.createdAt,
  });

  factory Lote.fromJson(Map<String, dynamic> json) {
    return Lote(
      id: json['id'],
      codigoLote: json['codigo_lote'],
      fechaCosecha: DateTime.parse(json['fecha_cosecha']),
      ubicacionId: json['ubicacion_id'],
      pesoKg: json['peso_kg']?.toDouble(),
      estado: json['estado'] ?? 'pendiente',
      notas: json['notas'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
```

**2. Servicio de Lotes** (`lib/services/lotes_service.dart`):
```dart
class LotesService {
  final ApiService _apiService = ApiService();

  Future<List<Lote>> getUserLotes() async {
    try {
      final response = await _apiService.get('/lotes/user');
      if (response['success']) {
        return (response['lotes'] as List)
            .map((json) => Lote.fromJson(json))
            .toList();
      }
      throw Exception(response['error'] ?? 'Error obteniendo lotes');
    } catch (e) {
      debugPrint('[LOTES] Error: $e');
      rethrow;
    }
  }

  Future<Lote> createLote(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/lotes/create', data);
      if (response['success']) {
        return Lote.fromJson(response['lote']);
      }
      throw Exception(response['error'] ?? 'Error creando lote');
    } catch (e) {
      debugPrint('[LOTES] Error creando: $e');
      rethrow;
    }
  }
}
```

**3. Pantalla Lista de Lotes** (`lib/screens/lotes_list_screen.dart`):
```dart
class LotesListScreen extends StatefulWidget {
  @override
  State<LotesListScreen> createState() => _LotesListScreenState();
}

class _LotesListScreenState extends State<LotesListScreen> {
  final LotesService _lotesService = LotesService();
  List<Lote> _lotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLotes();
  }

  Future<void> _loadLotes() async {
    setState(() => _isLoading = true);
    try {
      final lotes = await _lotesService.getUserLotes();
      setState(() {
        _lotes = lotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando lotes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Lotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lotes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lotes.length,
                  itemBuilder: (context, index) {
                    final lote = _lotes[index];
                    return LoteCard(
                      lote: lote,
                      onTap: () => _navigateToDetail(lote),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/lotes/create'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Lote'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/icons/honey01.png', width: 120),
          const SizedBox(height: 24),
          Text(
            'No tienes lotes registrados',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer lote para comenzar',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
```

**Testing**:
- [ ] Lista muestra lotes correctamente
- [ ] Empty state aparece cuando no hay lotes
- [ ] Navegación a detalle funciona
- [ ] Refresh funciona correctamente

---

### **FASE 3: Captura y Análisis de Imágenes** (3-4 semanas)

#### 3.1 Upload de Imágenes de Microscopio
**Prioridad**: Alta | **Complejidad**: Alta

**Backend - Storage en Supabase**:
```python
@muestras_bp.route('/muestras/upload-image', methods=['POST'])
@AuthManager.login_required
def upload_image():
    """
    POST /api/muestras/upload-image
    Content-Type: multipart/form-data
    Body: {
        "muestra_id": "uuid",
        "image": File
    }
    """
    try:
        if 'image' not in request.files:
            return jsonify({'success': False, 'error': 'No image provided'}), 400
        
        file = request.files['image']
        muestra_id = request.form.get('muestra_id')
        
        # Validar que la muestra pertenece al usuario
        auth_user_id = g.user['id']
        muestra = db.client.table('muestras_polen') \
            .select('lote_id, lotes_muestras(auth_user_id)') \
            .eq('id', muestra_id) \
            .single() \
            .execute()
        
        if muestra.data['lotes_muestras']['auth_user_id'] != auth_user_id:
            return jsonify({'success': False, 'error': 'Unauthorized'}), 403
        
        # Subir a Supabase Storage
        filename = f"{muestra_id}_{int(time.time())}.jpg"
        storage_path = f"muestras/{auth_user_id}/{filename}"
        
        db.client.storage.from_('microscopio-images').upload(
            storage_path,
            file.read(),
            file_options={"content-type": file.content_type}
        )
        
        # Obtener URL pública
        public_url = db.client.storage.from_('microscopio-images').get_public_url(storage_path)
        
        # Actualizar muestra con URL
        db.client.table('muestras_polen').update({
            'imagen_microscopio_url': public_url
        }).eq('id', muestra_id).execute()
        
        # **IMPORTANTE**: Encolar para análisis del clasificador
        await _queue_for_classification(muestra_id, public_url)
        
        return jsonify({
            'success': True,
            'url': public_url,
            'message': 'Imagen subida. Análisis en cola.'
        }), 200
        
    except Exception as e:
        logger.error(f"Error uploading image: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500
```

**Flutter - Captura y Upload**:
```dart
// lib/services/image_service.dart
class ImageService {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  Future<String?> captureAndUpload(String muestraId) async {
    try {
      // Capturar imagen
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Comprimir para ahorrar datos
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image == null) return null;
      
      // Comprimir aún más si es necesario
      final compressedImage = await _compressImage(File(image.path));
      
      // Preparar multipart request
      final formData = FormData.fromMap({
        'muestra_id': muestraId,
        'image': await MultipartFile.fromFile(
          compressedImage.path,
          filename: 'muestra_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      
      // Upload
      final response = await _apiService.dio.post(
        '/muestras/upload-image',
        data: formData,
        onSendProgress: (sent, total) {
          debugPrint('[UPLOAD] $sent / $total bytes');
        },
      );
      
      if (response.data['success']) {
        return response.data['url'];
      }
      
      throw Exception(response.data['error'] ?? 'Upload failed');
      
    } catch (e) {
      debugPrint('[IMAGE] Error uploading: $e');
      rethrow;
    }
  }
  
  Future<File> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final img = img_lib.decodeImage(bytes);
    
    if (img == null) return file;
    
    // Reducir tamaño si es muy grande
    final resized = img_lib.copyResize(img, width: 1920);
    final compressed = img_lib.encodeJpg(resized, quality: 70);
    
    final compressedFile = File(file.path)..writeAsBytesSync(compressed);
    return compressedFile;
  }
}
```

**Testing**:
- [ ] Cámara se abre correctamente
- [ ] Imagen se comprime antes de subir
- [ ] Progress indicator funciona
- [ ] URL pública se retorna correctamente
- [ ] Imagen visible en Supabase Storage

---

#### 3.2 Integración con Clasificador de Polen (Backend)
**Prioridad**: Crítica | **Complejidad**: Alta

**Opciones de Implementación**:

**Opción A: Edge Function en Supabase (Recomendado)**
```typescript
// supabase/functions/classify-pollen/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { muestra_id, image_url } = await req.json()
    
    // Llamar a modelo de ML (TensorFlow Serving, HuggingFace, o custom API)
    const mlResponse = await fetch('https://YOUR-ML-API.com/classify', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ image_url })
    })
    
    const predictions = await mlResponse.json()
    // predictions = [{especie: "Ulmo", porcentaje: 65.3, confidence: 0.89}, ...]
    
    // Guardar resultados en BD
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )
    
    for (const pred of predictions) {
      await supabase.from('resultados_polinicos').insert({
        muestra_id: muestra_id,
        especie_floral: pred.especie,
        porcentaje: pred.porcentaje,
        confidence_score: pred.confidence,
        validado_por_humano: false
      })
    }
    
    // Actualizar estado de muestra
    await supabase.from('muestras_polen').update({
      estado_procesamiento: 'completado'
    }).eq('id', muestra_id)
    
    return new Response(
      JSON.stringify({ success: true, predictions }),
      { headers: { "Content-Type": "application/json" } }
    )
    
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
```

**Opción B: Tarea Async en Flask (Celery/RQ)**
```python
# classify_worker.py
from rq import Queue
from redis import Redis
import requests

redis_conn = Redis.from_url(os.getenv('REDIS_URL'))
queue = Queue('pollen-classification', connection=redis_conn)

def classify_pollen_task(muestra_id, image_url):
    """Worker task para clasificación de polen"""
    try:
        # Llamar a servicio de ML
        ml_response = requests.post('https://ML-API/classify', json={
            'image_url': image_url
        })
        predictions = ml_response.json()['predictions']
        
        # Guardar resultados
        for pred in predictions:
            db.client.table('resultados_polinicos').insert({
                'muestra_id': muestra_id,
                'especie_floral': pred['especie'],
                'porcentaje': pred['porcentaje'],
                'confidence_score': pred['confidence']
            }).execute()
        
        # Actualizar estado
        db.client.table('muestras_polen').update({
            'estado_procesamiento': 'completado'
        }).eq('id', muestra_id).execute()
        
        return {'success': True, 'predictions': predictions}
        
    except Exception as e:
        logger.error(f"Error en clasificación: {e}")
        # Marcar muestra como fallida
        db.client.table('muestras_polen').update({
            'estado_procesamiento': 'error'
        }).eq('id', muestra_id).execute()
        raise

# En auth_manager_routes.py
@muestras_bp.route('/muestras/<muestra_id>/analyze', methods=['POST'])
@AuthManager.login_required
def analyze_muestra(muestra_id):
    """Encola una muestra para análisis"""
    try:
        # Obtener URL de imagen
        muestra = db.client.table('muestras_polen') \
            .select('imagen_microscopio_url') \
            .eq('id', muestra_id) \
            .single() \
            .execute()
        
        image_url = muestra.data['imagen_microscopio_url']
        
        # Encolar tarea
        job = queue.enqueue(classify_pollen_task, muestra_id, image_url)
        
        # Actualizar estado a "analizando"
        db.client.table('muestras_polen').update({
            'estado_procesamiento': 'analizando'
        }).eq('id', muestra_id).execute()
        
        return jsonify({
            'success': True,
            'job_id': job.id,
            'message': 'Análisis en proceso'
        }), 202  # Accepted
        
    except Exception as e:
        logger.error(f"Error encolando análisis: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500
```

**Testing**:
- [ ] Imagen se envía al clasificador
- [ ] Resultados se guardan correctamente
- [ ] Estado de muestra se actualiza
- [ ] Manejo de errores funciona

---

### **FASE 4: Dashboard y Visualizaciones** (3-4 semanas)

#### 4.1 Gráficos de Composición Floral
**Prioridad**: Alta | **Complejidad**: Media

**Instalar** `fl_chart`:
```yaml
dependencies:
  fl_chart: ^0.66.2
```

**Widget de Pie Chart**:
```dart
// lib/widgets/composition_pie_chart.dart
class CompositionPieChart extends StatelessWidget {
  final List<ResultadoPolinico> resultados;

  const CompositionPieChart({required this.resultados});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: _buildSections(),
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        borderData: FlBorderData(show: false),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    // Colores para diferentes especies
    final colors = [
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
    ];

    return resultados.asMap().entries.map((entry) {
      final index = entry.key;
      final resultado = entry.value;
      
      return PieChartSectionData(
        value: resultado.porcentaje,
        title: '${resultado.porcentaje.toStringAsFixed(1)}%',
        color: colors[index % colors.length],
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
```

**Pantalla de Detalle de Muestra**:
```dart
// lib/screens/muestra_detail_screen.dart
class MuestraDetailScreen extends StatefulWidget {
  final String muestraId;

  const MuestraDetailScreen({required this.muestraId});

  @override
  State<MuestraDetailScreen> createState() => _MuestraDetailScreenState();
}

class _MuestraDetailScreenState extends State<MuestraDetailScreen> {
  Muestra? _muestra;
  List<ResultadoPolinico> _resultados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Cargar muestra y resultados desde API
    setState(() => _isLoading = true);
    try {
      final muestra = await MuestrasService().getMuestra(widget.muestraId);
      final resultados = await ResultadosService().getResultados(widget.muestraId);
      
      setState(() {
        _muestra = muestra;
        _resultados = resultados;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Mostrar error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Muestra ${_muestra?.codigoMuestra ?? ''}'),
        actions: [
          if (!_muestra!.validadoPorExperto)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _validateResults,
              tooltip: 'Validar resultados',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Imagen de microscopio
            if (_muestra?.imagenMicroscopioUrl != null)
              Image.network(
                _muestra!.imagenMicroscopioUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            
            const SizedBox(height: 16),
            
            // Info de la muestra
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Código: ${_muestra!.codigoMuestra}'),
                    Text('Fecha análisis: ${_formatDate(_muestra!.fechaAnalisis)}'),
                    Text('Estado: ${_muestra!.estadoProcesamiento}'),
                  ],
                ),
              ),
            ),
            
            // Gráfico de composición
            if (_resultados.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Composición Floral',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              SizedBox(
                height: 300,
                child: CompositionPieChart(resultados: _resultados),
              ),
              
              // Leyenda
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _resultados.map((r) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getColor(r.especieFloral),
                      radius: 10,
                    ),
                    title: Text(r.especieFloral),
                    trailing: Text('${r.porcentaje.toStringAsFixed(1)}%'),
                    subtitle: r.validadoPorHumano
                        ? const Text('✓ Validado', style: TextStyle(color: Colors.green))
                        : Text('Confianza: ${(r.confidenceScore * 100).toStringAsFixed(0)}%'),
                  )).toList(),
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Sin resultados disponibles'),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportPDF,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Exportar PDF'),
      ),
    );
  }

  void _validateResults() {
    // Navegar a pantalla de validación
    Navigator.pushNamed(context, '/muestras/validate', arguments: {
      'muestra_id': widget.muestraId,
      'resultados': _resultados,
    });
  }

  Future<void> _exportPDF() async {
    // Llamar a API para generar PDF
    try {
      final pdf = await ResultadosService().exportPDF(widget.muestraId);
      // Abrir PDF o compartir
      await Share.share(pdf.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exportando PDF: $e')),
      );
    }
  }
}
```

**Testing**:
- [ ] Gráfico muestra correctamente los porcentajes
- [ ] Leyenda coincide con los colores
- [ ] Navegación a validación funciona
- [ ] Export PDF funciona

---

### **FASE 5: Mapas y Geolocalización** (2-3 semanas)

#### 5.1 Integración de Google Maps
**Prioridad**: Media | **Complejidad**: Media

**Configuración**:
1. Obtener API Key de Google Cloud Console
2. Agregar a `AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

3. Agregar dependencia:
```yaml
google_maps_flutter: ^2.5.3
geolocator: ^10.1.0
geocoding: ^2.1.1
```

**Pantalla de Mapa**:
```dart
// lib/screens/map_screen.dart
class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadLotesMarkers();
  }

  Future<void> _getCurrentLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() => _currentPosition = position);

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 12,
        ),
      ),
    );
  }

  Future<void> _loadLotesMarkers() async {
    final lotes = await LotesService().getUserLotes();
    
    final markers = lotes.where((l) => l.ubicacion != null).map((lote) {
      return Marker(
        markerId: MarkerId(lote.id),
        position: LatLng(
          lote.ubicacion!.latitud,
          lote.ubicacion!.longitud,
        ),
        infoWindow: InfoWindow(
          title: lote.codigoLote,
          snippet: '${lote.pesoKg} kg - ${lote.estado}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerColor(lote.estado),
        ),
        onTap: () => _navigateToLote(lote),
      );
    }).toSet();

    setState(() => _markers = markers);
  }

  double _getMarkerColor(String estado) {
    switch (estado) {
      case 'completado':
        return BitmapDescriptor.hueGreen;
      case 'procesando':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Lotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 12,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onMapCreated: (controller) => _mapController = controller,
            ),
    );
  }
}
```

**Testing**:
- [ ] Mapa se carga correctamente
- [ ] Marcadores aparecen en ubicaciones correctas
- [ ] Tap en marcador muestra info
- [ ] Botón "My Location" funciona

---

## 📋 Checklist de Implementación Completa

### Backend
- [ ] Endpoint `/api/auth/forgot-password`
- [ ] Tablas: `lotes_muestras`, `muestras_polen`, `resultados_polinicos`, `regiones_botanicas`
- [ ] RLS Policies en todas las tablas
- [ ] Endpoints CRUD para lotes
- [ ] Endpoints para muestras (upload, analyze, validate)
- [ ] Storage bucket para imágenes de microscopio
- [ ] Edge Function o Worker para clasificador
- [ ] Endpoint para export PDF

### Flutter
- [ ] Modo offline (Hive + Queue)
- [ ] Pantalla "Forgot Password"
- [ ] Deep linking para reset password
- [ ] Lista de lotes (filtros, búsqueda)
- [ ] Detalle de lote
- [ ] Crear lote (GPS automático)
- [ ] Captura de imagen de microscopio
- [ ] Upload con progress indicator
- [ ] Detalle de muestra con gráfico
- [ ] Validación de resultados por experto
- [ ] Mapa con marcadores de lotes
- [ ] Export y share de PDFs

### Visualizaciones
- [ ] Pie chart de composición
- [ ] Bar chart de kg producidos por temporada
- [ ] Line chart de historial de pureza
- [ ] Radar chart para comparar mieles
- [ ] Heatmap de regiones botánicas

### Testing
- [ ] Tests unitarios de servicios
- [ ] Tests de integración de API
- [ ] Tests de UI (widget tests)
- [ ] Tests de modo offline
- [ ] Tests de compresión de imágenes
- [ ] Tests de sincronización

---

## 🚀 Priorización Final

### Sprint 1 (Semana 1-2)
1. Forgot Password (Backend + Flutter)
2. Estructura de BD para lotes
3. Endpoints básicos de lotes
4. Modo offline - estructura base

### Sprint 2 (Semana 3-4)
1. Pantallas Flutter de lotes (lista, detalle, crear)
2. Upload de imágenes
3. GPS automático al crear muestra

### Sprint 3 (Semana 5-6)
1. Integración con clasificador
2. Guardar resultados en BD
3. Polling de estado de análisis

### Sprint 4 (Semana 7-8)
1. Gráficos de composición (pie, bar)
2. Dashboard con métricas
3. Validación de resultados por experto

### Sprint 5 (Semana 9-10)
1. Mapa con pins de lotes
2. Heatmap de regiones botánicas
3. Export PDF de certificados

### Sprint 6 (Semana 11-12)
1. Pulido de modo offline
2. Testing exhaustivo
3. Optimización de performance
4. Documentación final

---

## 📚 Recursos Adicionales

### Documentación de Referencia
- [Supabase Storage Docs](https://supabase.com/docs/guides/storage)
- [Flutter Offline-First Guide](https://docs.flutter.dev/cookbook/persistence)
- [fl_chart Examples](https://pub.dev/packages/fl_chart#getting-started)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)

### Arquitectura de Clasificador ML
Si no tienes un modelo de clasificación de polen, considera:
- **HuggingFace Models**: Modelos pre-entrenados de visión
- **TensorFlow Lite**: Para correr inferencia en el dispositivo
- **Roboflow**: Plataforma para entrenar modelos custom
- **YOLOv8**: Para detección de objetos en imágenes

### Almacenamiento de Imágenes
- **Supabase Storage**: Gratis hasta 1GB, luego $0.021/GB/mes
- **Cloudinary**: Gratis hasta 25 créditos/mes
- **AWS S3**: Pay-as-you-go

---

## ✅ Criterios de Éxito

La implementación será exitosa cuando:

1. **Usuario Apicultor** puede:
   - Crear lote en campo sin internet
   - Tomar foto de microscopio y subirla
   - Ver resultados del clasificador en gráfico
   - Validar/corregir porcentajes si es experto
   - Exportar PDF para compartir con compradores

2. **Usuario Comprador** puede:
   - Escanear QR del lote
   - Ver composición floral verificada
   - Visualizar origen geográfico en mapa
   - Descargar certificado de pureza

3. **Sistema** cumple:
   - 95%+ uptime
   - Respuesta < 2s para queries simples
   - Análisis de imagen < 30s
   - Funciona offline (sync automático)
   - Datos encriptados en tránsito y reposo

---

**Fin del Plan Estratégico**  
**Última actualización**: Diciembre 2025  
**Autor**: Cascade AI + @Nahzap  
**Versión**: 2.0.0
