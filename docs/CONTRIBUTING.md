# Contribuir a MeliAPP Flutter

¡Gracias por tu interés en contribuir a MeliAPP Flutter! 🎉

## 📋 Tabla de Contenidos

- [Código de Conducta](#código-de-conducta)
- [Cómo Contribuir](#cómo-contribuir)
- [Estándares de Código](#estándares-de-código)
- [Proceso de Pull Request](#proceso-de-pull-request)
- [Reportar Bugs](#reportar-bugs)
- [Sugerir Mejoras](#sugerir-mejoras)

---

## 📜 Código de Conducta

Este proyecto y todos sus participantes se rigen por nuestro Código de Conducta. Al participar, se espera que mantengas este código. Por favor reporta comportamientos inaceptables.

---

## 🤝 Cómo Contribuir

### 1. Fork del Proyecto

```bash
# Haz fork en GitHub, luego clona tu fork
git clone https://github.com/TU-USUARIO/MeliAPP_Flutter.git
cd MeliAPP_Flutter
```

### 2. Crea una Rama

```bash
# Crea una rama para tu feature/bugfix
git checkout -b feature/mi-nueva-funcionalidad
# o
git checkout -b bugfix/corregir-problema
```

### 3. Configura el Proyecto

```bash
# Instala dependencias
flutter pub get

# Verifica que todo funcione
flutter analyze
flutter test
```

### 4. Realiza tus Cambios

- Escribe código limpio y bien documentado
- Sigue las convenciones de Dart/Flutter
- Añade tests si es necesario
- Actualiza documentación

### 5. Commit y Push

```bash
# Añade tus cambios
git add .

# Commit con mensaje descriptivo
git commit -m "feat: Agrega nueva funcionalidad X"

# Push a tu fork
git push origin feature/mi-nueva-funcionalidad
```

### 6. Pull Request

- Ve a GitHub y crea un Pull Request
- Describe claramente qué hace tu PR
- Referencia issues relacionados si los hay
- Espera el review del equipo

---

## 💻 Estándares de Código

### Dart/Flutter Style Guide

Seguimos las [Effective Dart Guidelines](https://dart.dev/guides/language/effective-dart):

```dart
// ✅ Bueno: Nombres descriptivos y claros
Future<User> getUserProfile() async { ... }

// ❌ Malo: Nombres vagos
Future<dynamic> getData() async { ... }
```

### Formato

```bash
# Formatea todo el código
flutter format lib/

# O usa el formateador de tu IDE
```

### Análisis Estático

```bash
# Ejecuta el analizador antes de commit
flutter analyze

# No debería haber errores ni warnings
```

### Tests

```bash
# Ejecuta todos los tests
flutter test

# Tests con coverage
flutter test --coverage
```

---

## 🔄 Proceso de Pull Request

### Checklist antes del PR

- [ ] El código compila sin errores
- [ ] `flutter analyze` sin warnings
- [ ] Tests pasan (`flutter test`)
- [ ] Código formateado (`flutter format`)
- [ ] Documentación actualizada
- [ ] Commit messages claros

### Tipos de Commits

Usa [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: Agrega nueva funcionalidad
fix: Corrige un bug
docs: Cambios en documentación
style: Formato, punto y coma, etc
refactor: Refactorización de código
test: Agrega o modifica tests
chore: Tareas de mantenimiento
```

**Ejemplos:**

```bash
git commit -m "feat: Agrega soporte para biometría en login"
git commit -m "fix: Corrige error al escanear QR sin permisos"
git commit -m "docs: Actualiza README con instrucciones de deploy"
```

### Review Process

1. Un mantenedor revisará tu PR
2. Puede pedir cambios o aclaraciones
3. Realiza los cambios solicitados
4. Una vez aprobado, se hará merge

---

## 🐛 Reportar Bugs

### Antes de Reportar

1. **Busca** si ya existe un issue similar
2. **Verifica** que estés usando la última versión
3. **Recopila** información del error

### Template de Bug Report

```markdown
**Descripción del Bug**
Una descripción clara del problema.

**Pasos para Reproducir**
1. Ve a '...'
2. Haz click en '...'
3. Scroll hasta '...'
4. Ver error

**Comportamiento Esperado**
Qué esperabas que sucediera.

**Screenshots**
Si aplica, agrega capturas de pantalla.

**Entorno**
- Flutter version: [ej. 3.10.0]
- Dart version: [ej. 3.0.0]
- OS: [ej. Android 13, iOS 16]
- Dispositivo: [ej. Pixel 6, iPhone 14]

**Contexto Adicional**
Cualquier otra información relevante.
```

---

## 💡 Sugerir Mejoras

### Template de Feature Request

```markdown
**¿Tu solicitud está relacionada con un problema?**
Una descripción clara del problema. Ej: "Siempre me frustra cuando [...]"

**Describe la solución que te gustaría**
Una descripción clara de lo que quieres que suceda.

**Describe alternativas que hayas considerado**
Otras soluciones o funcionalidades que consideraste.

**Contexto adicional**
Agrega cualquier otro contexto o screenshots sobre el feature request.
```

---

## 🏗️ Arquitectura del Proyecto

### Estructura de Carpetas

```
lib/
├── config/          # Configuración (API, constantes)
├── models/          # Modelos de datos
├── providers/       # Estado (Provider)
├── screens/         # UI (Pantallas)
├── services/        # Lógica de negocio
└── main.dart        # Entry point
```

### Principios

- **Clean Architecture**: Separación de capas
- **SOLID Principles**: Código mantenible
- **DRY**: Don't Repeat Yourself
- **Single Responsibility**: Cada clase/función hace una cosa

---

## 🧪 Guidelines de Testing

### Unit Tests

```dart
// Ubica en test/
test('getUserProfile devuelve user cuando existe', () async {
  // Arrange
  final service = AuthService();
  
  // Act
  final user = await service.getUserProfile();
  
  // Assert
  expect(user, isNotNull);
  expect(user.email, equals('test@example.com'));
});
```

### Widget Tests

```dart
testWidgets('LoginScreen muestra formulario', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(home: LoginScreen()));
  
  expect(find.byType(TextFormField), findsNWidgets(2));
  expect(find.text('Iniciar Sesión'), findsOneWidget);
});
```

---

## 📝 Documentación

### Comentarios de Código

```dart
/// Obtiene el perfil completo del usuario desde la API.
///
/// Combina datos de las tablas usuarios e info_contacto.
///
/// Returns:
///   Un objeto [User] con todos los datos del perfil.
///
/// Throws:
///   [ApiException] si la API devuelve un error.
///   [NetworkException] si no hay conexión.
Future<User> getUserProfile() async { ... }
```

### README Updates

Si tu cambio afecta:
- Instalación
- Configuración
- Uso de la app

Por favor actualiza el README.md

---

## ❓ Preguntas

Si tienes preguntas sobre cómo contribuir:

- Abre un **Issue** con la etiqueta `question`
- Contacta por email: rodrigoandresj@gmail.com

---

## 🎉 ¡Gracias!

Gracias por tomarte el tiempo de contribuir a MeliAPP Flutter. Tu ayuda hace que este proyecto sea mejor para todos! 🚀

---

<div align="center">

**Happy Coding!** 💻🐝

</div>
