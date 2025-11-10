import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'qr_scanner_screen.dart';
// QR generation no es responsabilidad de la app Flutter

/// Pantalla principal con pruebas de conexión a la API REST
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _testResult = '';
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MeliAPP - Pruebas'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUserData,
            tooltip: 'Refrescar datos',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información del usuario
            _buildUserCard(),
            const SizedBox(height: 16),

            // Botones de prueba
            _buildTestButtons(),
            const SizedBox(height: 16),

            // Resultados de pruebas
            _buildResultsCard(),
          ],
        ),
      ),
      // QR Scanner - Abre URLs en navegador
      floatingActionButton: FloatingActionButton(
        onPressed: _openQRScanner,
        backgroundColor: Colors.blue[600],
        tooltip: 'Escanear QR',
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }

  Widget _buildUserCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[600],
                      child: Text(
                        user?.username != null
                            ? user!.username.substring(0, 1).toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.nombreCompleto ?? 'Usuario Autenticado',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (authProvider.isLoading)
                            const Text('Cargando...')
                          else if (user != null) ...[
                            Text(
                              user.username,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            if (user.email != null) Text(user.email!),
                          ] else
                            const Text('No hay datos de usuario'),
                        ],
                      ),
                    ),
                  ],
                ),
                if (user != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // === SECCIÓN: INFORMACIÓN DE CUENTA ===
                  Text(
                    'Información de Cuenta',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.fingerprint, 'UUID', user.id),
                  if (user.role != null)
                    _buildInfoRow(Icons.badge, 'Role', user.role!),
                  if (user.tipoUsuario != null)
                    _buildInfoRow(
                      Icons.category,
                      'Tipo Usuario',
                      user.tipoUsuario!,
                    ),
                  if (user.status != null)
                    _buildInfoRow(Icons.info_outline, 'Status', user.status!),
                  if (user.activo != null)
                    _buildInfoRow(
                      user.activo! ? Icons.check_circle : Icons.cancel,
                      'Activo',
                      user.activo! ? 'Sí' : 'No',
                    ),

                  // === SECCIÓN: FECHAS ===
                  if (user.fechaRegistro != null || user.lastLogin != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Fechas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (user.fechaRegistro != null)
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Registro',
                        _formatDate(user.fechaRegistro!),
                      ),
                    if (user.lastLogin != null)
                      _buildInfoRow(
                        Icons.login,
                        'Último Login',
                        _formatDate(user.lastLogin!),
                      ),
                  ],

                  // === SECCIÓN: INFORMACIÓN DE CONTACTO ===
                  const SizedBox(height: 12),
                  Text(
                    'Información de Contacto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (user.nombreCompleto != null ||
                      user.nombreEmpresa != null ||
                      user.telefono != null ||
                      user.direccion != null ||
                      user.comuna != null ||
                      user.region != null) ...[
                    if (user.nombreCompleto != null)
                      _buildInfoRow(
                        Icons.person,
                        'Nombre Completo',
                        user.nombreCompleto!,
                      ),
                    if (user.nombreEmpresa != null)
                      _buildInfoRow(
                        Icons.business,
                        'Empresa',
                        user.nombreEmpresa!,
                      ),
                    if (user.telefono != null)
                      _buildInfoRow(Icons.phone, 'Teléfono', user.telefono!),
                    if (user.direccion != null)
                      _buildInfoRow(
                        Icons.location_on,
                        'Dirección',
                        user.direccion!,
                      ),
                    if (user.comuna != null)
                      _buildInfoRow(
                        Icons.location_city,
                        'Comuna',
                        user.comuna!,
                      ),
                    if (user.region != null)
                      _buildInfoRow(Icons.map, 'Región', user.region!),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No hay datos de contacto registrados en info_contacto.\nCompleta tu perfil en la plataforma web.',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTestButtons() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pruebas de API',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testDatabaseConnection,
                icon: const Icon(Icons.storage),
                label: const Text('Ver Datos Completos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testFullAPI,
                icon: const Icon(Icons.api),
                label: const Text('Prueba Completa de API'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Resultados de Pruebas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _testResult.isEmpty
                      ? 'Ejecuta una prueba para ver los resultados...'
                      : _testResult,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testDatabaseConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Verificando conexión local...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      setState(() {
        _testResult =
            '''
✅ DATOS DE USUARIO LOCALES

Usuario: ${user?.username ?? 'N/A'}
Email: ${user?.email ?? 'N/A'}
ID: ${user?.id ?? 'N/A'}
Role: ${user?.role ?? 'N/A'}
Status: ${user?.status ?? 'N/A'}

NOTA: Estos datos se obtienen del cache local.
El endpoint /api/auth/session tiene un error en el backend
(busca usuarios.id que no existe, debería buscar usuarios.auth_user_id)

Timestamp: ${DateTime.now()}
        ''';
      });
    } catch (e) {
      setState(() {
        _testResult =
            '''
❌ ERROR OBTENIENDO DATOS LOCALES

Error: $e

Timestamp: ${DateTime.now()}
        ''';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // QR Generation eliminado: no es responsabilidad de la app Flutter
  // La generación de QR se hace en la plataforma web oficial

  Future<void> _testFullAPI() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Ejecutando prueba completa...';
    });

    final results = <String>[];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Prueba 1: Verificar datos locales
      results.add('1. Verificando datos locales...');
      final user = authProvider.user;
      if (user != null) {
        results.add('   ✅ Usuario en cache: ${user.username}');
      } else {
        results.add('   ❌ No hay usuario en cache');
      }

      // Prueba 2: Verificar cookies
      results.add('2. Verificando cookies de sesión...');
      final hasCookies = await _apiService.hasCookies();
      results.add(
        '   ${hasCookies ? '✅' : '❌'} Cookies: ${hasCookies ? 'Presentes' : 'Ausentes'}',
      );

      // Prueba 3: Intentar generar QR (probablemente fallará por UUID incorrecto)
      final uuidSegment = authProvider.getCurrentUserUuidSegment();
      if (uuidSegment != null) {
        results.add('3. Intentando generar QR...');
        results.add('   ⚠️  UUID Segment: $uuidSegment');
        results.add(
          '   ⚠️  Nota: Fallará porque no es el UUID real de Supabase',
        );
      } else {
        results.add(
          '3. ⚠️ No se puede generar QR (UUID segment no disponible)',
        );
      }

      setState(() {
        _testResult =
            '''
🔍 PRUEBA COMPLETA DEL SISTEMA

${results.join('\n')}

📊 Resumen:
- API Base: https://meli-app-v3.vercel.app
- Login: ✅ Funcionando
- Usuario Local: ${user?.username ?? 'N/A'}
- Email: ${user?.email ?? 'N/A'}
- Cookies: ${hasCookies ? 'Configuradas' : 'No configuradas'}

⚠️  LIMITACIONES ACTUALES:
- El endpoint /api/auth/session tiene error en backend
- No podemos obtener el auth_user_id real de Supabase
- QR generation necesita el UUID real del usuario

Timestamp: ${DateTime.now()}
        ''';
      });
    } catch (e) {
      setState(() {
        _testResult =
            '''
❌ ERROR EN PRUEBA COMPLETA

${results.join('\n')}

Error final: $e

Timestamp: ${DateTime.now()}
        ''';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refreshUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUser();
  }

  void _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  /// Abre el scanner de QR que detecta URLs y las abre en el navegador
  void _openQRScanner() {
    // Verificar si la plataforma soporta el scanner QR
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Plataformas no soportadas
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Scanner No Disponible'),
            ],
          ),
          content: const Text(
            'El scanner de QR solo funciona en dispositivos móviles (Android/iOS).\n\n'
            'Para probar esta funcionalidad:\n'
            '• Ejecuta la app en un dispositivo Android\n'
            '• Ejecuta la app en un dispositivo iOS\n'
            '• Usa un emulador Android/iOS',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    // Plataformas soportadas (Android/iOS)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
  }

  /// Construye una fila de información con icono
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Formatea una fecha ISO a formato legible
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}
