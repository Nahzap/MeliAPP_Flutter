import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar iconos custom de la aplicación.
///
/// Iconos disponibles:
/// - bee, bee02, bee03 (Abejas)
/// - colmena, colmena02 (Colmenas)
/// - honey01, honey02 (Miel)
/// - pollen01, pollen02, pollen03 (Polen)
/// - apiario01, apicultor (Apiarios/Apicultores)
/// - leaf01, marker01 (Vegetación/Ubicación)
class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final BoxFit fit;

  const AppIcon(
    this.name, {
    super.key,
    this.size = 48,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/$name.png',
      width: size,
      height: size,
      color: color,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback si la imagen no se encuentra
        return Icon(Icons.image_not_supported, size: size, color: Colors.grey);
      },
    );
  }
}

/// Iconos predefinidos para facilitar el uso
class AppIcons {
  // Abejas
  static const String bee = 'bee';
  static const String bee02 = 'bee02';
  static const String bee03 = 'bee03';

  // Colmenas
  static const String colmena = 'colmena';
  static const String colmena02 = 'colmena02';

  // Miel
  static const String honey01 = 'honey01';
  static const String honey02 = 'honey02';

  // Polen
  static const String pollen01 = 'pollen01';
  static const String pollen02 = 'pollen02';
  static const String pollen03 = 'pollen03';

  // Apiarios y apicultores
  static const String apiario01 = 'apiario01';
  static const String apicultor = 'apicultor';

  // Vegetación y ubicación
  static const String leaf01 = 'leaf01';
  static const String marker01 = 'marker01';
}
