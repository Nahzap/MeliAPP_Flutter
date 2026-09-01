import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/qr_service.dart';
import 'profile_view_screen.dart';
import 'qr_scanner_screen.dart';

/// Home = visor del perfil propio (MeliAPP Cloud, solo lectura).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _refreshToken = 0;
  final ScrollController _profileScroll = ScrollController();

  @override
  void dispose() {
    _profileScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MeliAPP Cloud'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
            tooltip: 'Buscar productores',
          ),
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
      body: ProfileViewScreen(
        embedded: true,
        refreshToken: _refreshToken,
        scrollController: _profileScroll,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'scrollTop',
            onPressed: _scrollToTop,
            tooltip: 'Ir arriba',
            child: const Icon(Icons.arrow_upward),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'qr',
            onPressed: _openQRScanner,
            tooltip: 'Escanear o pegar QR',
            child: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
    );
  }

  void _scrollToTop() {
    if (!_profileScroll.hasClients) return;
    _profileScroll.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _refreshUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUser();
    if (mounted) setState(() => _refreshToken++);
  }

  void _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _openQRScanner() {
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _pasteQrDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    ).then((userId) {
      if (userId is String && mounted) {
        Navigator.pushNamed(context, '/profile', arguments: userId);
      }
    });
  }

  Future<void> _pasteQrDialog() async {
    final controller = TextEditingController();
    final submitted = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir perfil desde QR'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Pega la URL de MeliAPP Cloud',
            hintText: 'https://www.meliapp.cl/profile/...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );

    if (submitted == null || submitted.isEmpty || !mounted) return;
    final userId = await QRService().resolveUserId(submitted);
    if (!mounted) return;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La URL no es un perfil de MeliAPP Cloud'),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/profile', arguments: userId);
  }
}
