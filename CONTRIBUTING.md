# Contribuyendo a MeliAPP Flutter

¡Gracias por tu interés en contribuir a MeliAPP Flutter! 

## Cómo Contribuir

### Configuración del Entorno de Desarrollo

1. **Clona el repositorio:**
   ```bash
   git clone https://github.com/tu-usuario/MeliAPP_Flutter.git
   cd MeliAPP_Flutter
   ```

2. **Instala las dependencias:**
   ```bash
   flutter pub get
   ```

3. **Verifica que todo funcione:**
   ```bash
   flutter doctor
   flutter analyze
   flutter test
   ```

### Proceso de Desarrollo

1. **Crea una rama para tu feature:**
   ```bash
   git checkout -b feature/nueva-funcionalidad
   ```

2. **Realiza tus cambios siguiendo las convenciones:**
   - Usa nombres descriptivos para variables y funciones
   - Comenta código complejo
   - Sigue las convenciones de Dart/Flutter
   - Ejecuta `flutter analyze` antes de hacer commit

3. **Ejecuta las pruebas:**
   ```bash
   flutter test
   ```

4. **Haz commit de tus cambios:**
   ```bash
   git add .
   git commit -m "feat: descripción clara del cambio"
   ```

5. **Push y crea un Pull Request:**
   ```bash
   git push origin feature/nueva-funcionalidad
   ```

### Convenciones de Commit

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` nueva funcionalidad
- `fix:` corrección de bug
- `docs:` cambios en documentación
- `style:` cambios de formato (no afectan funcionalidad)
- `refactor:` refactorización de código
- `test:` agregar o modificar tests
- `chore:` tareas de mantenimiento

### Estructura del Código

```
lib/
├── main.dart
├── models/          # Modelos de datos
├── screens/         # Pantallas de la app
├── widgets/         # Widgets reutilizables
├── services/        # Servicios (API, storage, etc.)
├── utils/           # Utilidades y helpers
└── constants/       # Constantes de la app
```

### Reportar Issues

Si encuentras un bug o tienes una sugerencia:

1. Verifica que no exista un issue similar
2. Crea un nuevo issue con:
   - Descripción clara del problema
   - Pasos para reproducir
   - Comportamiento esperado vs actual
   - Screenshots si es relevante
   - Información del entorno (Flutter version, OS, etc.)

## Código de Conducta

- Sé respetuoso con otros contribuidores
- Mantén las discusiones constructivas
- Ayuda a crear un ambiente inclusivo y acogedor

¡Gracias por contribuir! 🚀
