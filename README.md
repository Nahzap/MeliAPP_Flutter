# MeliAPP Flutter

Una aplicación Flutter para MercadoLibre desarrollada con Windsurf.

## Configuración del Entorno

### Requisitos
- Flutter 3.35.7 (instalado)
- Dart 3.9.2 (incluido con Flutter)
- Android Studio 2024.2 (instalado)
- Visual Studio Community 2022 (instalado)
- Windsurf IDE

### Estructura del Proyecto
```
MeliAPP_Flutter/
├── lib/
│   └── main.dart          # Punto de entrada de la aplicación
├── android/               # Configuración Android
├── ios/                   # Configuración iOS
├── web/                   # Configuración Web
├── windows/               # Configuración Windows
├── .vscode/               # Configuración Windsurf/VS Code
│   ├── settings.json
│   ├── launch.json
│   └── extensions.json
└── pubspec.yaml           # Dependencias del proyecto
```

## Comandos Útiles

### Desarrollo
```bash
# Ejecutar la aplicación
flutter run

# Ejecutar en modo debug
flutter run --debug

# Ejecutar en Chrome (web)
flutter run -d chrome

# Hot reload (durante desarrollo)
r

# Hot restart (durante desarrollo)
R

# Salir del modo debug
q
```

### Mantenimiento
```bash
# Verificar configuración
flutter doctor

# Obtener dependencias
flutter pub get

# Actualizar dependencias
flutter pub upgrade

# Analizar código
flutter analyze

# Ejecutar tests
flutter test

# Limpiar build
flutter clean
```

### Build
```bash
# Build para Android (APK)
flutter build apk

# Build para Android (App Bundle)
flutter build appbundle

# Build para Windows
flutter build windows

# Build para Web
flutter build web
```

## Desarrollo con Windsurf

### Configuración Completada
- ✅ Proyecto Flutter inicializado
- ✅ Dependencias instaladas
- ✅ Configuración VS Code/Windsurf
- ✅ Variables de entorno configuradas
- ✅ Flutter doctor sin errores

### Extensiones Recomendadas
- Dart
- Flutter

### Comandos de Terminal en Windsurf
Puedes usar la terminal integrada de Windsurf para ejecutar todos los comandos de Flutter directamente.

## Próximos Pasos

1. Personalizar `lib/main.dart` para tu aplicación MercadoLibre
2. Agregar dependencias específicas en `pubspec.yaml`
3. Crear la estructura de carpetas para tu app
4. Implementar la funcionalidad específica de MercadoLibre

## Recursos

- [Documentación Flutter](https://docs.flutter.dev/)
- [API MercadoLibre](https://developers.mercadolibre.com/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
