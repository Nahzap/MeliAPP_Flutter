# Plan Estratégico REVISADO: MeliAPP Cloud Flutter
**Versión**: 2.1.0  
**Fecha**: 1 Diciembre 2025  
**Tipo**: Integración Flutter con Backend Existente

---

## 🎯 Objetivo Corregido

Desarrollar la aplicación Flutter que **consuma los datos EXISTENTES** del backend MeliAPP_v2, replicando la funcionalidad de la versión web para mostrar:
- Lotes de miel del usuario
- Composición botánica por lote
- Clases botánicas por comuna
- Visualizaciones con gráficos

**NO se requiere**: Sistema de análisis polínico nuevo, modo offline, ni upload de imágenes de microscopio.

---

## ✅ Infraestructura Existente (CORRECTA)

### Backend Endpoints Disponibles

```python
# LOTES (origenes_botanicos table)
GET    /api/lotes/<usuario_id>              # Lista lotes públicos del usuario
GET    /api/lote/<lote_id>                  # Detalle de un lote
GET    /api/lote/composicion/<lote_id>     # Solo composición de un lote
POST   /api/gestionar-lote                  # Crear lote (auth requerido)
PUT    /api/lote/<lote_id>                  # Actualizar lote (auth requerido)
DELETE /api/lote/<lote_id>                  # Eliminar lote (auth requerido)
GET    /api/lote/<lote_id>/qr               # QR del lote (auth requerido)

# CLASES BOTÁNICAS
GET    /api/botanical-classes/<comuna>     # Clases botánicas por comuna

# USUARIO
GET    /api/profile/me                     # Perfil completo (auth requerido)
GET    /api/usuario-info/<usuario_id>      # Info + especies por zona
```

### Tabla Real: `origenes_botanicos`

```sql
CREATE TABLE origenes_botanicos (
    id UUID PRIMARY KEY,
    auth_user_id UUID REFERENCES auth.users(id),
    orden_miel INTEGER NOT NULL,           -- Orden del lote (1, 2, 3...)
    nombre_miel VARCHAR NOT NULL,          -- Nombre: "test01", "test6", etc.
    temporada VARCHAR NOT NULL,            -- "PRIMAVERA - VERANO - OTOÑO"
    kg_producidos NUMERIC,                 -- Kilos producidos
    composicion TEXT,                      -- "Maitén:40, Notro:30, Michay:20"
    fecha_registro TIMESTAMPTZ,
    fecha_actualizacion TIMESTAMPTZ
);
```

**Ejemplo de datos reales**:
```json
{
  "id": "73bc9621-d8a6-4f57-a699-9137dcaa3a72",
  "orden_miel": 1,
  "nombre_miel": "test01",
  "temporada": "PRIMAVERA - VERANO - OTOÑO - INVIERNO",
  "kg_producidos": "279.00",
  "composicion": "Maiten:40, Notro:30, Michay:20, Avellano Chileno:10",
  "fecha_registro": "2022-08-19T00:00:00+00:00"
}
```

### Formato del Campo `composicion`

```
"Especie1:porcentaje1, Especie2:porcentaje2, Especie3:porcentaje3"

Ejemplos:
- "Maiten:40, Notro:30, Michay:20, Avellano Chileno:10"
- "Avellano Chileno:100"
- "Matico:25, Chaura:40, Otras Especies:35"
- "Diente de Leon:50, Crepis:50"
```

---

## ❌ Gaps Reales Identificados

### 1. **Password Reset** (Backend funcional pero sin endpoint)
- ✅ Función existe: `AuthManager.request_password_reset()`
- ❌ NO hay endpoint `/api/auth/forgot-password`
- ❌ NO hay pantalla Flutter

### 2. **Flutter NO consume endpoints existentes**
- ❌ NO hay modelos para lotes (`origenes_botanicos`)
- ❌ NO hay servicio para lotes
- ❌ NO hay pantallas de lotes
- ❌ NO parsea campo `composicion`

### 3. **Visualizaciones NO implementadas en Flutter**
- ❌ NO hay gráfico pie chart de composición
- ❌ NO hay lista de lotes
- ❌ NO hay dashboard con métricas
- ❌ NO hay mapa con ubicaciones

### 4. **Iconos NO integrados**
- ✅ 14 iconos PNG disponibles en `MeliAPP_icons/`
- ❌ NO copiados a `assets/icons/`
- ❌ NO declarados en `pubspec.yaml`

---

## 📋 Roadmap Corregido (6 semanas)

### **SPRINT 1: Fundamentos** (Semana 1-2)

#### 1.1 Password Reset (2 días)
**Backend**:
```python
# auth_manager_routes.py
@auth_bp.route('/api/auth/forgot-password', methods=['POST'])
def api_forgot_password():
    """POST /api/auth/forgot-password - Body: {"email": "user@example.com"}"""
    try:
        data = request.get_json()
        email = data.get('email')
        if not email:
            return jsonify({'success': False, 'error': 'Email requerido'}), 400
        
        result = AuthManager.request_password_reset(email)
        return jsonify(result), 200 if result['success'] else 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
```

**Flutter**:
```dart
// lib/screens/forgot_password_screen.dart
class ForgotPasswordScreen extends StatefulWidget {
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _requestReset() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.post('/auth/forgot-password', {
        'email': _emailController.text.trim(),
      });
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email enviado. Revisa tu correo.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'tu@email.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _requestReset,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Enviar Email de Recuperación'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Testing**:
- [ ] Endpoint funciona con email válido
- [ ] Email llega correctamente
- [ ] Pantalla Flutter muestra y funciona
- [ ] Link de "¿Olvidaste tu contraseña?" en login screen

---

#### 1.2 Integración de Iconos (0.5 día)

**Pasos**:
1. Copiar iconos a proyecto Flutter:
```bash
mkdir -p assets/icons
cp MeliAPP_icons/*.png assets/icons/
```

2. Actualizar `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/icons/
```

3. Crear widget helper:
```dart
// lib/widgets/app_icon.dart
class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const AppIcon(this.name, {this.size = 48, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/$name.png',
      width: size,
      height: size,
      color: color,
      errorBuilder: (_, __, ___) => Icon(Icons.error, size: size),
    );
  }
}

// Uso:
AppIcon('bee', size: 64)
AppIcon('honey01', size: 48, color: Colors.amber)
```

**Iconos disponibles**:
- `bee.png`, `bee02.png`, `bee03.png`
- `colmena.png`, `colmena02.png`
- `honey01.png`, `honey02.png`
- `pollen01.png`, `pollen02.png`, `pollen03.png`
- `apiario01.png`, `apicultor.png`
- `leaf01.png`, `marker01.png`

---

#### 1.3 Modelos de Lote (1 día)

```dart
// lib/models/lote_model.dart
class Lote {
  final String id;
  final String authUserId;
  final int ordenMiel;
  final String nombreMiel;
  final String temporada;
  final double? kgProducidos;
  final String? composicion;
  final DateTime? fechaRegistro;
  final DateTime? fechaActualizacion;

  Lote({
    required this.id,
    required this.authUserId,
    required this.ordenMiel,
    required this.nombreMiel,
    required this.temporada,
    this.kgProducidos,
    this.composicion,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  factory Lote.fromJson(Map<String, dynamic> json) {
    return Lote(
      id: json['id'],
      authUserId: json['auth_user_id'],
      ordenMiel: json['orden_miel'],
      nombreMiel: json['nombre_miel'],
      temporada: json['temporada'],
      kgProducidos: json['kg_producidos'] != null 
          ? double.tryParse(json['kg_producidos'].toString()) 
          : null,
      composicion: json['composicion'],
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.parse(json['fecha_registro'])
          : null,
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'])
          : null,
    );
  }

  /// Parsea el campo composicion en un mapa {Especie: Porcentaje}
  Map<String, double> parseComposicion() {
    if (composicion == null || composicion!.isEmpty) return {};
    
    final result = <String, double>{};
    final items = composicion!.split(',');
    
    for (var item in items) {
      final parts = item.trim().split(':');
      if (parts.length == 2) {
        final especie = parts[0].trim();
        final porcentaje = double.tryParse(parts[1].trim()) ?? 0.0;
        result[especie] = porcentaje;
      }
    }
    
    return result;
  }

  /// Retorna el total de la composición (debería ser ~100%)
  double getTotalComposicion() {
    return parseComposicion().values.fold(0.0, (sum, val) => sum + val);
  }

  /// Lista de especies ordenadas por porcentaje descendente
  List<MapEntry<String, double>> getEspeciesOrdenadas() {
    final comp = parseComposicion();
    final entries = comp.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}
```

---

#### 1.4 Servicio de Lotes (1 día)

```dart
// lib/services/lotes_service.dart
class LotesService {
  final ApiService _apiService = ApiService();

  /// Obtiene todos los lotes de un usuario (público)
  Future<List<Lote>> getLotesUsuario(String userId) async {
    try {
      final response = await _apiService.get('/lotes/$userId');
      
      if (response['success']) {
        final lotes = (response['lotes'] as List)
            .map((json) => Lote.fromJson(json))
            .toList();
        
        // Ordenar por orden_miel
        lotes.sort((a, b) => a.ordenMiel.compareTo(b.ordenMiel));
        
        debugPrint('[LOTES] Cargados ${lotes.length} lotes para usuario $userId');
        return lotes;
      }
      
      throw Exception(response['error'] ?? 'Error obteniendo lotes');
    } catch (e) {
      debugPrint('[LOTES] Error: $e');
      rethrow;
    }
  }

  /// Obtiene un lote específico
  Future<Lote> getLote(String loteId) async {
    try {
      final response = await _apiService.get('/lote/$loteId');
      
      if (response['success']) {
        return Lote.fromJson(response['data']);
      }
      
      throw Exception(response['error'] ?? 'Lote no encontrado');
    } catch (e) {
      debugPrint('[LOTES] Error obteniendo lote $loteId: $e');
      rethrow;
    }
  }

  /// Obtiene solo la composición de un lote
  Future<String> getComposicion(String loteId) async {
    try {
      final response = await _apiService.get('/lote/composicion/$loteId');
      
      if (response['success']) {
        return response['composicion'] ?? '';
      }
      
      throw Exception(response['error'] ?? 'Composición no encontrada');
    } catch (e) {
      debugPrint('[LOTES] Error obteniendo composición: $e');
      rethrow;
    }
  }

  /// Crea un nuevo lote (requiere autenticación)
  Future<Lote> createLote(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/gestionar-lote', data);
      
      if (response['success']) {
        return Lote.fromJson(response['lote']);
      }
      
      throw Exception(response['error'] ?? 'Error creando lote');
    } catch (e) {
      debugPrint('[LOTES] Error creando: $e');
      rethrow;
    }
  }

  /// Actualiza un lote existente (requiere autenticación)
  Future<Lote> updateLote(String loteId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/lote/$loteId', data);
      
      if (response['success']) {
        return Lote.fromJson(response['lote']);
      }
      
      throw Exception(response['error'] ?? 'Error actualizando lote');
    } catch (e) {
      debugPrint('[LOTES] Error actualizando: $e');
      rethrow;
    }
  }

  /// Elimina un lote (requiere autenticación)
  Future<bool> deleteLote(String loteId) async {
    try {
      final response = await _apiService.delete('/lote/$loteId');
      return response['success'] ?? false;
    } catch (e) {
      debugPrint('[LOTES] Error eliminando: $e');
      rethrow;
    }
  }
}
```

---

### **SPRINT 2: Pantallas de Lotes** (Semana 3-4)

#### 2.1 Lista de Lotes (3 días)

```dart
// lib/screens/lotes/lotes_list_screen.dart
class LotesListScreen extends StatefulWidget {
  final String? userId; // null = usuario actual, string = usuario específico

  const LotesListScreen({this.userId});

  @override
  State<LotesListScreen> createState() => _LotesListScreenState();
}

class _LotesListScreenState extends State<LotesListScreen> {
  final LotesService _lotesService = LotesService();
  List<Lote> _lotes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLotes();
  }

  Future<void> _loadLotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = widget.userId ?? Provider.of<AuthProvider>(context, listen: false).user?.id;
      
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final lotes = await _lotesService.getLotesUsuario(userId);
      
      setState(() {
        _lotes = lotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Lotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLotes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _lotes.isEmpty
                  ? _buildEmptyState()
                  : _buildLotesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/lotes/create'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Lote'),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadLotes,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon('honey01', size: 120),
          const SizedBox(height: 24),
          Text(
            'No tienes lotes registrados',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer lote para comenzar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/lotes/create'),
            icon: const Icon(Icons.add),
            label: const Text('Crear Lote'),
          ),
        ],
      ),
    );
  }

  Widget _buildLotesList() {
    return RefreshIndicator(
      onRefresh: _loadLotes,
      child: ListView.builder(
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
    );
  }

  void _navigateToDetail(Lote lote) {
    Navigator.pushNamed(
      context,
      '/lotes/detail',
      arguments: lote.id,
    ).then((_) => _loadLotes()); // Refresh después de volver
  }
}

// lib/widgets/lote_card.dart
class LoteCard extends StatelessWidget {
  final Lote lote;
  final VoidCallback onTap;

  const LoteCard({required this.lote, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final composicion = lote.parseComposicion();
    final total = lote.getTotalComposicion();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icono de lote
                  AppIcon('honey01', size: 40),
                  const SizedBox(width: 12),
                  
                  // Info principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lote ${lote.ordenMiel}: ${lote.nombreMiel}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lote.temporada,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Kg producidos
                  if (lote.kgProducidos != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${lote.kgProducidos!.toStringAsFixed(0)} kg',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              // Preview de composición
              Text(
                'Composición (${composicion.length} especies):',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Top 3 especies
              ...lote.getEspeciesOrdenadas().take(3).map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              if (composicion.length > 3) ...[
                const SizedBox(height: 4),
                Text(
                  '+ ${composicion.length - 3} especies más',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              // Total
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${total.toStringAsFixed(2)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: total >= 99 && total <= 101
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### **SPRINT 3: Visualizaciones** (Semana 5)

#### 3.1 Gráfico de Composición (3 días)

**Agregar dependencia**:
```yaml
dependencies:
  fl_chart: ^0.66.2
```

**Widget de Pie Chart**:
```dart
// lib/widgets/composition_pie_chart.dart
import 'package:fl_chart/fl_chart.dart';

class CompositionPieChart extends StatelessWidget {
  final Map<String, double> composicion;
  final double size;

  const CompositionPieChart({
    required this.composicion,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (composicion.isEmpty) {
      return Center(
        child: Text('Sin datos de composición'),
      );
    }

    final entries = composicion.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: PieChart(
            PieChartData(
              sections: _buildSections(entries, context),
              sectionsSpace: 2,
              centerSpaceRadius: size * 0.3,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(entries, context),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(
    List<MapEntry<String, double>> entries,
    BuildContext context,
  ) {
    final colors = [
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF97316), // Orange
    ];

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final color = colors[index % colors.length];

      return PieChartSectionData(
        value: data.value,
        title: '${data.value.toStringAsFixed(1)}%',
        color: color,
        radius: size * 0.2,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(
    List<MapEntry<String, double>> entries,
    BuildContext context,
  ) {
    final colors = [
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      const Color(0xFFF97316),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final color = colors[index % colors.length];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${data.key} (${data.value.toStringAsFixed(1)}%)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }
}
```

---

#### 3.2 Detalle de Lote con Gráfico (2 días)

```dart
// lib/screens/lotes/lote_detail_screen.dart
class LoteDetailScreen extends StatefulWidget {
  final String loteId;

  const LoteDetailScreen({required this.loteId});

  @override
  State<LoteDetailScreen> createState() => _LoteDetailScreenState();
}

class _LoteDetailScreenState extends State<LoteDetailScreen> {
  final LotesService _lotesService = LotesService();
  Lote? _lote;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLote();
  }

  Future<void> _loadLote() async {
    setState(() => _isLoading = true);
    try {
      final lote = await _lotesService.getLote(widget.loteId);
      setState(() {
        _lote = lote;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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

    if (_lote == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Lote no encontrado')),
      );
    }

    final composicion = _lote!.parseComposicion();

    return Scaffold(
      appBar: AppBar(
        title: Text('Lote ${_lote!.ordenMiel}: ${_lote!.nombreMiel}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navegar a edición
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: _showQR,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con icono
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Column(
                children: [
                  AppIcon('honey02', size: 80),
                  const SizedBox(height: 16),
                  Text(
                    _lote!.nombreMiel,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lote!.temporada,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Información básica
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Orden', '#${_lote!.ordenMiel}'),
                      const Divider(),
                      _buildInfoRow(
                        'Producción',
                        '${_lote!.kgProducidos?.toStringAsFixed(2) ?? '0'} kg',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Fecha Registro',
                        _formatDate(_lote!.fechaRegistro),
                      ),
                      if (_lote!.fechaActualizacion != null) ...[
                        const Divider(),
                        _buildInfoRow(
                          'Última Actualización',
                          _formatDate(_lote!.fechaActualizacion),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Gráfico de composición
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Composición Floral',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: CompositionPieChart(
                      composicion: composicion,
                      size: 250,
                    ),
                  ),
                ],
              ),
            ),

            // Lista detallada
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalle por Especie',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ..._lote!.getEspeciesOrdenadas().map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key),
                                  Text(
                                    '${entry.value.toStringAsFixed(2)}%',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: entry.value / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_lote!.getTotalComposicion().toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _lote!.getTotalComposicion() >= 99 &&
                                      _lote!.getTotalComposicion() <= 101
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showQR() {
    // TODO: Generar y mostrar QR del lote
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función QR próximamente')),
    );
  }
}
```

---

### **SPRINT 4: Dashboard y Mapas** (Semana 6)

#### 4.1 Dashboard Mejorado (3 días)

Actualizar `home_screen.dart` para incluir:
- Resumen de lotes del usuario
- Gráfico de kg producidos por lote
- Acceso rápido a lista de lotes

```dart
// Agregar a home_screen.dart
FutureBuilder<List<Lote>>(
  future: LotesService().getLotesUsuario(user!.id),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }

    final lotes = snapshot.data!;
    final totalKg = lotes.fold<double>(
      0, 
      (sum, lote) => sum + (lote.kgProducidos ?? 0),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lotes.length}',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const Text('Lotes Registrados'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${totalKg.toStringAsFixed(0)} kg',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const Text('Total Producido'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/lotes'),
              child: const Text('Ver Todos los Lotes'),
            ),
          ],
        ),
      ),
    );
  },
)
```

#### 4.2 Mapa de Ubicaciones (2 días)

**Agregar dependencias**:
```yaml
dependencies:
  google_maps_flutter: ^2.5.3
  geolocator: ^10.1.0
```

**Pantalla de mapa básica** (mostrar ubicaciones de tabla `ubicaciones`):
```dart
// lib/screens/map_screen.dart
class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    // TODO: Cargar ubicaciones desde backend
    // Endpoint: GET /api/ubicaciones/<user_id>
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de Ubicaciones')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(-36.828, -73.035), // Chile central
          zoom: 8,
        ),
        markers: _markers,
        myLocationEnabled: true,
        onMapCreated: (controller) => _mapController = controller,
      ),
    );
  }
}
```

---

## 📋 Checklist de Implementación

### Backend
- [ ] Endpoint `/api/auth/forgot-password` (POST)
- [ ] Endpoint `/api/auth/reset-password` (POST) para procesar el token

### Flutter - Básico
- [ ] Integrar 14 iconos en `assets/icons/`
- [ ] Actualizar `pubspec.yaml` con assets
- [ ] Widget `AppIcon` reutilizable
- [ ] Pantalla `ForgotPasswordScreen`
- [ ] Link "¿Olvidaste tu contraseña?" en `LoginScreen`

### Flutter - Lotes
- [ ] Modelo `Lote` con parser de composición
- [ ] Servicio `LotesService`
- [ ] Pantalla `LotesListScreen`
- [ ] Widget `LoteCard`
- [ ] Pantalla `LoteDetailScreen`
- [ ] Widget `CompositionPieChart`
- [ ] Actualizar `HomeScreen` con resumen de lotes

### Flutter - Avanzado
- [ ] Pantalla `CreateLoteScreen`
- [ ] Pantalla `EditLoteScreen`
- [ ] QR del lote
- [ ] Mapa de ubicaciones
- [ ] Dashboard con gráficos adicionales

---

## 🚀 Resumen de Cambios vs Plan Anterior

### ❌ Removido (No Necesario)
- Sistema de análisis polínico con ML
- Tablas nuevas (`lotes_muestras`, `muestras_polen`, `resultados_polinicos`)
- Upload de imágenes de microscopio
- Integración con clasificador ML
- Modo offline completo
- Edge Functions de Supabase

### ✅ Mantenido (Necesario)
- Password reset (backend + Flutter)
- Integración de iconos
- Consumir endpoints existentes
- Visualizaciones (gráficos de composición)
- Lista y detalle de lotes
- Dashboard mejorado

### 🆕 Enfoque Correcto
- **Usar tabla `origenes_botanicos` existente**
- **Parsear campo `composicion` (formato CSV)**
- **Consumir endpoints ya implementados**
- **Replicar funcionalidad de la web**

---

## ⏱️ Tiempo Estimado Total

**6 semanas** (vs 12 semanas del plan anterior)

- Sprint 1: Fundamentos (2 semanas)
- Sprint 2: Pantallas de Lotes (2 semanas)
- Sprint 3: Visualizaciones (1 semana)
- Sprint 4: Dashboard y Mapas (1 semana)

---

**Preparado por**: Cascade AI (Revisión 2.1.0)  
**Aprobado por**: @Nahzap  
**Próxima revisión**: Fin de Sprint 1
