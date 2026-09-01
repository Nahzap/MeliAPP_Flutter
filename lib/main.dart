import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_view_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/search_screen.dart';
import 'screens/lotes/lotes_list_screen.dart';
import 'screens/lotes/lote_detail_screen.dart';
import 'services/api_service.dart';
import 'services/taxa_service.dart';
import 'config/theme_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().initialize();
  runApp(const MeliApp());
}

class MeliApp extends StatelessWidget {
  const MeliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaxaService()..ensureLoaded()),
      ],
      child: MaterialApp(
        title: 'MeliAPP',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        onGenerateRoute: (settings) {
          // Rutas con parámetros
          if (settings.name == '/lotes/detail') {
            final loteId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => LoteDetailScreen(loteId: loteId),
            );
          }

          if (settings.name == '/profile') {
            final userId = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (context) => ProfileViewScreen(userId: userId),
            );
          }

          // Ruta de lotes con userId opcional
          if (settings.name == '/lotes' || settings.name == '/lotes/list') {
            final userId = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (context) => LotesListScreen(userId: userId),
            );
          }

          // Rutas simples
          Widget page;
          switch (settings.name) {
            case '/login':
              page = const LoginScreen();
              break;
            case '/register':
              page = const RegisterScreen();
              break;
            case '/home':
              page = const HomeScreen();
              break;
            case '/forgot-password':
              page = const ForgotPasswordScreen();
              break;
            case '/search':
              page = const SearchScreen();
              break;
            default:
              page = const LoginScreen();
          }

          return MaterialPageRoute(builder: (context) => page);
        },
      ),
    );
  }
}

/// Widget que maneja la navegación inicial basada en el estado de autenticación
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Inicializar el provider de autenticación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Mostrar splash screen mientras se inicializa
        if (!authProvider.isInitialized) {
          return const SplashScreen();
        }

        // Mostrar pantalla correspondiente según estado de autenticación
        return authProvider.isAuthenticated
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}

/// Pantalla de splash mostrada durante la inicialización
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Colmena
            Image.asset(
              'MeliAPP_icons/colmena.png',
              width: 240,
              height: 240,
              color: Colors.white,
            ),
            const SizedBox(height: 24),

            // Título
            const Text(
              'MeliAPP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8),

            // Subtítulo
            Text(
              'APP de Gestión Apícola',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 32),

            // Loading indicator
            CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}
