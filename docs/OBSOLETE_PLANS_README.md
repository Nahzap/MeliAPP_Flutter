# Planes Obsoletos

Este directorio contiene planes estratégicos que fueron **INVALIDADOS** debido a análisis incorrecto.

---

## ❌ Planes Obsoletos

### `STRATEGIC_PLAN.md` (v2.0.0)
**Fecha**: 1 Diciembre 2025  
**Estado**: OBSOLETO  
**Razón**: Análisis incorrecto de la infraestructura existente

**Error crítico**:
Propuso crear un sistema completo de análisis polínico desde cero cuando:
- La tabla `origenes_botanicos` YA existe con lotes y composición
- Los endpoints `/api/lotes/<user_id>` YA funcionan
- La versión web YA muestra gráficos de composición
- El campo `composicion` usa formato CSV que solo necesita parsearse

**Propuestas incorrectas**:
- Crear 4 tablas nuevas (`lotes_muestras`, `muestras_polen`, `resultados_polinicos`, `regiones_botanicas`)
- Implementar 14+ endpoints API nuevos
- Sistema de upload de imágenes de microscopio
- Integración con clasificador ML de polen
- Modo offline completo con Hive + Queue

**Tiempo estimado erróneo**: 12 semanas

---

### `TECHNICAL_AUDIT.md` (v2.0.0)
**Fecha**: 1 Diciembre 2025  
**Estado**: OBSOLETO  
**Razón**: Basado en análisis incorrecto del `STRATEGIC_PLAN.md`

**Problemas**:
- Auditoría de tablas "faltantes" que no se necesitan
- Endpoints "faltantes" que no existen porque los reales ya funcionan
- Métricas de complejidad infladas incorrectamente

---

## ✅ Plan Vigente

**`REVISED_STRATEGIC_PLAN.md` (v2.1.0)**  
**Fecha**: 1 Diciembre 2025  
**Estado**: ACTIVO

**Enfoque corregido**:
- Consumir datos existentes de `origenes_botanicos`
- Parsear campo `composicion` (formato CSV)
- Visualizar en Flutter con gráficos (fl_chart)
- Integrar 14 iconos disponibles
- Password reset (única funcionalidad backend faltante)

**Tiempo estimado correcto**: 6 semanas

---

## 📚 Lecciones Aprendidas

1. **Siempre verificar datos reales en BD antes de proponer nuevas tablas**
   - Ejecutar queries SQL para entender estructura
   - Revisar ejemplos de datos existentes

2. **Analizar versión web funcional primero**
   - Estudiar cómo consume los datos
   - Identificar endpoints ya implementados
   - Ver formato de respuestas reales

3. **No asumir que "no existe" sin evidencia**
   - Buscar en todos los archivos de rutas
   - Verificar nombres de tablas alternativos
   - Consultar al usuario si hay dudas

4. **Preguntar al usuario antes de proponer arquitecturas complejas**
   - "¿Ya existe esto en la web?"
   - "¿Cómo lo hace actualmente?"
   - "¿Qué endpoints usa la web?"

---

**Conclusión**: Antes de proponer crear algo nuevo, verificar que no exista ya funcionando.
