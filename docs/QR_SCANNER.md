# Flutter App - MeliAPP Cloud

## Configuración

### Backend
- **Plataforma**: MeliAPP Cloud
- **URL**: `https://meli-app-cloud.vercel.app`

### Diseño Visual
- **Coincide con plataforma web**
- Colores: Amber (#F59E0B) + Emerald (#10B981)
- Escala de grises: Slate
- Tipografía: Inter

## Cambios Aplicados

### AndroidManifest.xml
- Permisos: `INTERNET`, `CAMERA`
- Queries para `url_launcher` (Android 11+)

### Tema (theme_config.dart)
- Tema unificado con plataforma web
- Colores primarios y secundarios
- Componentes con mismo estilo

### QR Scanner
- URLs abren en navegador
- Cierre automático
- Logs con prefijo `[QR]`

## Testing
```bash
flutter clean && flutter pub get && flutter run
```
