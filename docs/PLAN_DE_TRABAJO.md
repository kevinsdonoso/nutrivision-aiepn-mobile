# PLAN DE TRABAJO - NUTRIVISIONAIEPN MOBILE

> Documento de planificacion estructurada para mejoras de UX/UI y funcionalidad

---

## Estado Actual del Proyecto

### Porcentaje de Avance General: **85%**

| Componente | Estado | Porcentaje |
|------------|--------|------------|
| ML Core (YoloDetector) | Completo | 100% |
| Sistema de Excepciones | Completo | 100% |
| Sistema de Logging | Completo | 100% |
| Testing (145 tests) | Completo | 100% |
| Deteccion desde Galeria | Completo | 100% |
| Deteccion en Tiempo Real | Funcional | 90% |
| Codigo Nativo C++ (NEON) | Completo | 100% |
| UI Principal (Home) | Completo | 100% |
| Base de Datos Nutricional | Completo | 100% |
| Firebase Auth | Completo | 100% |
| Onboarding | Completo | 100% |
| Profile System | Completo | 100% |
| Session Manager | Completo | 100% |
| **Modo Oscuro** | **Parcial** | **60%** |
| **Navegacion** | **Parcial** | **70%** |
| **UX Camara** | **Parcial** | **75%** |

### Diagnostico Tecnico
- `flutter analyze`: 0 issues
- `flutter test`: 145 tests pasando
- Arquitectura: Clean Architecture con Riverpod

---

## PROBLEMAS IDENTIFICADOS

### 1. Modo Oscuro Incompleto
- **Severidad**: Media
- **Ubicacion**: `lib/core/theme/app_theme.dart`, varios widgets
- **Descripcion**: El tema oscuro esta definido pero muchos widgets usan colores hardcodeados que no respetan el tema del sistema

### 2. Indicador de Perfil Confuso
- **Severidad**: Baja
- **Ubicacion**: `lib/features/profile/views/profile_screen.dart`
- **Descripcion**: No es claro que campos faltan para completar el perfil al 100%

### 3. Navegacion de Retroceso Inconsistente
- **Severidad**: Alta
- **Ubicacion**: Multiples pantallas
- **Descripcion**: Botones de retroceso y gestos no funcionan correctamente en algunas pantallas

### 4. Deteccion Inicia Activada
- **Severidad**: Media
- **Ubicacion**: `lib/features/detection/views/detection_live_screen.dart`
- **Descripcion**: La deteccion deberia iniciar DESACTIVADA para que el usuario controle cuando activarla

### 5. Icono de Deteccion No Claro
- **Severidad**: Baja
- **Ubicacion**: `lib/features/detection/views/detection_live_screen.dart`
- **Descripcion**: El icono de visibility/visibility_off no comunica claramente "deteccion activa/inactiva"

### 6. Rendimiento Sin Configuracion
- **Severidad**: Media
- **Ubicacion**: `lib/features/detection/views/detection_live_screen.dart`
- **Descripcion**: No hay opciones para ajustar parametros de rendimiento en tiempo real

### 7. Inconsistencia Galeria vs Camara
- **Severidad**: Alta
- **Ubicacion**: `lib/features/detection/views/detection_live_screen.dart`
- **Descripcion**: La captura de camara no tiene todas las funcionalidades de galeria:
  - Autoajuste de porciones
  - Lista de ingredientes con nivel de confianza
  - Opcion de resaltar una etiqueta especifica

---

## PLAN DE FASES

---

## FASE 1: Correcciones Criticas de UX
**Duracion estimada**: 4-6 horas
**Estado**: EN PROGRESO

### Objetivo
Corregir los problemas mas criticos que afectan la experiencia del usuario.

### 1.1 Modo Oscuro Completo

**Archivos a modificar**:
- `lib/core/theme/app_theme.dart`
- `lib/features/home/views/home_screen.dart`
- `lib/features/detection/views/detection_live_screen.dart`
- `lib/features/detection/views/detection_gallery_screen.dart`

**Cambios especificos**:
1. Agregar colores semanticos al tema que se adapten automaticamente
2. Reemplazar colores hardcodeados por referencias al tema
3. Usar `Theme.of(context).colorScheme` en lugar de `AppColors.xxx` directamente
4. Agregar `surfaceContainerHighest`, `onSurfaceVariant` al ColorScheme oscuro

### 1.2 Navegacion Funcional

**Archivos a modificar**:
- `lib/features/detection/views/detection_live_screen.dart`
- `lib/features/detection/views/detection_gallery_screen.dart`
- `lib/features/profile/views/profile_screen.dart`
- `lib/features/profile/views/edit_profile_screen.dart`

**Cambios especificos**:
1. Verificar que `context.pop()` funcione correctamente
2. Agregar `WillPopScope` donde sea necesario para manejar gesto de retroceso
3. Implementar `Navigator.maybePop()` como fallback
4. Asegurar que `canPop()` se verifique antes de hacer pop

### 1.3 Estado Inicial de Deteccion

**Archivos a modificar**:
- `lib/features/detection/views/detection_live_screen.dart`

**Cambio especifico**:
```dart
// ANTES
bool _liveDetectionEnabled = true;

// DESPUES
bool _liveDetectionEnabled = false;
```

### 1.4 Mejora de Iconografia

**Archivos a modificar**:
- `lib/features/detection/views/detection_live_screen.dart`

**Cambio especifico**:
- Usar iconos mas descriptivos: `Icons.radar` (activo) / `Icons.radar_outlined` (inactivo)
- Agregar texto descriptivo junto al toggle

---

## FASE 2: Mejoras de Rendimiento y Configuracion
**Duracion estimada**: 6-8 horas
**Estado**: PENDIENTE

### Objetivo
Agregar panel de configuracion para ajustar parametros de rendimiento en tiempo real.

### 2.1 Panel de Configuracion de Camara

**Archivos a crear**:
- `lib/features/detection/widgets/camera_settings_panel.dart`

**Archivos a modificar**:
- `lib/features/detection/views/detection_live_screen.dart`
- `lib/features/detection/providers/camera_provider.dart`
- `lib/core/constants/app_constants.dart`

**Funcionalidades**:
1. Slider para ajustar frame skip (1-5)
2. Selector de resolucion (low/medium/high)
3. Slider para umbral de confianza (0.3-0.8)
4. Toggle para mostrar/ocultar FPS
5. Indicador de uso de memoria

### 2.2 Persistencia de Configuracion

**Archivos a crear**:
- `lib/data/repositories/settings_repository.dart`

**Funcionalidades**:
1. Guardar configuracion en SharedPreferences
2. Restaurar configuracion al iniciar

---

## FASE 3: Paridad Funcional Galeria-Camara
**Duracion estimada**: 8-10 horas
**Estado**: PENDIENTE

### Objetivo
Implementar todas las funcionalidades de galeria en la captura de camara.

### 3.1 Autoajuste de Porciones en Captura

**Archivos a modificar**:
- `lib/features/detection/views/detection_live_screen.dart`

**Funcionalidades**:
1. Integrar `QuantityAdjustmentDialog` en resultados de captura
2. Mostrar preview de nutrientes totales
3. Permitir editar cantidades antes de guardar

### 3.2 Lista de Ingredientes con Confianza

**Archivos a modificar**:
- `lib/features/detection/views/detection_live_screen.dart`

**Funcionalidades**:
1. Mostrar lista expandible de ingredientes detectados
2. Indicador visual de nivel de confianza (color-coded)
3. Conteo de instancias por ingrediente

### 3.3 Resaltado de Etiqueta Especifica

**Archivos a modificar**:
- `lib/features/detection/views/detection_live_screen.dart`
- `lib/features/detection/widgets/detection_overlay.dart`

**Funcionalidades**:
1. Tap en ingrediente para resaltar solo esas detecciones
2. Atenuar otras detecciones visualmente
3. Boton para mostrar todas las detecciones

---

## FASE 4: Claridad y Feedback Visual
**Duracion estimada**: 4-6 horas
**Estado**: PENDIENTE

### Objetivo
Mejorar la claridad visual y feedback al usuario.

### 4.1 Indicador de Completitud de Perfil

**Archivos a modificar**:
- `lib/features/profile/views/profile_screen.dart`
- `lib/data/models/user_profile.dart`

**Funcionalidades**:
1. Mostrar lista de campos faltantes para completar perfil
2. Barra de progreso visual
3. Sugerencias para completar campos

### 4.2 Iconografia Consistente

**Archivos a modificar**:
- `lib/core/theme/app_theme.dart`
- Varios widgets

**Funcionalidades**:
1. Definir paleta de iconos consistente
2. Documentar uso de iconos
3. Reemplazar iconos inconsistentes

### 4.3 Feedback Visual Mejorado

**Archivos a crear**:
- `lib/shared/widgets/loading_overlay.dart`
- `lib/shared/widgets/success_animation.dart`

**Funcionalidades**:
1. Animaciones de carga consistentes
2. Feedback visual de exito/error
3. Transiciones suaves entre estados

---

## FASE 5: Testing Completo
**Duracion estimada**: 8-12 horas
**Estado**: PENDIENTE

### Objetivo
Alcanzar cobertura de testing completa.

### 5.1 Tests Unitarios

**Cobertura objetivo**: 95%

**Areas a cubrir**:
- Providers de deteccion
- Logica de configuracion de camara
- Calculo de nutrientes con cantidades ajustadas
- Validacion de perfil

### 5.2 Tests de Integracion

**Areas a cubrir**:
- Flujo completo de deteccion desde galeria
- Flujo completo de deteccion desde camara
- Flujo de autenticacion
- Flujo de edicion de perfil

### 5.3 Tests Funcionales (Widget Tests)

**Areas a cubrir**:
- Navegacion entre pantallas
- Respuesta a modo oscuro/claro
- Interacciones de usuario en camara
- Ajuste de cantidades

---

## FASE 6: Rediseno UI/UX
**Duracion estimada**: 16-24 horas
**Estado**: PENDIENTE

### Objetivo
Rediseno integral de la interfaz de usuario.

### 6.1 Analisis de Usabilidad

**Actividades**:
1. Revisar flujos de usuario actuales
2. Identificar puntos de friccion
3. Proponer mejoras basadas en heuristicas

### 6.2 Rediseno Visual

**Areas a redisenar**:
1. Home screen con dashboard nutricional
2. Pantalla de camara mas intuitiva
3. Resultados de deteccion mas visuales
4. Perfil con mejor organizacion

### 6.3 Implementacion

**Orden de implementacion**:
1. Sistema de diseno (tokens, componentes base)
2. Home screen
3. Pantallas de deteccion
4. Perfil y configuracion

---

## CRONOGRAMA SUGERIDO

| Fase | Duracion | Semana |
|------|----------|--------|
| FASE 1: Correcciones Criticas | 4-6 horas | Semana 1 |
| FASE 2: Rendimiento | 6-8 horas | Semana 1-2 |
| FASE 3: Paridad Funcional | 8-10 horas | Semana 2 |
| FASE 4: Claridad Visual | 4-6 horas | Semana 3 |
| FASE 5: Testing | 8-12 horas | Semana 3-4 |
| FASE 6: Rediseno | 16-24 horas | Semana 4-6 |

**Total estimado**: 46-66 horas de trabajo

---

## NOTAS IMPORTANTES

1. **Prioridad**: Las fases estan ordenadas por prioridad. FASE 1 es critica.
2. **Dependencias**: FASE 3 depende parcialmente de FASE 2.
3. **Testing**: FASE 5 puede ejecutarse en paralelo con otras fases.
4. **Rediseno**: FASE 6 debe ejecutarse despues de que todo este estable.

---

## ARCHIVOS CRITICOS - NO MODIFICAR

Los siguientes archivos NO deben modificarse hasta FASE 6:

```
lib/features/detection/services/
- yolo_detector.dart (521 lineas, motor ML)
- camera_frame_processor.dart (356 lineas, orquestacion)
- image_processing_isolate.dart (149 lineas, isolate)
- native_image_processor.dart (102 lineas, C++ bridge)

android/app/src/main/cpp/
- native_image_processor.cpp (287 lineas, NEON)
- yuv_to_rgb.h (87 lineas, headers)
- CMakeLists.txt (config build)
```

---

*Documento generado el 2025-12-18*
*Proyecto: NutriVisionAIEPN Mobile*
