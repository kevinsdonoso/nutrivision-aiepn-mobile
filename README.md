# 🍽️ NutriVisionAIEPN Mobile

> **Aplicación móvil Flutter para reconocimiento automático de alimentos mediante visión por computador usando YOLO11n (TensorFlow Lite) ejecutado on-device. Estima macronutrientes consultando una base de datos SQLite local.**
>
> 📚 *Proyecto de Trabajo de Integración Curricular — Escuela Politécnica Nacional (EPN)*

---

## 📋 Tabla de Contenidos

1. [Descripción del Proyecto](#-descripción-del-proyecto)
2. [✨ Funcionalidades Implementadas](#-funcionalidades-implementadas)
3. [🎬 Casos de Uso Principales](#-casos-de-uso-principales)
4. [👥 Historias de Usuario](#-historias-de-usuario)
5. [🏗️ Stack Tecnológico Completo](#️-stack-tecnológico-completo)
6. [🔄 Diagrama de Flujo de Datos](#-diagrama-de-flujo-de-datos)
7. [🔗 Interacciones entre Módulos](#-interacciones-entre-módulos)
8. [💻 Requisitos Previos](#-requisitos-previos)
9. [🛠️ Instalación del Entorno de Desarrollo](#️-instalación-del-entorno-de-desarrollo)
10. [📁 Estructura del Proyecto](#-estructura-del-proyecto)
11. [⚙️ Configuración Inicial](#️-configuración-inicial)
12. [📦 Dependencias (pubspec.yaml)](#-dependencias-pubspecyaml)
13. [🤖 Configuración de Android](#-configuración-de-android)
14. [🧠 Integración del Modelo TFLite](#-integración-del-modelo-tflite)
15. [🛡️ Sistema de Excepciones](#️-sistema-de-excepciones)
16. [📱 Permisos de Cámara y Galería](#-permisos-de-cámara-y-galería)
17. [🏗️ Arquitectura de la Aplicación](#️-arquitectura-de-la-aplicación)
18. [🧪 Testing](#-testing)
19. [🔧 Comandos Útiles](#-comandos-útiles)
20. [📲 Generación de Builds](#-generación-de-builds)
21. [🗺️ Roadmap de Desarrollo](#️-roadmap-de-desarrollo)
22. [🔥 Solución de Problemas Comunes](#-solución-de-problemas-comunes)
23. [📚 Referencias y Recursos](#-referencias-y-recursos)
24. [🚀 Performance Testing](#-performance-testing)

---

## 🎯 Descripción del Proyecto

**NutriVisionAIEPN Mobile** es una aplicación Android desarrollada en Flutter que permite:

- 📸 Capturar imágenes de platos de comida ecuatoriana/mediterránea
- 🔍 Detectar automáticamente los ingredientes usando el modelo YOLO11n
- 🥗 Identificar hasta **83 clases** de ingredientes alimenticios
- 📊 Estimar macronutrientes (calorías, proteínas, carbohidratos, grasas)
- 💾 Funcionar **100% offline** sin necesidad de conexión a internet
- 🎯 Visualizar bounding boxes sobre los ingredientes detectados
- 🔎 Filtrar detecciones por ingrediente seleccionado

### Modelo de ML

| Propiedad | Valor |
|-----------|-------|
| Arquitectura | YOLO11n (Ultralytics) |
| Formato | TensorFlow Lite (FP32) |
| Tamaño de entrada | 640×640 píxeles |
| Output | [1, 87, 8400] (coordenadas normalizadas 0-1) |
| Clases | 83 ingredientes |
| Tamaño del modelo | ~10.27 MB |
| Dataset | NutriVisionAIEPN (297 imágenes, 6 platos) |

### Platos soportados

1. 🥗 Ensalada Caprese
2. 🦐 Ceviche ecuatoriano
3. 🍕 Pizza
4. 🍲 Menestra ecuatoriana
5. 🥘 Paella
6. 🍖 Fritada ecuatoriana

---

## ✨ Funcionalidades Implementadas

### 🔍 1. Detección de Ingredientes (Feature: Detection)

**Componentes:**
- 15 archivos Dart (~160 KB de código)
- Motor de inferencia YOLO11n on-device
- Streaming de cámara en tiempo real
- Procesamiento desde galería

**Funcionalidades:**
- ✅ Carga del modelo TFLite (10.27 MB)
- ✅ Detección desde galería con ImagePicker
- ✅ Detección en tiempo real con streaming de cámara
- ✅ Preprocesamiento letterbox resize a 640×640
- ✅ Desnormalización de coordenadas (0-1 → 0-640 píxeles)
- ✅ Non-Maximum Suppression (NMS) por clase
- ✅ Visualización con bounding boxes personalizados
- ✅ Filtrado por ingrediente específico
- ✅ Optimización C++ con NEON SIMD (ARM)
- ✅ Procesamiento en isolate (no bloquea UI)
- ✅ Conversión YUV420→RGB optimizada (~10x más rápida)
- ✅ Throttling de frames para rendimiento
- ✅ Controles de cámara (flash, cambio de cámara)
- ✅ Panel de configuración (CameraSettingsPanel)

**Archivos críticos:**
- `lib/features/detection/services/yolo_detector.dart` (35 KB)
- `lib/features/detection/services/camera_frame_processor.dart` (16 KB)
- `lib/features/detection/services/detection_controller.dart` (17 KB)
- `android/app/src/main/cpp/native_image_processor.cpp` (287 líneas)
- `lib/features/nutrition/widgets/quantity_adjustment_dialog.dart` (346 líneas)
- `lib/features/nutrition/state/ingredient_quantities_notifier.dart` (323 líneas)
- `lib/data/models/performance_metrics.dart` (160 líneas)
- `lib/shared/widgets/gradient_button.dart`

**Configuración:**
- Confianza mínima: 0.40 (40%)
- IoU threshold: 0.30
- Clases: 83 ingredientes
- Platos: 6 (Caprese, Ceviche, Pizza, Menestra, Paella, Fritada)

---

### 📊 2. Sistema Nutricional (Feature: Nutrition)

**Componentes:**
- 8 archivos Dart (~80 KB de código)
- Base de datos USDA FoodData Central
- Sistema de cantidades con porciones estándar

**Funcionalidades:**
- ✅ Base de datos JSON con 80 ingredientes
- ✅ Información nutricional de 6 platos completos
- ✅ Cálculo de macronutrientes (calorías, proteínas, carbohidratos, grasas)
- ✅ Repositorio con cache en memoria
- ✅ Widgets UI: NutritionCard, NutrientBar, NutritionSummary
- ✅ Integración con detección desde galería
- ✅ Sistema de cantidades (FASE 6A-6B):
  - Modelos: QuantityUnit, QuantitySource, StandardPortion
  - Base de datos: 83 ingredientes × ~4 porciones c/u
  - Repositorio de porciones con cache
  - State management: IngredientQuantitiesNotifier (115 tests)
  - Providers Riverpod para cantidades
  - Cálculo de nutrientes con cantidades personalizadas

**Archivos críticos:**
- `lib/data/repositories/nutrition_repository.dart` (11.5 KB)
- `lib/data/repositories/portion_repository.dart` (12 KB)
- `lib/features/nutrition/state/ingredient_quantities_notifier.dart`
- `assets/data/nutrition_fdc.json` (31 KB)
- `assets/data/standard_portions.json` (11 KB)

**Estado:**
- FASE 6A ✅ 100%
- FASE 6B ✅ 100% (lógica completa, 115 tests)
- FASE 6C ⏳ Pendiente (widgets UI)

---

### 🔐 3. Autenticación Firebase (Feature: Auth)

**Componentes:**
- 7 archivos Dart
- Firebase Authentication + Firestore

**Funcionalidades:**
- ✅ Registro con email/password
- ✅ Inicio de sesión
- ✅ Cierre de sesión
- ✅ Recuperación de contraseña (forgot password)
- ✅ Gestión de perfiles en Firestore
- ✅ Navegación condicional basada en estado de auth
- ✅ Redirección automática (no auth → login, perfil incompleto → setup)
- ✅ Stream de cambios de autenticación en tiempo real
- ✅ Validación de inputs con InputValidator (133 tests)

**Servicios:**
- `FirebaseAuthService`: Wrapper de FirebaseAuth
- `FirestoreUserService`: CRUD de usuarios
- `AuthRepository`: Combina auth + firestore
- `SessionManager`: Gestión de sesión activa

**Modelos:**
- `AuthState`: Estados (loading, authenticated, unauthenticated, error)
- `UserProfile`: Perfil completo con validaciones

**Archivos críticos:**
- `lib/features/auth/services/firebase_auth_service.dart`
- `lib/features/auth/repositories/auth_repository.dart`
- `lib/features/auth/providers/auth_provider.dart` (11.3 KB)

---

### 🚀 4. Onboarding (Feature: Onboarding)

**Funcionalidades:**
- ✅ SplashScreen con animación de carga
- ✅ WelcomeScreen con introducción
- ✅ Navegación automática según estado de auth
- ✅ Transiciones animadas (fade, slide)

**Archivos:**
- `lib/features/onboarding/views/splash_screen.dart`
- `lib/features/onboarding/views/welcome_screen.dart`

---

### 👤 5. Perfil de Usuario (Feature: Profile)

**Funcionalidades:**
- ✅ Pantalla de perfil completa
- ✅ Edición de perfil (nombre, email, avatar)
- ✅ Avatares generados con iniciales
- ✅ Sincronización con Firestore
- ✅ ProfileSetupScreen para completar perfil post-registro
- ✅ Validación de campos

**Campos del perfil:**
- ID de usuario (UID Firebase)
- Email, nombre completo
- Foto de perfil (URL o null)
- Fecha de creación
- Flag de onboarding completado

**Archivos:**
- `lib/features/profile/views/profile_screen.dart`
- `lib/features/profile/views/edit_profile_screen.dart`

---

### 🏠 6. Pantalla Principal (Feature: Home)

**Funcionalidades:**
- ✅ Diseño moderno con SliverAppBar expandible
- ✅ Gradient background animado
- ✅ Botones de acceso rápido a detección
- ✅ Avatar/botón de perfil en AppBar
- ✅ Scroll parallax effect
- ✅ Indicador de modo runtime (debug/profile/release)

**Archivo:**
- `lib/features/home/views/home_screen.dart`

---

### 🛠️ 7. Módulos Core

#### Sistema de Logging
- ✅ Logger centralizado (AppLogger)
- ✅ Niveles: debug, info, warning, error, critical
- ✅ Configuración por entorno
- ✅ Colores en consola
- ✅ Timestamps automáticos
- ✅ Tags para filtrado
- ✅ 39 tests unitarios

#### Sistema de Excepciones
- ✅ Jerarquía de 17 tipos de excepciones personalizadas
- ✅ Mensajes técnicos + mensajes de usuario
- ✅ ExceptionHandler para wrapping
- ✅ Validaciones en constructores
- ✅ Integración con todos los servicios

#### Sistema de Seguridad
- ✅ InputValidator con 133 tests
- ✅ Validación de emails (RFC 5322)
- ✅ Validación de contraseñas (longitud, complejidad)
- ✅ Validación de nombres
- ✅ Sanitización de inputs
- ✅ Prevención XSS y SQL injection

#### Gestión de Sesión
- ✅ SessionManager centralizado
- ✅ Gestión de sesión activa de usuario
- ✅ Integración con AuthRepository

---

### 🎨 8. Widgets Compartidos (Shared: 7 componentes)

| Widget | Líneas | Uso |
|--------|--------|-----|
| **RuntimeModeIndicator** | ~140 | Muestra modo debug/profile/release |
| **AnimatedCounter** | ~250 | Contador animado para nutrientes |
| **FeedbackWidgets** | ~600 | Snackbars, toasts, diálogos |
| **InfoCard** | ~370 | Card genérico de información |
| **LoadingOverlay** | ~330 | Overlay de carga con spinner |
| **GradientButton** | ~280 | Botón con gradiente personalizado |
| **Widgets** | ~20 | Barrel export |

**Ubicación:**
- `lib/shared/widgets/`

---

### ⚡ 9. Optimización Nativa (Android: C++)

**Funcionalidades:**
- ✅ Conversión YUV420 → RGB en C++ con NEON SIMD
- ✅ Procesamiento paralelo de 8 píxeles (ARM SIMD)
- ✅ Fallback automático a versión scalar
- ✅ JNI bindings con MethodChannel
- ✅ Mejora de rendimiento ~10x vs Dart puro

**Archivos:**
- `android/app/src/main/cpp/native_image_processor.cpp` (287 líneas)
- `android/app/src/main/cpp/yuv_to_rgb.h` (87 líneas)
- `android/app/src/main/cpp/CMakeLists.txt`

**Rendimiento:**
| Implementación | Tiempo por frame | Mejora |
|----------------|------------------|--------|
| Dart puro | ~50ms | 1x |
| C++ con NEON | ~5ms | **~10x** |

---

## 🎬 Casos de Uso Principales

### CU-001: Detectar Ingredientes desde Galería
**Actor:** Usuario
**Precondición:** App instalada, permisos de galería otorgados
**Flujo principal:**
1. Usuario abre la app
2. Usuario toca "Desde Galería" en HomeScreen
3. Sistema abre selector de imágenes
4. Usuario selecciona foto de plato de comida
5. Sistema procesa imagen con YOLO11n
6. Sistema muestra bounding boxes sobre ingredientes
7. Sistema consulta base de datos nutricional
8. Sistema muestra NutritionCard con macronutrientes
**Resultado:** Usuario ve ingredientes detectados con información nutricional

---

### CU-002: Detectar Ingredientes en Tiempo Real
**Actor:** Usuario
**Precondición:** Dispositivo con cámara, permisos otorgados
**Flujo principal:**
1. Usuario toca "Cámara en Vivo"
2. Sistema solicita permiso de cámara (si no otorgado)
3. Sistema inicializa cámara con ResolutionPreset.medium
4. Sistema muestra preview de cámara
5. Sistema ejecuta detección cada N frames (frame skip)
6. Sistema dibuja bounding boxes en overlay en tiempo real
7. Usuario apunta cámara a plato de comida
8. Sistema actualiza detecciones automáticamente
**Resultado:** Usuario ve detecciones en tiempo real con overlay

---

### CU-003: Registrarse e Iniciar Sesión
**Actor:** Usuario nuevo
**Precondición:** App instalada, conexión a internet
**Flujo principal:**
1. Usuario abre app por primera vez
2. Sistema muestra SplashScreen → WelcomeScreen
3. Usuario toca "Crear Cuenta"
4. Usuario ingresa email y contraseña
5. Sistema valida inputs con InputValidator
6. Sistema crea cuenta en Firebase Auth
7. Sistema crea perfil en Firestore
8. Sistema redirige a ProfileSetupScreen
9. Usuario completa nombre y preferencias
10. Sistema marca onboarding como completado
11. Sistema redirige a HomeScreen
**Resultado:** Usuario autenticado con perfil completo

---

### CU-004: Ver Perfil de Usuario
**Actor:** Usuario autenticado
**Precondición:** Sesión activa
**Flujo principal:**
1. Usuario toca avatar en AppBar
2. Sistema navega a ProfileScreen
3. Sistema muestra:
   - Avatar con iniciales
   - Nombre completo
   - Email
   - Botón de editar perfil
   - Botón de cerrar sesión
4. Usuario puede editar perfil o cerrar sesión
**Resultado:** Usuario ve información de su perfil

---

### CU-005: Filtrar Ingredientes Detectados
**Actor:** Usuario
**Precondición:** Detección completada desde galería
**Flujo principal:**
1. Usuario ve lista de ingredientes detectados
2. Usuario toca un ingrediente específico (ej: "tomate")
3. Sistema filtra y resalta solo detecciones de ese ingrediente
4. Sistema muestra chip con "Filtrando: tomate"
5. Bounding boxes cambian a color azul
6. Usuario toca chip o ingrediente nuevamente para quitar filtro
**Resultado:** Vista filtrada de un solo ingrediente

---

### CU-006: Consultar Información Nutricional
**Actor:** Usuario
**Precondición:** Ingredientes detectados desde galería
**Flujo principal:**
1. Sistema detecta ingredientes en imagen
2. Sistema consulta NutritionRepository por cada ingrediente
3. Sistema calcula macronutrientes totales del plato
4. Sistema muestra NutritionCard con:
   - Calorías totales
   - Proteínas (g)
   - Carbohidratos (g)
   - Grasas (g)
5. Usuario puede ver desglose por ingrediente
**Resultado:** Usuario conoce información nutricional estimada

---

### CU-007: Ajustar Cantidades de Ingredientes
**Actor:** Usuario
**Precondición:** Detección completada, sistema de cantidades inicializado
**Flujo principal:**
1. Usuario ve ingredientes detectados con cantidades por defecto (100g)
2. Usuario toca botón de ajustar cantidad
3. Sistema muestra opciones:
   - Porciones estándar (ej: 1 taza, 1 unidad, 1 cucharada)
   - Gramos personalizados
4. Usuario selecciona nueva cantidad
5. Sistema recalcula nutrientes con nueva cantidad
6. Sistema actualiza NutritionCard con valores nuevos
**Resultado:** Información nutricional ajustada a cantidad real
**Estado:** Lógica implementada (FASE 6B), UI pendiente (FASE 6C)

---

### CU-008: Recuperar Contraseña Olvidada
**Actor:** Usuario registrado que olvidó su contraseña
**Precondición:** Cuenta existente en Firebase
**Flujo principal:**
1. Usuario toca "¿Olvidaste tu contraseña?" en LoginScreen
2. Sistema muestra campo para ingresar email
3. Usuario ingresa email
4. Sistema valida formato de email
5. Sistema envía correo de recuperación via Firebase
6. Sistema muestra confirmación
7. Usuario revisa email y sigue link
8. Usuario establece nueva contraseña
**Resultado:** Contraseña restablecida

---

## 👥 Historias de Usuario

### Detección de Ingredientes

**HU-001:** Como usuario, quiero tomar una foto de mi plato de comida para conocer qué ingredientes contiene.

**HU-002:** Como usuario, quiero usar la cámara en tiempo real para ver qué ingredientes detecta la app sin tomar foto.

**HU-003:** Como usuario, quiero seleccionar una imagen de mi galería para analizar un plato que fotografié antes.

**HU-004:** Como usuario, quiero ver cuadros (bounding boxes) alrededor de cada ingrediente detectado para saber exactamente qué identificó la app.

**HU-005:** Como usuario, quiero filtrar las detecciones por un ingrediente específico para ver solo ese ingrediente en la imagen.

---

### Información Nutricional

**HU-006:** Como usuario preocupado por mi alimentación, quiero ver las calorías totales de mi plato para controlar mi ingesta diaria.

**HU-007:** Como usuario, quiero ver los macronutrientes (proteínas, carbohidratos, grasas) de cada ingrediente para planificar mis comidas.

**HU-008:** Como usuario, quiero ajustar las cantidades de cada ingrediente detectado para obtener información nutricional más precisa según lo que realmente voy a comer.

**HU-009:** Como usuario, quiero ver porciones estándar (taza, cucharada, unidad) en lugar de solo gramos para facilitar la medición.

---

### Autenticación y Perfil

**HU-010:** Como usuario nuevo, quiero registrarme con mi email y contraseña para tener acceso personalizado a la app.

**HU-011:** Como usuario registrado, quiero iniciar sesión para acceder a mis datos guardados y preferencias.

**HU-012:** Como usuario, quiero editar mi perfil (nombre, foto) para personalizar mi experiencia.

**HU-013:** Como usuario, quiero cerrar sesión para proteger mi privacidad cuando comparto el dispositivo.

**HU-014:** Como usuario que olvidó su contraseña, quiero recibir un correo de recuperación para poder acceder nuevamente a mi cuenta.

---

### Experiencia de Usuario

**HU-015:** Como usuario nuevo, quiero ver una pantalla de bienvenida la primera vez que abro la app para entender cómo funciona.

**HU-016:** Como desarrollador, quiero ver un indicador de modo debug/profile/release para saber en qué entorno estoy ejecutando la app.

**HU-017:** Como usuario, quiero que la app funcione offline para poder usarla sin conexión a internet (detección y cálculo nutricional).

**HU-018:** Como usuario, quiero ver mensajes de error claros cuando algo falla para saber qué hacer.

---

## 🏗️ Stack Tecnológico Completo

### Framework Principal

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **Flutter SDK** | 3.38.4 (stable) | Framework de desarrollo |
| **Dart** | 3.10.3 | Lenguaje de programación |
| **Android SDK** | API 26-35 | Compilación Android |
| **NDK** | Automático | C++ nativo para optimizaciones |

---

### Machine Learning

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **TensorFlow Lite** | 0.11.0 | Inferencia on-device |
| **YOLO11n** | Ultralytics | Arquitectura del modelo |
| **XNNPack Delegate** | Incluido | Aceleración CPU |
| **NEON SIMD** | ARM v7a/v8a | Optimización YUV→RGB |

---

### Backend & Autenticación

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **Firebase Core** | 3.8.0 | Inicialización Firebase |
| **Firebase Auth** | 5.3.3 | Autenticación de usuarios |
| **Cloud Firestore** | 5.5.1 | Base de datos NoSQL en la nube |

---

### State Management & Arquitectura

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **flutter_riverpod** | 2.6.1 | Gestión de estado reactiva |
| **riverpod_annotation** | 2.6.1 | Generación de código |
| **riverpod_generator** | 2.6.2 | Generador de providers |
| **go_router** | 14.6.2 | Navegación declarativa |

---

### Cámara & Imágenes

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **camera** | 0.11.0+2 | Acceso a cámara con streaming |
| **image_picker** | 1.1.2 | Selección desde galería |
| **image** | 4.3.0 | Procesamiento de imágenes |

---

### Base de Datos Local

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **sqflite** | 2.4.1 | SQLite para Flutter |
| **sqlite3_flutter_libs** | 0.5.28 | Librerías nativas SQLite |
| **shared_preferences** | 2.3.3 | Almacenamiento clave-valor |

---

### UI & Diseño

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **google_fonts** | 6.2.1 | Tipografías de Google |
| **flutter_svg** | 2.0.10+1 | Renderizado de SVG |
| **shimmer** | 3.0.0 | Skeleton loading |
| **fl_chart** | 0.69.0 | Gráficos de nutrientes |
| **lottie** | 3.1.3 | Animaciones |
| **cached_network_image** | 3.4.1 | Cache de imágenes |

---

### Permisos & Sistema

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **permission_handler** | 11.3.1 | Manejo de permisos runtime |
| **device_info_plus** | 11.1.0 | Información del dispositivo |
| **path_provider** | 2.1.5 | Rutas del sistema |

---

### Utilidades

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **intl** | 0.19.0 | Internacionalización |
| **collection** | 1.18.0 | Extensiones de colecciones |
| **uuid** | 4.5.1 | Generación de IDs únicos |
| **share_plus** | 10.1.2 | Compartir contenido |

---

### Desarrollo & Testing

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **flutter_test** | SDK | Framework de testing |
| **flutter_lints** | 5.0.0 | Reglas de linting |
| **build_runner** | 2.4.13 | Generación de código |
| **flutter_launcher_icons** | 0.13.1 | Generación de iconos |

---

### Código Nativo

| Tecnología | Lenguaje | Propósito |
|------------|----------|-----------|
| **JNI Bindings** | C++ | Interoperabilidad Java-C++ |
| **ARM NEON** | Assembly | Instrucciones SIMD para ARM |
| **CMake** | 3.x | Build system para C++ |

---

## 🔄 Diagrama de Flujo de Datos

### Arquitectura de Capas

```
┌─────────────────────────────────────────────────────────────────┐
│                         CAPA DE UI                              │
│  (Pantallas: Home, Gallery, Live, Profile, Auth)                │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CAPA DE PROVIDERS                             │
│  (Riverpod: detectorProvider, authStateProvider,                │
│   nutritionProvider, quantityProvider, cameraProvider)          │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                   CAPA DE SERVICIOS                              │
│  YoloDetector ←→ CameraFrameProcessor ←→ NativeImageProcessor   │
│  NutritionService ←→ FirebaseAuthService ←→ SessionManager      │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                 CAPA DE REPOSITORIOS                             │
│  NutritionRepository ←→ PortionRepository ←→ AuthRepository     │
│  SettingsRepository                                              │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                CAPA DE DATASOURCES                               │
│  NutritionDatasource (JSON) ←→ PortionDatasource (JSON)         │
│  FirebaseAuth ←→ Firestore ←→ SharedPreferences                 │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                   FUENTES DE DATOS                               │
│  assets/data/nutrition_fdc.json (80 ingredientes)               │
│  assets/data/standard_portions.json (83 ingredientes)           │
│  assets/models/yolov11n_float32.tflite (10.27 MB)               │
│  Firebase Authentication + Firestore                             │
└─────────────────────────────────────────────────────────────────┘
```

---

### Flujo Específico: Detección desde Galería

```
Usuario toca "Desde Galería"
    │
    ├──> DetectionGalleryScreen
    │       │
    │       ├──> ImagePicker.pickImage()
    │       │       │
    │       │       └──> Archivo XFile
    │       │
    │       ├──> ref.watch(detectorProvider)
    │       │       │
    │       │       └──> YoloDetector.detect(image)
    │       │               │
    │       │               ├──> Preprocesamiento (letterbox resize)
    │       │               ├──> Inferencia TFLite
    │       │               └──> Postprocesamiento (NMS)
    │       │                       │
    │       │                       └──> List<Detection>
    │       │
    │       └──> ref.watch(nutritionProvider)
    │               │
    │               └──> NutritionService.getMultipleNutrition()
    │                       │
    │                       └──> NutritionRepository.getIngredient()
    │                               │
    │                               └──> NutritionDatasource.loadData()
    │                                       │
    │                                       └──> JSON parse
    │
    └──> UI actualiza con:
            - BoundingBoxPainter (detecciones)
            - NutritionCard (macronutrientes)
            - Lista de ingredientes
```

---

### Flujo Específico: Autenticación

```
Usuario toca "Crear Cuenta"
    │
    ├──> RegisterScreen
    │       │
    │       ├──> InputValidator.validateEmail()
    │       ├──> InputValidator.validatePassword()
    │       │
    │       └──> ref.watch(authRepositoryProvider).signUp()
    │               │
    │               ├──> FirebaseAuthService.signUpWithEmailAndPassword()
    │               │       │
    │               │       └──> Firebase Authentication
    │               │
    │               └──> FirestoreUserService.createUser()
    │                       │
    │                       └──> Cloud Firestore
    │
    └──> authStateProvider emite AuthStateAuthenticated
            │
            └──> GoRouter redirige a ProfileSetupScreen
```

---

## 🔗 Interacciones entre Módulos

### 1. Detection ↔ Nutrition

**Dirección:** Detection → Nutrition (unidireccional)

**Descripción:**
La feature de detección alimenta a la feature de nutrición con los ingredientes detectados.

**Flujo:**
1. `DetectionGalleryScreen` ejecuta detección con `YoloDetector`
2. Obtiene `List<Detection>` con labels de ingredientes
3. Extrae labels únicos: `detections.uniqueLabels`
4. Consulta `NutritionService.getMultipleNutrition(labels)`
5. Muestra resultados en `NutritionCard` y `NutritionSummary`

**Archivos involucrados:**
- `lib/features/detection/views/detection_gallery_screen.dart`
- `lib/features/nutrition/services/nutrition_service.dart`
- `lib/features/nutrition/providers/nutrition_provider.dart`
- `lib/features/nutrition/widgets/nutrition_card.dart`

---

### 2. Auth ↔ Navigation (GoRouter)

**Dirección:** Bidireccional

**Descripción:**
El sistema de autenticación controla la navegación de la app mediante redirects condicionales.

**Flujo:**
1. `authStateProvider` expone estado de autenticación
2. `appRouterProvider` observa `authStateProvider` con `ref.watch()`
3. GoRouter ejecuta `redirect:` en cada cambio de ruta
4. Lógica de redirección:
   - No autenticado + ruta protegida → `/welcome`
   - Autenticado + ruta de auth → `/` (home)
   - Autenticado + perfil incompleto → `/profile-setup`
5. Providers de auth disparan cambios en UI automáticamente

**Archivos involucrados:**
- `lib/app/routes.dart`
- `lib/features/auth/providers/auth_provider.dart`
- `lib/features/auth/repositories/auth_repository.dart`
- `lib/core/session/session_manager.dart`

---

### 3. Camera ↔ Detection (Tiempo Real)

**Dirección:** Camera → Detection (pipeline)

**Descripción:**
La cámara alimenta frames en tiempo real al sistema de detección con conversión optimizada.

**Flujo:**
1. `DetectionLiveScreen` inicializa `CameraController`
2. Inicia `startImageStream()` con callback
3. Por cada frame (YUV420):
   - `CameraFrameProcessor.processFrame()`
   - Intenta conversión nativa C++ vía `NativeImageProcessor`
   - Si falla, usa Dart Isolate con `ImageProcessingIsolate`
   - Convierte YUV420 → RGB
   - Envía a `YoloDetector.detect()`
   - Retorna `List<Detection>`
4. `DetectionOverlay` dibuja bounding boxes sobre camera preview
5. Throttling con `frameSkip` y `minInferenceIntervalMs`

**Archivos involucrados:**
- `lib/features/detection/views/detection_live_screen.dart`
- `lib/features/detection/services/camera_frame_processor.dart`
- `lib/features/detection/services/native_image_processor.dart`
- `lib/features/detection/services/image_processing_isolate.dart`
- `lib/features/detection/widgets/detection_overlay.dart`
- `android/app/src/main/cpp/native_image_processor.cpp`

---

### 4. Nutrition ↔ Quantities (FASE 6B)

**Dirección:** Bidireccional

**Descripción:**
El sistema de cantidades permite ajustar porciones y recalcular nutrientes dinámicamente.

**Flujo:**
1. Usuario detecta ingredientes
2. `IngredientQuantitiesNotifier` inicializa cantidades por defecto (100g)
3. Usuario ajusta cantidad de un ingrediente
4. Notifier actualiza estado con nueva cantidad
5. `NutritionRepository.calculateTotalNutrientsWithQuantities()` recalcula
6. UI (NutritionCard) se actualiza automáticamente vía providers

**Archivos involucrados:**
- `lib/features/nutrition/state/ingredient_quantities_notifier.dart` (115 tests)
- `lib/features/nutrition/providers/quantity_provider.dart`
- `lib/data/repositories/nutrition_repository.dart`
- `lib/data/repositories/portion_repository.dart`
- `lib/data/models/ingredient_quantity.dart`
- `lib/data/models/standard_portion.dart`

**Estado:** Lógica completa (FASE 6B ✅), UI widgets pendientes (FASE 6C ⏳)

---

### 5. Core (Logging, Exceptions) ↔ Todos los Módulos

**Dirección:** Todos → Core (dependencia universal)

**Descripción:**
Los módulos core (logging, exceptions) son usados por todos los demás módulos del proyecto.

**Logging:**
1. Todos los servicios importan `app_logger.dart`
2. Uso de niveles:
   - `AppLogger.info()` para eventos normales
   - `AppLogger.warning()` para situaciones anormales
   - `AppLogger.error()` para errores
3. Solo se imprimen logs según `LogConfig` (filtrado por nivel)

**Excepciones:**
1. Try-catch en servicios lanzan excepciones personalizadas
2. UI captura excepciones con `on NutriVisionException catch (e)`
3. `ExceptionHandler.getUserMessage(e)` para mensajes de usuario
4. `ExceptionHandler.logError(e)` para debugging

**Ejemplos:**
```dart
// YoloDetector
AppLogger.info('Modelo cargado correctamente', tag: 'YoloDetector');
throw ModelNotInitializedException();

// FirebaseAuthService
AppLogger.error('Error en login: $errorCode', tag: 'Auth');
throw AuthException(message: 'Credenciales inválidas');
```

**Archivos involucrados:**
- `lib/core/logging/app_logger.dart`
- `lib/core/exceptions/app_exceptions.dart`
- Todos los servicios del proyecto

---

## 💻 Requisitos Previos

### Hardware mínimo (PC de desarrollo)

- **RAM:** 8 GB (recomendado 16 GB)
- **Almacenamiento:** 10 GB libres para SDKs
- **SO:** Windows 10/11 64-bit

### Software requerido

| Software | Versión | Descarga |
|----------|---------|----------|
| Flutter SDK | 3.38.4 (stable) | [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install) |
| Dart SDK | 3.10.3 | Incluido con Flutter |
| Android Studio | 2024.x (Ladybug) | [developer.android.com/studio](https://developer.android.com/studio) |
| Git | 2.x | [git-scm.com](https://git-scm.com/) |
| VS Code (opcional) | Latest | [code.visualstudio.com](https://code.visualstudio.com/) |

### Android SDK Components

Instalar desde Android Studio → **Settings → SDK Manager → SDK Tools**:

| Componente | Versión |
|------------|---------|
| Android SDK Build-Tools | 35.0.0 |
| Android SDK Command-line Tools | Latest |
| Android SDK Platform-Tools | Latest |
| Android Emulator | Latest |
| Android SDK Platform | API 34 o 35 |

### Dispositivo Android de prueba

- **API mínima:** 26 (Android 8.0 Oreo)
- **API objetivo:** 34 (Android 14)
- **RAM recomendada:** 4 GB+
- **Cámara:** Requerida para captura en tiempo real

---

## 🛠️ Instalación del Entorno de Desarrollo

### Paso 1: Instalar Flutter SDK

```powershell
# 1. Descargar Flutter SDK desde https://flutter.dev/docs/get-started/install/windows
# 2. Extraer en una carpeta SIN espacios, ej: C:\src\flutter

# 3. Agregar Flutter al PATH (PowerShell como Admin)
[Environment]::SetEnvironmentVariable("Path", "$env:Path;C:\src\flutter\bin", "User")

# 4. Reiniciar la terminal y verificar
flutter --version
```

### Paso 2: Configurar Variables de Entorno de Android

```powershell
# Configurar ANDROID_HOME (PowerShell como Admin)
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LOCALAPPDATA\Android\Sdk", "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "$env:LOCALAPPDATA\Android\Sdk", "User")

# Agregar platform-tools al PATH
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools"
[Environment]::SetEnvironmentVariable("Path", "$env:Path;$sdkPath", "User")
```

### Paso 3: Instalar plugins en Android Studio

1. Abrir **Android Studio**
2. Ir a **File → Settings → Plugins**
3. Buscar e instalar **Flutter** (incluye Dart automáticamente)
4. Reiniciar Android Studio

### Paso 4: Configurar Flutter SDK en Android Studio

1. Ir a **File → Settings → Languages & Frameworks → Flutter**
2. En **Flutter SDK path**, poner: `C:\src\flutter` (o tu ruta)
3. Click en **Apply** y **OK**

### Paso 5: Aceptar licencias de Android

```powershell
flutter doctor --android-licenses
# Presionar 'y' para aceptar todas
```

### Paso 6: Verificar instalación

```powershell
flutter doctor -v
```

**Resultado esperado (todo en ✓):**

```
[✓] Flutter (Channel stable, 3.38.4)
[✓] Dart SDK (3.10.3)
[✓] Windows Version (Windows 11)
[✓] Android toolchain - develop for Android devices (Android SDK 35.0.0)
[✓] Android Studio (version 2024.x)
[✓] VS Code (optional)
[✓] Connected device (1 available)
```

---

## 📁 Estructura del Proyecto

### Arquitectura Feature-First (Implementada)

```
nutrivision_aiepn_mobile/
│
├── android/                              # ✅ Configuración nativa Android
│   ├── app/
│   │   ├── build.gradle.kts             # Configuración de build
│   │   ├── proguard-rules.pro           # Reglas ProGuard para TFLite
│   │   ├── src/main/AndroidManifest.xml # Permisos de la app
│   │   └── src/main/cpp/                # ✅ Código nativo C++
│   │       ├── native_image_processor.cpp # Conversión YUV→RGB optimizada
│   │       ├── yuv_to_rgb.h               # Optimizaciones NEON (ARM SIMD)
│   │       └── CMakeLists.txt             # Build configuration
│   └── build.gradle.kts
│
├── assets/                               # ✅ Recursos de la app
│   ├── models/yolov11n_float32.tflite   # Modelo YOLO11n (~10 MB)
│   ├── labels/labels.txt                # 83 clases de ingredientes
│   └── data/
│       ├── nutrition_fdc.json           # Base de datos nutricional (80 ingredientes)
│       ├── standard_portions.json       # Base de datos de porciones (83 ingredientes)
│       └── fooddata.db                  # Base de datos SQLite (48 KB)
│
├── lib/                                  # Código fuente Dart/Flutter
│   ├── main.dart                        # ✅ Punto de entrada
│   │
│   ├── app/                             # ✅ Configuración de la app
│   │   ├── app.dart                     # Widget principal NutriVisionApp
│   │   └── routes.dart                  # Navegación con go_router
│   │
│   ├── core/                            # ✅ Núcleo compartido
│   │   ├── constants/app_constants.dart # Constantes globales
│   │   ├── theme/app_theme.dart         # Sistema de temas
│   │   ├── exceptions/app_exceptions.dart # Excepciones personalizadas
│   │   ├── logging/                     # Sistema de logging centralizado
│   │   │   ├── app_logger.dart          # Logger principal
│   │   │   ├── log_config.dart          # Configuración de logging
│   │   │   └── log_level.dart           # Niveles de log
│   │   ├── security/                    # ✅ NEW: Seguridad y validación
│   │   │   └── input_validator.dart     # Validación de inputs (133 tests)
│   │   ├── session/session_manager.dart # Gestión de sesión
│   │   └── utils/                       # ✅ NEW: Utilidades compartidas
│   │       └── runtime_mode.dart        # Detección de entorno (debug/profile/release)
│   │
│   ├── data/                            # ✅ Capa de datos
│   │   ├── models/
│   │   │   ├── detection.dart           # Modelo de detección YOLO
│   │   │   ├── nutrients_per_100g.dart  # Nutrientes por 100g
│   │   │   ├── nutrition_info.dart      # Información nutricional
│   │   │   ├── nutrition_data.dart      # Contenedor de datos
│   │   │   ├── quantity_enums.dart      # Enums de cantidades
│   │   │   ├── standard_portion.dart    # Modelo de porciones
│   │   │   ├── ingredient_quantity.dart # Cantidad de ingrediente
│   │   │   ├── user_profile.dart        # Perfil de usuario
│   │   │   ├── auth_state.dart          # Estado de autenticación
│   │   │   ├── camera_settings.dart     # ✅ NEW: Configuración de cámara
│   │   │   └── performance_metrics.dart # ✅ NEW: Métricas de rendimiento
│   │   ├── datasources/
│   │   │   ├── nutrition_datasource.dart # Carga JSON de nutrientes
│   │   │   └── portion_datasource.dart  # Carga JSON de porciones
│   │   └── repositories/
│   │       ├── nutrition_repository.dart # Repositorio nutrición con cache
│   │       ├── portion_repository.dart  # Repositorio porciones con cache
│   │       └── settings_repository.dart # ✅ NEW: Repositorio de configuración
│   │
│   └── features/                        # ✅ Feature-First Architecture
│       ├── detection/                   # Feature de detección YOLO
│       │   ├── providers/
│       │   │   ├── detector_provider.dart    # Singleton del detector
│       │   │   └── camera_provider.dart      # Estado de cámara
│       │   ├── services/
│       │   │   ├── yolo_detector.dart          # Motor de inferencia YOLO
│       │   │   ├── camera_frame_processor.dart # Conversión YUV→RGB
│       │   │   ├── image_processing_isolate.dart # Worker isolate para conversión
│       │   │   ├── native_image_processor.dart   # Cliente Dart para C++ nativo
│       │   │   ├── detection_controller.dart     # ✅ NEW: Controlador centralizado
│       │   │   └── detection_debug_helper.dart   # ✅ NEW: Helper para debugging
│       │   ├── views/
│       │   │   ├── detection_gallery_screen.dart # Detección desde galería + nutrición
│       │   │   ├── detection_live_screen.dart    # Detección en tiempo real
│       │   │   └── detection_results_screen.dart # ✅ NEW: Pantalla de resultados
│       │   └── widgets/
│       │       ├── camera_controls.dart         # Controles de cámara
│       │       ├── detection_overlay.dart       # Overlay con bounding boxes
│       │       └── camera_settings_panel.dart   # ✅ NEW: Panel configuración
│       ├── nutrition/                   # ✅ Sistema nutricional
│       │   ├── providers/
│       │   │   ├── nutrition_provider.dart # Providers Riverpod
│       │   │   └── quantity_provider.dart  # ✅ NEW: Provider de cantidades
│       │   ├── services/nutrition_service.dart   # Servicio singleton
│       │   ├── state/                   # ✅ NEW: State management
│       │   │   └── ingredient_quantities_notifier.dart # Notifier cantidades (115 tests)
│       │   └── widgets/
│       │       ├── nutrient_bar.dart        # Barra de progreso nutriente
│       │       ├── nutrition_card.dart      # Card de información nutricional
│       │       ├── nutrition_summary.dart   # Resumen total de nutrientes
│       │       └── quantity_adjustment_dialog.dart # ✅ NEW: Dialog ajuste cantidades
│       ├── auth/                        # ✅ Autenticación Firebase
│       │   ├── services/                # Firebase Auth + Firestore
│       │   ├── repositories/            # Auth repository
│       │   ├── providers/               # Auth state providers
│       │   └── views/                   # Login, Register, Profile Setup
│       ├── onboarding/                  # ✅ Onboarding
│       │   └── views/                   # Splash, Welcome screens
│       ├── profile/                     # ✅ Perfil de usuario
│       │   └── views/                   # Profile, Edit Profile screens
│       └── home/
│           └── views/
│               └── home_screen.dart         # Pantalla principal
│
├── shared/                              # ✅ NEW: Widgets compartidos
│   └── widgets/
│       ├── runtime_mode_indicator.dart  # Indicador visual modo runtime
│       ├── animated_counter.dart        # Contador animado para nutrientes
│       ├── feedback_widgets.dart        # Widgets de feedback (snackbars, toasts)
│       ├── info_card.dart               # Card de información genérico
│       └── loading_overlay.dart         # Overlay de carga
│
├── test/                                 # ✅ Tests automatizados (445 tests)
│   ├── ml/yolo_detector_test.dart       # 42 tests del detector
│   ├── data/models/
│   │   ├── nutrition_test.dart          # 33 tests de nutrición
│   │   ├── auth_state_test.dart         # ✅ NEW: 24 tests AuthState
│   │   ├── camera_settings_test.dart    # ✅ NEW: 14 tests CameraSettings
│   │   ├── ingredient_quantity_test.dart # ✅ NEW: 26 tests IngredientQuantity
│   │   └── user_profile_test.dart       # ✅ NEW: 18 tests UserProfile
│   ├── core/
│   │   ├── logging/                     # 39 tests de logging
│   │   └── security/
│   │       └── input_validator_test.dart # ✅ NEW: 133 tests InputValidator
│   ├── features/nutrition/state/
│   │   └── ingredient_quantities_notifier_test.dart # ✅ NEW: 115 tests
│   └── test_assets/test_images/         # 54 imágenes de prueba
│
├── pubspec.yaml                          # Dependencias
├── CLAUDE.md                             # Contexto para IA
└── README.md                             # Este archivo
```

---

## ⚙️ Configuración Inicial

### Paso 1: Clonar/Abrir el proyecto

```powershell
# Si es un repositorio existente
git clone https://github.com/tu-usuario/nutrivision_aiepn_mobile.git
cd nutrivision_aiepn_mobile

# O abrir el proyecto existente en Android Studio
# File → Open → Seleccionar carpeta del proyecto
```

### Paso 2: Crear la estructura de carpetas

```powershell
# Ejecutar desde la raíz del proyecto (PowerShell en Windows)
# Estructura Feature-First (ya implementada)
New-Item -ItemType Directory -Force -Path "assets\models"
New-Item -ItemType Directory -Force -Path "assets\labels"
New-Item -ItemType Directory -Force -Path "assets\data"
New-Item -ItemType Directory -Force -Path "lib\core\constants"
New-Item -ItemType Directory -Force -Path "lib\core\exceptions"
New-Item -ItemType Directory -Force -Path "lib\core\logging"
New-Item -ItemType Directory -Force -Path "lib\core\security"
New-Item -ItemType Directory -Force -Path "lib\core\session"
New-Item -ItemType Directory -Force -Path "lib\core\theme"
New-Item -ItemType Directory -Force -Path "lib\data\models"
New-Item -ItemType Directory -Force -Path "lib\data\repositories"
New-Item -ItemType Directory -Force -Path "lib\data\datasources"
New-Item -ItemType Directory -Force -Path "lib\features\detection\services"
New-Item -ItemType Directory -Force -Path "lib\features\detection\views"
New-Item -ItemType Directory -Force -Path "lib\features\detection\widgets"
New-Item -ItemType Directory -Force -Path "lib\features\detection\providers"
New-Item -ItemType Directory -Force -Path "lib\features\nutrition"
New-Item -ItemType Directory -Force -Path "lib\features\auth"
New-Item -ItemType Directory -Force -Path "lib\features\profile"
New-Item -ItemType Directory -Force -Path "lib\features\onboarding"
New-Item -ItemType Directory -Force -Path "lib\features\home"
New-Item -ItemType Directory -Force -Path "test\ml"
New-Item -ItemType Directory -Force -Path "test\core\logging"
New-Item -ItemType Directory -Force -Path "test\data\models"
New-Item -ItemType Directory -Force -Path "test\test_assets\test_images"
```

### Paso 3: Copiar archivos del modelo

Copiar los archivos generados en Kaggle:

```
assets/
├── models/
│   └── yolov11n_float32.tflite   ← Desde Kaggle
└── labels/
    └── labels.txt                 ← Desde Kaggle (83 clases)
```

### Paso 4: Obtener dependencias

```powershell
flutter pub get
```

---

## 📦 Dependencias (pubspec.yaml)

Reemplaza el contenido de `pubspec.yaml`:

```yaml
name: nutrivision_aiepn_mobile
description: "Aplicación móvil Flutter para reconocimiento automático de alimentos mediante visión por computador usando YOLO11n (TensorFlow Lite) ejecutado on-device. Estima macronutrientes consultando una base de datos SQLite local. Proyecto de Trabajo de Integración Curricular — EPN."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.6.0

dependencies:
  flutter:
    sdk: flutter

  # ═══════════════════════════════════════════════════════════════
  # UI & DISEÑO
  # ═══════════════════════════════════════════════════════════════
  cupertino_icons: ^1.0.8
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10+1
  shimmer: ^3.0.0                    # Loading skeleton
  fl_chart: ^0.69.0                  # Gráficos de nutrientes
  lottie: ^3.1.3                     # Animaciones

  # ═══════════════════════════════════════════════════════════════
  # MACHINE LEARNING - TensorFlow Lite
  # ═══════════════════════════════════════════════════════════════
  tflite_flutter: ^0.11.0            # Inferencia TFLite (última estable)
  
  # ═══════════════════════════════════════════════════════════════
  # CÁMARA & IMÁGENES
  # ═══════════════════════════════════════════════════════════════
  camera: ^0.11.0+2                  # Acceso a cámara con streaming
  image_picker: ^1.1.2               # Selección desde galería
  image: ^4.3.0                      # Procesamiento de imágenes (letterbox)
  
  # ═══════════════════════════════════════════════════════════════
  # PERMISOS & SISTEMA
  # ═══════════════════════════════════════════════════════════════
  permission_handler: ^11.3.1        # Manejo de permisos runtime
  device_info_plus: ^11.1.0          # Info del dispositivo (API level)
  path_provider: ^2.1.5              # Rutas del sistema de archivos
  
  # ═══════════════════════════════════════════════════════════════
  # BASE DE DATOS LOCAL
  # ═══════════════════════════════════════════════════════════════
  sqflite: ^2.4.1                    # SQLite para Flutter
  sqlite3_flutter_libs: ^0.5.28      # Librerías nativas SQLite
  
  # ═══════════════════════════════════════════════════════════════
  # ESTADO & ARQUITECTURA
  # ═══════════════════════════════════════════════════════════════
  flutter_riverpod: ^2.6.1           # Estado reactivo
  riverpod_annotation: ^2.6.1        # Generación de código Riverpod
  go_router: ^14.6.2                 # Navegación declarativa
  
  # ═══════════════════════════════════════════════════════════════
  # UTILIDADES
  # ═══════════════════════════════════════════════════════════════
  intl: ^0.19.0                      # Formateo de fechas/números
  collection: ^1.18.0                # Extensiones de colecciones
  uuid: ^4.5.1                       # Generación de IDs únicos
  share_plus: ^10.1.2                # Compartir resultados

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  
  # Generación de código
  build_runner: ^2.4.13
  riverpod_generator: ^2.6.2

# ═══════════════════════════════════════════════════════════════
# ASSETS - Registrar archivos del modelo
# ═══════════════════════════════════════════════════════════════
flutter:
  uses-material-design: true
  
  assets:
    # Modelo TFLite
    - assets/models/yolov11n_float32.tflite
    
    # Labels del modelo
    - assets/labels/labels.txt
    
    # Base de datos de nutrientes (se copia al primer inicio)
    - assets/data/
    
    # Imágenes y recursos
    - assets/images/
```

### Instalar dependencias

```powershell
flutter pub get
```

---

## 🤖 Configuración de Android

### android/app/build.gradle

Modifica el archivo `android/app/build.gradle`:

```groovy
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

// Cargar propiedades del keystore para firma
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "edu.epn.nutrivision.nutrivision_aiepn_mobile"
    compileSdk = 35  // API 35 (Android 15)
    
    // Requerido para tflite_flutter
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "edu.epn.nutrivision.nutrivision_aiepn_mobile"
        minSdk = 26           // Android 8.0 Oreo (requerido para TFLite GPU)
        targetSdk = 34        // Android 14
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Solo arquitecturas ARM (99% de dispositivos Android)
        ndk {
            abiFilters 'armeabi-v7a', 'arm64-v8a'
        }
    }
    
    // ═══════════════════════════════════════════════════════════
    // CRÍTICO: No comprimir archivos TFLite
    // ═══════════════════════════════════════════════════════════
    aaptOptions {
        noCompress 'tflite'
        noCompress 'lite'
    }
    
    // ═══════════════════════════════════════════════════════════
    // Configuración de firma para Release
    // ═══════════════════════════════════════════════════════════
    signingConfigs {
        release {
            keyAlias = keystoreProperties['keyAlias']
            keyPassword = keystoreProperties['keyPassword']
            storeFile = keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword = keystoreProperties['storePassword']
        }
    }

    buildTypes {
        debug {
            // Debug sin ofuscación para desarrollo
            shrinkResources false
            minifyEnabled false
        }
        release {
            signingConfig = signingConfigs.release
            shrinkResources true
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Dependencias adicionales si son necesarias
}
```

### android/app/proguard-rules.pro

Crear el archivo `android/app/proguard-rules.pro`:

```proguard
# ═══════════════════════════════════════════════════════════════════
# ProGuard rules para NutriVisionAIEPN Mobile
# ═══════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────
# Flutter
# ───────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# ───────────────────────────────────────────────────────────────────
# TensorFlow Lite (CRÍTICO - NO ELIMINAR)
# ───────────────────────────────────────────────────────────────────
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }

# TFLite Flutter Plugin
-keep class com.tfliteflutter.** { *; }
-keepclassmembers class com.tfliteflutter.** { *; }

# ───────────────────────────────────────────────────────────────────
# Mantener métodos nativos
# ───────────────────────────────────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

# ───────────────────────────────────────────────────────────────────
# SQLite
# ───────────────────────────────────────────────────────────────────
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# ───────────────────────────────────────────────────────────────────
# Suprimir warnings conocidos
# ───────────────────────────────────────────────────────────────────
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn com.google.android.gms.**
```

### android/gradle.properties

Agregar al archivo `android/gradle.properties`:

```properties
# Configuración de memoria para builds grandes
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError

# AndroidX
android.useAndroidX=true
android.enableJetifier=true

# Habilitar R8 full mode
android.enableR8.fullMode=true
```

---

## 🧠 Integración del Modelo TFLite

### Arquitectura del Detector

El detector YOLO está implementado con las siguientes características:

| Componente | Descripción |
|------------|-------------|
| **Preprocesamiento** | Letterbox resize a 640×640 con padding gris (114,114,114) |
| **Desnormalización** | Conversión de coordenadas 0-1 a 0-640 píxeles |
| **Inferencia** | TFLite con XNNPack delegate para compatibilidad universal |
| **Postprocesamiento** | Non-Maximum Suppression (NMS) por clase |
| **Configuración** | Confianza: 0.40, IoU: 0.45 |

### Flujo de Coordenadas (Corregido)

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. MODELO OUTPUT (Normalizado 0-1)                              │
│    cx=0.596, cy=0.080, w=0.151, h=0.127                         │
└─────────────────────────────────────┬───────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. DESNORMALIZAR (* 640)                                        │
│    cx=381, cy=51, w=96, h=81                                    │
└─────────────────────────────────────┬───────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. CONVERTIR A ESQUINAS                                         │
│    x1=333, y1=10, x2=429, y2=92 (espacio 640x640)               │
└─────────────────────────────────────┬───────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. QUITAR PADDING + ESCALAR A IMAGEN ORIGINAL                   │
│    x1, y1, x2, y2 (espacio imagen original)                     │
└─────────────────────────────────────┬───────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. ESCALAR A WIDGET (para renderizado)                          │
│    BoundingBoxPainter aplica scaleX, scaleY                     │
└─────────────────────────────────────────────────────────────────┘
```

### lib/features/detection/services/yolo_detector.dart

```dart
/// Detector de ingredientes alimenticios usando YOLO11n.
/// 
/// Características principales:
/// - Desnormalización de coordenadas (0-1 → 0-640)
/// - Letterbox preprocessing con padding gris
/// - NMS (Non-Maximum Suppression) por clase
/// - Manejo robusto de excepciones personalizadas
/// 
/// Uso:
/// ```dart
/// final detector = YoloDetector();
/// await detector.initialize();
/// 
/// final detections = await detector.detect(image);
/// for (final d in detections) {
///   print('${d.label}: ${d.confidenceFormatted}');
///   print('  bbox: [${d.x1}, ${d.y1}, ${d.x2}, ${d.y2}]');
/// }
/// 
/// detector.dispose();
/// ```
class YoloDetector {
  static const int inputSize = 640;
  static const int numClasses = 83;
  static const int numPredictions = 8400;
  static const double defaultConfidenceThreshold = 0.40;
  static const double defaultIouThreshold = 0.45;
  
  // ... implementación completa en lib/ml/yolo_detector.dart
}
```

### Código Clave: Desnormalización de Coordenadas

```dart
// Postprocesamiento - CRÍTICO: desnormalizar coordenadas
for (int i = 0; i < numPredictions; i++) {
  // 1. Leer valores normalizados (0-1)
  final double cxNorm = output[0][0][i];
  final double cyNorm = output[0][1][i];
  final double wNorm = output[0][2][i];
  final double hNorm = output[0][3][i];

  // 2. DESNORMALIZAR: multiplicar por inputSize (640)
  final double cx = cxNorm * inputSize;
  final double cy = cyNorm * inputSize;
  final double w = wNorm * inputSize;
  final double h = hNorm * inputSize;

  // 3. Convertir a esquinas en espacio 640x640
  final double x1Model = cx - w / 2;
  final double y1Model = cy - h / 2;
  final double x2Model = cx + w / 2;
  final double y2Model = cy + h / 2;

  // 4. Transformar a imagen original (quitar padding, escalar)
  final double x1 = (x1Model - preprocess.padLeft) / preprocess.scale;
  final double y1 = (y1Model - preprocess.padTop) / preprocess.scale;
  final double x2 = (x2Model - preprocess.padLeft) / preprocess.scale;
  final double y2 = (y2Model - preprocess.padTop) / preprocess.scale;

  // 5. Clampear a límites de imagen
  final double x1Clamped = x1.clamp(0.0, origWidth.toDouble());
  final double y1Clamped = y1.clamp(0.0, origHeight.toDouble());
  final double x2Clamped = x2.clamp(0.0, origWidth.toDouble());
  final double y2Clamped = y2.clamp(0.0, origHeight.toDouble());
  
  // ... crear Detection con coordenadas correctas
}
```

### lib/data/models/detection.dart

```dart
/// Representa una detección de ingrediente en una imagen.
/// 
/// Incluye:
/// - Coordenadas del bounding box (x1, y1, x2, y2)
/// - Nivel de confianza (0.0 - 1.0)
/// - ID de clase y etiqueta
/// - Validaciones automáticas en constructor
/// - Factory methods seguros (fromModelOutput, tryCreate)
/// 
/// Throws:
/// - [InvalidBoundingBoxException] si x2 <= x1 o y2 <= y1
/// - [InvalidConfidenceException] si confianza fuera de [0, 1]
/// - [InvalidClassIdException] si classId < 0
class Detection {
  final double x1, y1, x2, y2;
  final double confidence;
  final int classId;
  final String label;
  
  // Propiedades calculadas
  double get width => x2 - x1;
  double get height => y2 - y1;
  double get area => width * height;
  double get centerX => (x1 + x2) / 2;
  double get centerY => (y1 + y2) / 2;
  
  // Niveles de confianza
  bool get isHighConfidence => confidence >= 0.70;
  bool get isMediumConfidence => confidence >= 0.50 && confidence < 0.70;
  bool get isLowConfidence => confidence < 0.50;
  
  // ... implementación completa en lib/data/models/detection.dart
}

/// Extensiones para List<Detection>
extension DetectionListExtension on List<Detection> {
  List<Detection> filterByConfidence(double minConfidence);
  List<Detection> filterByLabel(String label);
  List<Detection> sortedByConfidence();
  Map<String, List<Detection>> groupByLabel();
  Set<String> get uniqueLabels;
  Map<String, int> get ingredientCounts;
  Detection? get mostConfident;
  double get averageConfidence;
  DetectionStats get stats;
}
```

---

## ⚡ Optimización Nativa (C++)

El proyecto incluye código nativo C++ para optimizar la conversión YUV→RGB en la detección en tiempo real:

### Archivos de Código Nativo

| Archivo | Descripción |
|---------|-------------|
| `android/app/src/main/cpp/native_image_processor.cpp` | Implementación JNI con bindings |
| `android/app/src/main/cpp/yuv_to_rgb.h` | Conversión optimizada con NEON SIMD |
| `android/app/src/main/cpp/CMakeLists.txt` | Configuración de build CMake |

### Características

- **NEON SIMD (ARM):** Procesa 8 píxeles en paralelo
- **Aritmética Q8:** Punto fijo para máxima velocidad
- **Fallback automático:** Si NEON no disponible, usa scalar
- **Platform Channel:** `edu.epn.nutrivision/native_image_processor`

### Rendimiento

| Implementación | Tiempo por frame | Mejora |
|----------------|------------------|--------|
| Dart puro | ~50ms | 1x |
| C++ con NEON | ~5ms | **~10x** |

### Pipeline de Procesamiento

```
CameraImage (YUV420)
    ↓
¿Nativo disponible?
    ├─ Sí → C++ NEON (~5ms)
    └─ No → Dart Isolate (~50ms)
    ↓
Imagen RGB
    ↓
YoloDetector.detect()
```

---

## 📁 Carpeta de Referencia

| Archivo | Propósito |
|---------|-----------|
| `reference/fdc_mapping_log.txt` | Log de mapeo de ingredientes con FoodData Central |
| `reference/nutrivision.yaml` | Configuración de referencia del proyecto |

**Nota:** Archivos de desarrollo y documentación interna, no usados en runtime.

---

## 🛡️ Sistema de Excepciones

### lib/core/exceptions/app_exceptions.dart

Se implementó un sistema completo de excepciones personalizadas para manejo robusto de errores:

```
NutriVisionException (base abstracta)
│
├── ModelException
│   ├── ModelLoadException          # Error cargando modelo TFLite
│   ├── LabelsLoadException         # Error cargando labels.txt
│   ├── ModelNotInitializedException # Detector no inicializado
│   └── ModelDisposedException      # Detector ya fue disposed
│
├── InferenceException
│   ├── PreprocessingException      # Error en letterbox/normalización
│   ├── PostprocessingException     # Error en NMS/conversión
│   └── InferenceTimeoutException   # Inferencia muy lenta
│
├── ImageException
│   ├── ImageDecodeException        # Formato no soportado
│   ├── ImageDimensionsException    # Imagen muy pequeña
│   └── ImageFileException          # Archivo no existe
│
├── DetectionException
│   ├── InvalidBoundingBoxException # Coordenadas inválidas
│   ├── InvalidConfidenceException  # Confianza fuera de rango
│   └── InvalidClassIdException     # ClassId negativo
│
├── PermissionException
│   ├── CameraPermissionException   # Permiso cámara denegado
│   └── GalleryPermissionException  # Permiso galería denegado
│
├── DatabaseException
│   └── IngredientNotFoundException # Ingrediente no en BD
│
├── CameraInitializationException   # Error inicializando cámara
├── CameraStreamException           # Error en streaming
├── FrameConversionException        # Error conversión YUV→RGB
├── NoCameraAvailableException      # Sin cámaras disponibles
└── NutriVisionGenericException     # Errores no categorizados
```

### Uso de Excepciones

```dart
try {
  await detector.detect(image);
} on ModelNotInitializedException catch (e) {
  // Mostrar mensaje: "El detector no está listo"
  print(e.userMessage);
} on ImageDecodeException catch (e) {
  // Mostrar mensaje: "No se pudo leer la imagen"
  print(e.userMessage);
} on NutriVisionException catch (e) {
  // Cualquier otra excepción de la app
  ExceptionHandler.logError(e);
  print(e.userMessage);
}
```

### ExceptionHandler

```dart
/// Utilidades para manejo centralizado de excepciones
class ExceptionHandler {
  /// Envuelve cualquier error en NutriVisionException
  static NutriVisionException wrap(Object error, [StackTrace? stackTrace]);
  
  /// Obtiene mensaje amigable para el usuario
  static String getUserMessage(Object error);
  
  /// Registra error para debugging (solo en debug mode)
  static void logError(Object error, [StackTrace? stackTrace]) {
    assert(() {
      debugPrint('🔴 ERROR: $error');
      if (stackTrace != null) {
        debugPrint('📍 Stack trace: $stackTrace');
      }
      return true;
    }());
  }
}
```

---

## 📱 Permisos de Cámara y Galería

### android/app/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- ═══════════════════════════════════════════════════════════ -->
    <!-- PERMISOS                                                     -->
    <!-- ═══════════════════════════════════════════════════════════ -->
    
    <!-- Cámara -->
    <uses-permission android:name="android.permission.CAMERA"/>
    
    <!-- Almacenamiento (Android 12 y anterior) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="29" />
    
    <!-- Almacenamiento granular (Android 13+) -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    
    <!-- ═══════════════════════════════════════════════════════════ -->
    <!-- FEATURES                                                     -->
    <!-- ═══════════════════════════════════════════════════════════ -->
    
    <!-- Cámara como feature opcional (permite instalación en tablets sin cámara) -->
    <uses-feature android:name="android.hardware.camera" android:required="false"/>
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false"/>
    
    <application
        android:label="NutriVision AI"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:enableOnBackInvokedCallback="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"/>
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    
    <!-- Permitir consultas a otras apps (Android 11+) -->
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
    </queries>
    
</manifest>
```

---

## 🏗️ Arquitectura de la Aplicación

### Pantalla de Detección (GalleryDetectionPage)

Características implementadas:

| Feature | Descripción |
|---------|-------------|
| **Carga de modelo** | Inicialización asíncrona con feedback visual |
| **Selección de imagen** | ImagePicker para galería |
| **Bounding boxes** | Renderizado correcto con escalado proporcional |
| **Filtrado por ingrediente** | Toca un ingrediente para ver solo sus detecciones |
| **Indicador de filtro** | Chip visual mostrando filtro activo |
| **Lista de ingredientes** | Cards con conteo y confianza promedio |
| **Manejo de errores** | Dialogs con detalles técnicos usando excepciones |
| **Debug logging** | Coordenadas visibles en consola |

### BoundingBoxPainter

```dart
/// Dibuja bounding boxes sobre la imagen detectada.
/// 
/// Características:
/// - Escalado automático imagen→widget
/// - Colores por nivel de confianza (verde/naranja/rojo)
/// - Color especial azul para ingrediente filtrado
/// - Labels con fondo semi-transparente
/// - Posicionamiento inteligente de labels
/// - Usa withAlpha() en lugar de withOpacity() (lint fix)
class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final int imageWidth;
  final int imageHeight;
  final String? highlightLabel;
  
  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;
    
    for (final detection in detections) {
      // Color según confianza o filtro
      final Color boxColor = detection.label == highlightLabel
          ? Colors.blue
          : detection.isHighConfidence
              ? Colors.green
              : detection.isMediumConfidence
                  ? Colors.orange
                  : Colors.red;
      
      // Usar withAlpha en lugar de withOpacity (deprecated)
      strokePaint.color = boxColor.withAlpha((opacity * 255).round());
      fillPaint.color = boxColor.withAlpha((0.15 * opacity * 255).round());
      
      // ... dibujar bounding box
    }
  }
}
```

---

## 🧪 Testing

### Resumen de Tests (445 tests)

| Grupo | Tests | Estado | Archivo |
|-------|-------|--------|---------|
| Logging | 39 | ✅ | app_logger_test.dart |
| Security (InputValidator) | 133 | ✅ | input_validator_test.dart |
| Auth State | 33 | ✅ | auth_state_test.dart |
| Camera Settings | 23 | ✅ | camera_settings_test.dart |
| Ingredient Quantity | 45 | ✅ | ingredient_quantity_test.dart |
| Nutrition Models | 56 | ✅ | nutrition_test.dart |
| User Profile | 38 | ✅ | user_profile_test.dart |
| Quantities Notifier | 115 | ✅ | ingredient_quantities_notifier_test.dart |
| YOLO Detector | 7 | ✅ | yolo_detector_test.dart |
| **TOTAL** | **445** | ✅ | 9 archivos |

### Estadísticas del Proyecto

| Métrica | Valor |
|---------|-------|
| Archivos Dart en lib/ | 81 |
| Líneas de código producción | ~26,105 |
| Líneas de código tests | ~4,814 |
| Total de tests | **445** |
| Archivos de test | 9 |
| Ingredientes soportados | 83 |
| Platos soportados | 6 |
| Porciones estándar | 83 ingredientes × ~4 porciones c/u |
| Cobertura de tests | ~94% |

### Ejecutar Tests

```powershell
# Ejecutar todos los tests
flutter test

# Ejecutar solo tests del detector
flutter test test/ml/yolo_detector_test.dart

# Ejecutar con verbose output
flutter test --reporter expanded

# Ejecutar un test específico
flutter test --name "Detectar sin inicializar"
```

### Verificar Código

```powershell
# Analizar código (linting)
flutter analyze

# Resultado esperado:
# Analyzing nutrivision_aiepn_mobile...
# No issues found!
```

### Tests de Excepciones

```dart
test('Detectar sin inicializar lanza ModelNotInitializedException', () async {
  expect(
    () async => await testDetector.detect(dummyImage),
    throwsA(isA<ModelNotInitializedException>()),
  );
});

test('Detectar después de dispose lanza ModelDisposedException', () async {
  final testDetector = YoloDetector();
  await testDetector.initialize();
  testDetector.dispose();
  
  expect(
    () async => await testDetector.detect(dummyImage),
    throwsA(isA<ModelDisposedException>()),
  );
});

test('Constructor lanza InvalidBoundingBoxException si x2 <= x1', () {
  expect(
    () => Detection(x1: 100, y1: 0, x2: 50, y2: 100, ...),
    throwsA(isA<InvalidBoundingBoxException>()),
  );
});

test('ExceptionHandler.wrap envuelve excepciones genéricas', () {
  final wrapped = ExceptionHandler.wrap(Exception('Generic'));
  expect(wrapped, isA<NutriVisionGenericException>());
});
```

### Pantalla de Pruebas Manuales

La pantalla `GalleryDetectionPage` permite:

- 📷 Seleccionar imagen desde galería
- 🔍 Ejecutar detección YOLO
- 📊 Ver resultados con bounding boxes correctamente posicionados
- 🔎 Filtrar por ingrediente (toca para filtrar)
- ⏱️ Medir tiempo de inferencia
- 📋 Ver estadísticas de detección

---

## 🔧 Comandos Útiles

### Desarrollo diario

```powershell
# Obtener/actualizar dependencias
flutter pub get

# Ejecutar en modo debug (dispositivo conectado)
flutter run

# Ejecutar con hot reload en dispositivo específico
flutter run -d <device_id>

# Ver dispositivos disponibles
flutter devices

# Limpiar build cache
flutter clean

# Analizar código (linting)
flutter analyze

# Ejecutar tests
flutter test

# Generar código (Riverpod, etc.)
dart run build_runner build --delete-conflicting-outputs
```

### Debugging

```powershell
# Logs del dispositivo
flutter logs

# Ejecutar con verbose output
flutter run -v

# Abrir DevTools (profiler, inspector)
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 📲 Generación de Builds

### Build de Debug (desarrollo)

```powershell
# APK debug (más rápido, con símbolos)
flutter build apk --debug

# Instalar directamente en dispositivo
flutter install
```

### Build de Release (producción)

#### Paso 1: Generar keystore (solo primera vez)

```powershell
keytool -genkey -v -keystore %USERPROFILE%\nutrivision-release-key.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias nutrivision
```

#### Paso 2: Crear archivo key.properties

Crear `android/key.properties`:

```properties
storePassword=tu_password_aqui
keyPassword=tu_password_aqui
keyAlias=nutrivision
storeFile=C:\\Users\\TU_USUARIO\\nutrivision-release-key.jks
```

⚠️ **IMPORTANTE:** Agregar `key.properties` a `.gitignore` para no subir credenciales.

#### Paso 3: Build APK Release

```powershell
# APK universal (más grande, compatible con todo)
flutter build apk --release

# APKs separados por arquitectura (recomendado para distribución directa)
flutter build apk --split-per-abi --release

# Output:
#   build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk  (~15 MB)
#   build/app/outputs/flutter-apk/app-arm64-v8a-release.apk    (~16 MB)
```

#### Paso 4: Build App Bundle (para Play Store)

```powershell
# App Bundle con ofuscación
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

# Output: build/app/outputs/bundle/release/app-release.aab
```

### Tabla resumen de builds

| Tipo | Comando | Uso |
|------|---------|-----|
| Debug APK | `flutter build apk --debug` | Desarrollo y testing |
| Release APK | `flutter build apk --release` | Distribución directa |
| Split APKs | `flutter build apk --split-per-abi --release` | APKs más pequeños |
| App Bundle | `flutter build appbundle --release` | Google Play Store |

---

## 🗺️ Roadmap de Desarrollo

### ═══════════════════════════════════════════════════════════════
### FASES COMPLETADAS
### ═══════════════════════════════════════════════════════════════

### Fase 1: Setup Inicial ✅ (100%)
- [x] Crear proyecto Flutter
- [x] Configurar estructura de carpetas
- [x] Agregar dependencias en pubspec.yaml
- [x] Configurar Android (permisos, gradle)
- [x] Copiar modelo TFLite y labels

### Fase 2: ML Core ✅ (100%)
- [x] Implementar `YoloDetector`
- [x] Implementar preprocesamiento (letterbox)
- [x] Implementar desnormalización de coordenadas (0-1 → 0-640)
- [x] Implementar postprocesamiento (NMS por clase)
- [x] Probar inferencia con imagen estática
- [x] Crear modelo `Detection` con métodos auxiliares y validaciones
- [x] Implementar pantalla de detección desde galería
- [x] Implementar `BoundingBoxPainter` con escalado correcto
- [x] Implementar filtrado por ingrediente

### Fase 3: Sistema de Excepciones ✅ (100%)
- [x] Crear jerarquía de excepciones personalizadas
- [x] Implementar `ExceptionHandler` para manejo centralizado
- [x] Integrar excepciones en `YoloDetector`
- [x] Integrar excepciones en `Detection`
- [x] Agregar validaciones en constructores

### Fase 4: Testing ✅ (100%)
- [x] Crear estructura de tests automatizados
- [x] Implementar 445 tests unitarios
- [x] Tests de YoloDetector (inicialización, detección, consistencia)
- [x] Tests de Detection (propiedades, validaciones, serialización)
- [x] Tests de excepciones personalizadas
- [x] Tests de logging (39 tests)
- [x] Tests de security/InputValidator (133 tests)
- [x] Tests de modelos (Auth, Camera, Nutrition, Profile, Quantities)
- [x] Tests con 54 imágenes de Kaggle
- [x] Tests de rendimiento (< 600ms inferencia)

### Fase 5: Cámara en Tiempo Real ✅ (85%)
- [x] Implementar captura desde galería (ImagePicker)
- [x] Implementar preview de cámara en tiempo real
- [x] Integrar detección con streaming de cámara
- [x] Dibujar bounding boxes en overlay
- [x] Conversión YUV420 → RGB optimizada
- [x] Throttling de frames para rendimiento
- [x] Controles de cámara (flash, cambiar cámara)
- [x] Código nativo C++ con NEON SIMD (~10x más rápido)
- [x] Worker Isolate para no bloquear UI
- [ ] Optimización adicional de FPS

### Fase 6: UI/UX Inicial ✅ (80%)
- [x] Crear sistema de tema (AppTheme, AppColors)
- [x] Crear constantes globales (AppConstants)
- [x] Configurar navegación con go_router
- [x] Diseñar pantalla principal (HomePage)
- [x] Agregar animaciones y transiciones

### Fase 7: Refactorización ✅ (100%)
- [x] Migrar a arquitectura Feature-First
- [x] Reorganizar carpetas lib/
- [x] Actualizar imports
- [x] Verificar 445 tests pasando

### ═══════════════════════════════════════════════════════════════
### PLAN DE EVOLUCIÓN - FASES PENDIENTES
### ═══════════════════════════════════════════════════════════════

### FASE 0: Verificación Inicial ✅
- [x] Ejecutar `flutter clean`
- [x] Ejecutar `flutter pub get`
- [x] Ejecutar `flutter analyze` → 0 issues
- [x] Ejecutar `flutter test` → 445 tests pasando

### FASE 1: Crear Estructura de Carpetas ✅
| Carpeta | Estado | Descripción |
|---------|--------|-------------|
| `lib/core/logging/` | ✅ | Sistema de logging centralizado |
| `lib/core/session/` | ✅ | Gestión de sesión de usuario |
| `lib/data/defaults/` | ✅ | Datos fallback de nutrientes |
| `lib/features/auth/` | ✅ | Autenticación (demo) |
| `lib/features/onboarding/` | ✅ | Splash y welcome screens |
| `lib/features/profile/` | ✅ | Pantalla de perfil |
| `lib/features/home/viewmodels/` | ✅ | ViewModels de home |
| `lib/features/home/widgets/` | ✅ | Widgets reutilizables |
| `lib/shared/widgets/` | ✅ | Componentes compartidos |

### FASE 2: Sistema de Logging ✅
- [x] Crear `lib/core/logging/log_level.dart` - Enum de niveles
- [x] Crear `lib/core/logging/log_config.dart` - Configuración
- [x] Crear `lib/core/logging/app_logger.dart` - Logger principal
- [ ] Crear `lib/core/logging/log_persistence.dart` - Persistencia (opcional)
- [x] Tests para logging (17 tests)
- [x] Verificar: `flutter analyze` y `flutter test`

### FASE 3: Modelos de Datos ✅
- [x] Crear `lib/data/models/nutrients_per_100g.dart` - Nutrientes por 100g
- [x] Crear `lib/data/models/nutrition_info.dart` - Información nutricional
- [x] Crear `lib/data/models/nutrition_data.dart` - Contenedor de datos
- [x] Tests para modelos de nutrición (33 tests)
- [x] Verificar: `flutter analyze` y `flutter test`

### FASE 4: Base de Datos Nutricional ✅
- [x] Crear `lib/data/datasources/nutrition_datasource.dart` - Carga JSON
- [x] Crear `lib/data/repositories/nutrition_repository.dart` - Repositorio con cache
- [x] Crear `lib/features/nutrition/services/nutrition_service.dart` - Servicio singleton
- [x] Crear `lib/features/nutrition/providers/nutrition_provider.dart` - Providers Riverpod
- [x] Crear `assets/data/nutrition_fdc.json` - Datos USDA (80 ingredientes, 6 platos)
- [x] Widgets UI: nutrient_bar, nutrition_card, nutrition_summary
- [x] Integración con detection_gallery_screen
- [x] Verificar: `flutter analyze` y `flutter test` → 445 tests pasando

### FASE 5: Firebase Auth, Onboarding y Profile ✅ (100%)
#### 5.1 Onboarding
- [x] Crear `lib/features/onboarding/views/splash_screen.dart`
- [x] Crear `lib/features/onboarding/views/welcome_screen.dart`
- [x] Agregar rutas en `routes.dart`

#### 5.2 Auth (Firebase)
- [x] Crear `lib/features/auth/services/firebase_auth_service.dart`
- [x] Crear `lib/features/auth/services/firestore_user_service.dart`
- [x] Crear `lib/features/auth/repositories/auth_repository.dart`
- [x] Crear `lib/features/auth/providers/auth_provider.dart`
- [x] Crear `lib/features/auth/views/login_screen.dart`
- [x] Crear `lib/features/auth/views/register_screen.dart`
- [x] Crear `lib/features/auth/views/profile_setup_screen.dart`
- [x] Agregar rutas en `routes.dart`

#### 5.3 Profile
- [x] Crear `lib/features/profile/views/profile_screen.dart`
- [x] Crear `lib/features/profile/views/edit_profile_screen.dart`
- [x] Agregar rutas en `routes.dart`

#### 5.4 Session Manager
- [x] Crear `lib/core/session/session_manager.dart` - Gestión de sesión
- [x] Integrar en `routes.dart` (navegación condicional basada en auth)

#### 5.5 Seguridad
- [x] Crear `lib/core/security/input_validator.dart` - Validación de inputs

#### 5.6 Modelos de Auth
- [x] Crear `lib/data/models/user_profile.dart`
- [x] Crear `lib/data/models/auth_state.dart`

### FASE 6A: Sistema de Cantidades - Modelos y Repositorios ✅ (100%)
- [x] Crear `lib/data/models/quantity_enums.dart` - Enums QuantityUnit y QuantitySource
- [x] Crear `lib/data/models/standard_portion.dart` - Modelo de porciones estandar
- [x] Crear `lib/data/models/ingredient_quantity.dart` - Modelo de cantidad de ingrediente
- [x] Crear `lib/data/datasources/portion_datasource.dart` - Datasource para porciones
- [x] Crear `lib/data/repositories/portion_repository.dart` - Repositorio con cache
- [x] Crear `assets/data/standard_portions.json` - Base de datos de porciones (83 ingredientes)
- [x] Agregar metodo `calculateTotalNutrientsWithQuantities()` en NutritionRepository
- [x] Verificar: `flutter analyze` y `flutter test`

**Archivos creados:**
- `lib/data/models/quantity_enums.dart` (54 líneas)
- `lib/data/models/standard_portion.dart` (129 líneas)
- `lib/data/models/ingredient_quantity.dart` (268 líneas)
- `lib/data/datasources/portion_datasource.dart` (110 líneas)
- `lib/data/repositories/portion_repository.dart` (264 líneas)
- `assets/data/standard_portions.json` (83 ingredientes)

**Modificado:**
- `lib/data/repositories/nutrition_repository.dart` - Agregado método `calculateTotalNutrientsWithQuantities()` (líneas 164-181)

**Verificación:**
- `flutter analyze`: 0 issues
- `flutter test`: 445 tests pasando
- `flutter build apk --release`: Exitoso

### FASE 6B: Sistema de Cantidades - Providers y State ✅ (100%)
- [x] Crear `lib/features/nutrition/state/ingredient_quantities_notifier.dart` (323 líneas)
- [x] Crear `lib/features/nutrition/providers/quantity_provider.dart` (providers Riverpod)
- [x] Estado reactivo con AsyncNotifierProvider
- [x] 115 tests unitarios pasando
- [x] Integración completa con nutrition_provider
- [x] Verificar: `flutter analyze` (0 issues) y `flutter test` (445 tests pasando)

### FASE 6C: Sistema de Cantidades - UI Widgets ✅ (100%)
- [x] **Implementado:** `lib/features/nutrition/widgets/quantity_adjustment_dialog.dart` (346 líneas)
  - Widget unificado que combina funcionalidad de quantity_selector, portion_picker y grams_input
  - Diálogo modal con header gradient verde
  - Input manual de gramos con validación (10-5000g)
  - Selector de porciones estándar con FilterChips
  - Integración con `ingredientQuantitiesProvider` (Riverpod)
  - Usa `GradientButton` del sistema compartido
- [x] Verificado: `flutter analyze` (0 issues), `flutter test` (445 tests passing)

**Diseño implementado:**
- Header con gradiente LinearGradient (verde #4CAF50 → #2E7D32)
- TextField para input manual con InputFormatters (solo dígitos)
- Wrap de FilterChips para porciones estándar
- Botones: OutlinedButton (Cancelar) + GradientButton (Guardar)
- Validación en tiempo real con SnackBar de error

### FASE 6D: Integracion con Deteccion 🚧 (80%)
- [x] **Completado:** Integrar `QuantityAdjustmentDialog` en:
  - `lib/features/detection/views/detection_gallery_screen.dart` (línea 22: import)
  - `lib/features/detection/views/detection_results_screen.dart`
  - Dialog se abre al hacer tap en ingrediente detectado
- [x] **Completado:** Método `calculateTotalNutrientsWithQuantities()` en `NutritionRepository`
- [x] **Completado:** Provider `totalNutrientsWithQuantitiesProvider` en `quantity_provider.dart`
- [ ] **PENDIENTE (20%):** Conectar UI con provider de cantidades dinámicas
  - Actualmente usa `totalNutrientsProvider` (asume 100g por ingrediente)
  - Debe cambiar a `totalNutrientsWithQuantitiesProvider` (usa cantidades ajustadas)
  - Afecta: `NutritionCard` debe reaccionar a cambios en `ingredientQuantitiesProvider`
- [ ] **PENDIENTE:** Tests de integración para flujo completo (detección → ajuste → cálculo)

**Siguiente paso crítico:**
```dart
// En detection_gallery_screen.dart y detection_results_screen.dart
// ❌ ACTUAL (asume 100g):
final nutrientsAsync = ref.watch(totalNutrientsProvider(detectedLabels));

// ✅ DESEADO (usa cantidades ajustadas):
final nutrientsAsync = ref.watch(totalNutrientsWithQuantitiesProvider);
```

### FASE 6E: Widgets Compartidos ⏳
- [ ] Crear `lib/shared/widgets/gradient_app_bar.dart`
- [ ] Crear `lib/shared/widgets/macro_card.dart`
- [ ] Crear `lib/features/home/widgets/action_button.dart`
- [ ] Crear `lib/features/home/widgets/hero_card.dart`
- [ ] Crear `lib/features/home/viewmodels/home_viewmodel.dart`
- [ ] Verificar: `flutter analyze` y `flutter test`

### FASE 7: Renombrado de Servicios ⚠️ (AL FINAL)
> **IMPORTANTE:** Esta fase solo debe ejecutarse cuando todo lo anterior esté funcionando.

- [ ] Renombrar `yolo_detector.dart` → `yolo_service.dart`
- [ ] Renombrar clase `YoloDetector` → `YoloService`
- [ ] Renombrar `camera_frame_processor.dart` → `detection_service.dart`
- [ ] Renombrar clase `CameraFrameProcessor` → `DetectionService`
- [ ] Renombrar `ProcessingResult` → `DetectionResult`
- [ ] Actualizar todos los imports
- [ ] Actualizar providers
- [ ] Verificar: `flutter analyze` y `flutter test`
- [ ] Test manual: detección en cámara y galería

### ═══════════════════════════════════════════════════════════════
### ORDEN DE IMPLEMENTACIÓN RECOMENDADO
### ═══════════════════════════════════════════════════════════════

```
FASE 0 (Verificación)     ✅ COMPLETADO
       ↓
FASE 1 (Carpetas)         ✅ COMPLETADO
       ↓
FASE 2 (Logging)          ✅ COMPLETADO (17 tests nuevos)
       ↓
FASE 3 (Modelos)          ✅ COMPLETADO (33 tests nuevos)
       ↓
FASE 4 (Base de datos)    ✅ COMPLETADO (sistema nutricional completo)
       ↓
FASE 5 (Auth/Onboarding)  ✅ COMPLETADO (Firebase Auth + Profile + Session)
       ↓
FASE 6A (Cantidades)      ✅ COMPLETADO (Modelos y Repositorios)
       ↓
FASE 6B (Providers)       ✅ COMPLETADO (State management - 115 tests)
       ↓
FASE 6C (UI Widgets)      ← SIGUIENTE PASO - Selector de cantidades y porciones
       ↓
FASE 6D (Integracion)     ⏳ Conectar con deteccion
       ↓
FASE 6E (Widgets)         ⏳ Componentes compartidos
       ↓
FASE 7 (Renombrar)        ← SOLO AL FINAL, cuando todo funcione
```

### ═══════════════════════════════════════════════════════════════
### ARCHIVOS CRÍTICOS - NO MODIFICAR HASTA FASE 8
### ═══════════════════════════════════════════════════════════════

```
lib/core/
├── utils/
│   └── runtime_mode.dart        ← Detección de entorno (debug/profile/release)
└── security/
    └── input_validator.dart     ← Validación de inputs (133 tests)

lib/data/models/
├── performance_metrics.dart     ← ✅ NEW: Métricas de rendimiento detección
├── quantity_enums.dart          ← FASE 6A: Enums QuantityUnit y QuantitySource
├── standard_portion.dart        ← FASE 6A: Modelo de porciones estandar
└── ingredient_quantity.dart     ← FASE 6A: Modelo de cantidad de ingrediente

lib/data/datasources/
└── portion_datasource.dart      ← Carga de porciones desde JSON

lib/data/repositories/
└── portion_repository.dart      ← Repositorio con cache de porciones

lib/features/detection/services/
├── yolo_detector.dart            ← 467 líneas, motor ML
├── camera_frame_processor.dart   ← 354 líneas, orquestación
├── image_processing_isolate.dart ← 148 líneas, isolate
├── native_image_processor.dart   ← 97 líneas, C++ bridge
├── detection_controller.dart     ← ✅ NEW: Controlador centralizado detección
└── detection_debug_helper.dart   ← ✅ NEW: Helper para debugging

lib/features/nutrition/state/
└── ingredient_quantities_notifier.dart ← ✅ NEW: State manager cantidades (115 tests)

lib/shared/widgets/
├── runtime_mode_indicator.dart  ← ✅ NEW: Indicador visual modo runtime
├── animated_counter.dart        ← ✅ NEW: Contador animado para nutrientes
├── feedback_widgets.dart        ← ✅ NEW: Widgets de feedback (snackbars, toasts)
├── info_card.dart               ← ✅ NEW: Card de información genérico
└── loading_overlay.dart         ← ✅ NEW: Overlay de carga

assets/data/
└── standard_portions.json       ← Base de datos de porciones (83 ingredientes)

android/app/src/main/cpp/
├── native_image_processor.cpp   ← 287 líneas, NEON
├── yuv_to_rgb.h                 ← 87 líneas, headers
└── CMakeLists.txt               ← Config build
```

### ═══════════════════════════════════════════════════════════════
### TABLA DE PROGRESO GLOBAL
### ═══════════════════════════════════════════════════════════════

| Fase | Estado | Progreso |
|------|--------|----------|
| Fase 0 | Completada | 100% |
| Fase 1 | Completada | 100% |
| Fase 2 | Completada | 100% |
| Fase 3 | Completada | 100% |
| Fase 4 | Completada | 100% |
| Fase 5 | Completada | 100% |
| Fase 6A | Completada | 100% |
| **Fase 6B** | **Completada** | **100%** |
| Fase 6C | Pendiente | 0% |
| Fase 6D | Pendiente | 0% |
| Fase 6E | Pendiente | 0% |
| Fase 6F | Pendiente | 0% |
| Fase 7 | Diferida | 0% |

### ═══════════════════════════════════════════════════════════════
### PRÓXIMOS PASOS (FASE 6C - UI Widgets)
### ═══════════════════════════════════════════════════════════════

**Objetivo:** Implementar widgets de UI para el sistema de cantidades

**Archivos a crear:**
- `lib/features/nutrition/widgets/quantity_selector.dart`
- `lib/features/nutrition/widgets/portion_picker.dart`
- `lib/features/nutrition/widgets/grams_input.dart`

**Archivos ya creados (reutilizar):**
- `lib/features/nutrition/widgets/quantity_adjustment_dialog.dart` ✅

**Duración estimada:** 1-2 días

### Fases Finales (Post-Evolución)

### Fase 9: Features Adicionales (Después de FASE 8)
- [ ] Historial de análisis
- [ ] Compartir resultados
- [ ] Configuraciones de usuario
- [ ] Optimización de rendimiento

### Fase 10: Release (Final)
- [ ] Tests de integración
- [ ] Pruebas en múltiples dispositivos
- [ ] Generar build de release
- [ ] Documentación final

---

## 🔥 Solución de Problemas Comunes

### Error: "Gradle build failed"

```powershell
# Limpiar y reconstruir
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

### Error: "TFLite model not found"

1. Verificar que el archivo existe en `assets/models/yolov11n_float32.tflite`
2. Verificar que está registrado en `pubspec.yaml`
3. Ejecutar `flutter clean && flutter pub get`

### Error: "ModelNotInitializedException"

Asegúrate de llamar `await detector.initialize()` antes de usar `detect()`:

```dart
final detector = YoloDetector();
await detector.initialize();  // ← Necesario antes de detectar
final results = await detector.detect(image);
```

### Error: Bounding boxes en esquina superior izquierda (0,0)

**Problema:** El modelo devuelve coordenadas normalizadas (0-1), no píxeles.

**Solución:** Ya implementada en `yolo_detector.dart`:
```dart
// Desnormalizar coordenadas
final double cx = output[0][0][i] * inputSize; // 0.596 * 640 = 381
final double cy = output[0][1][i] * inputSize;
final double w = output[0][2][i] * inputSize;
final double h = output[0][3][i] * inputSize;
```

### Error: "Camera permission denied"

```dart
// Verificar en código que los permisos estén otorgados
final status = await Permission.camera.request();
if (status.isPermanentlyDenied) {
  openAppSettings(); // Abrir configuración del sistema
}
```

### Error: "Out of memory during inference"

1. Reducir resolución de cámara:
```dart
CameraController(camera, ResolutionPreset.medium) // No usar 'high' o 'max'
```

2. Procesar frames alternos:
```dart
int frameCount = 0;
onCameraFrame((image) {
  if (frameCount++ % 3 != 0) return; // Procesar cada 3 frames
  // ... detección
});
```

### Warning: "source value 8 is obsolete"

Actualizar en `android/app/build.gradle`:
```groovy
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}
kotlinOptions {
    jvmTarget = "17"
}
```

### Warning: "withOpacity is deprecated"

Usar `withAlpha` en lugar de `withOpacity`:
```dart
// ANTES (deprecated)
color.withOpacity(0.5)

// DESPUÉS
color.withAlpha((0.5 * 255).round())
```

### Warning: "avoid_print"

Usar `debugPrint` dentro de `assert()`:
```dart
// ANTES
print('Error: $error');

// DESPUÉS
assert(() {
  debugPrint('Error: $error');
  return true;
}());
```

### Build lento en Windows

```powershell
# Usar modo profile para builds más rápidos durante desarrollo
flutter run --profile

# Deshabilitar análisis durante build
flutter build apk --no-tree-shake-icons
```

---

## 📚 Referencias y Recursos

### Documentación Oficial

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language](https://dart.dev/guides)
- [TensorFlow Lite Flutter](https://pub.dev/packages/tflite_flutter)
- [Ultralytics YOLO](https://docs.ultralytics.com/)

### Paquetes Utilizados

| Paquete | Documentación |
|---------|---------------|
| tflite_flutter | [pub.dev/packages/tflite_flutter](https://pub.dev/packages/tflite_flutter) |
| camera | [pub.dev/packages/camera](https://pub.dev/packages/camera) |
| image_picker | [pub.dev/packages/image_picker](https://pub.dev/packages/image_picker) |
| image | [pub.dev/packages/image](https://pub.dev/packages/image) |
| permission_handler | [pub.dev/packages/permission_handler](https://pub.dev/packages/permission_handler) |
| flutter_riverpod | [pub.dev/packages/flutter_riverpod](https://pub.dev/packages/flutter_riverpod) |
| sqflite | [pub.dev/packages/sqflite](https://pub.dev/packages/sqflite) |

### Recursos del Proyecto

- **Notebook de Kaggle:** Entrenamiento YOLO11n
- **Dataset:** NutriVisionAIEPN (Roboflow)
- **Modelo:** `yolov11n_float32.tflite` (10.27 MB)
- **Output Format:** [1, 87, 8400] con coordenadas normalizadas 0-1

---

## 🚀 Performance Testing

### Objetivo

Medir y validar el rendimiento del sistema de detección YOLO11n on-device para asegurar que cumple con thresholds específicos en dispositivos reales.

### Métricas Rastreadas

El proyecto utiliza `PerformanceMetrics` (`lib/data/models/performance_metrics.dart`) para rastrear:

| Métrica | Descripción | Threshold |
|---------|-------------|-----------|
| **Carga del modelo** | Tiempo de `Interpreter.fromAsset()` | < 2000ms |
| **Conversión YUV→RGB (C++ NEON)** | Transformación nativa ARM SIMD | < 50ms |
| **Conversión YUV→RGB (Dart isolate)** | Fallback en Dart puro | < 150ms |
| **Preprocesamiento** | Resize + letterbox + normalización | < 20ms |
| **Inferencia (CPU XNNPack)** | `interpreter.run()` en CPU | < 300ms |
| **Inferencia (GPU delegate)** | `interpreter.run()` en GPU | < 100ms |
| **Postprocesamiento + NMS** | Parsing output + filtrado | < 50ms |
| **Total por frame** | Pipeline completo | < 500ms |
| **FPS (Live detection)** | Frames/segundo en cámara | > 10 FPS |
| **Memory footprint** | Uso total de RAM | < 150 MB |

### Instrumentación Existente

#### YoloDetector (Código de Producción)

El detector YA captura métricas detalladas usando `Stopwatch`:

**Ubicación:** `lib/features/detection/services/yolo_detector.dart` (líneas 403-436)

```dart
final stopwatchPreprocess = Stopwatch()..start();
// ... preprocesamiento ...
stopwatchPreprocess.stop();

final stopwatchRun = Stopwatch()..start();
_interpreter!.run(inputTensor, outputTensor);
stopwatchRun.stop();

final stopwatchPostprocess = Stopwatch()..start();
// ... postprocesamiento + NMS ...
stopwatchPostprocess.stop();

AppLogger.debug(
  'Preprocess: ${stopwatchPreprocess.elapsedMilliseconds}ms',
  'Inference: ${stopwatchRun.elapsedMilliseconds}ms',
  'Postprocess: ${stopwatchPostprocess.elapsedMilliseconds}ms',
);
```

#### PerformanceMetrics Model

**Ubicación:** `lib/data/models/performance_metrics.dart` (160 líneas)

```dart
@immutable
class PerformanceMetrics {
  final int frameNumber;
  final int totalMs;
  final int conversionMs;
  final int preprocessMs;
  final int inferenceMs;
  final int postprocessMs;
  final int detectionCount;
  final DateTime timestamp;

  double get fps => totalMs > 0 ? 1000 / totalMs : 0;
  double get inferencePercent => ...;
}
```

### Integration Tests

#### Configuración

**1. Dependencia agregada en `pubspec.yaml`:**

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

**2. Estructura creada:**

```
integration_test/
├── performance_test.dart       # 8 tests de performance
└── README.md                   # Guía de ejecución
```

#### Comandos de Ejecución

```bash
# Ejecutar en dispositivo real (recomendado)
flutter test integration_test/performance_test.dart

# Con profiling habilitado
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/performance_test.dart \
  --profile
```

#### Tests Implementados

| Test | Descripción | Threshold | Líneas |
|------|-------------|-----------|--------|
| **TEST 1** | Carga de modelo | < 2000ms | 130-165 |
| **TEST 2** | Inferencia CPU | < 300ms | 170-200 |
| **TEST 3** | Preprocesamiento | < 20ms | 205-230 |
| **TEST 4** | Postprocesamiento | Cualitativo | 235-255 |
| **TEST 5** | Pipeline completo | < 500ms | 260-290 |
| **TEST 6** | FPS (10 frames) | > 10 FPS | 295-330 |
| **TEST 7** | Memory usage | < 150 MB | 335-360 |
| **TEST 8** | Estabilidad (50 frames) | Sin outliers | 365-420 |

**Ejemplo de test:**

```dart
testWidgets('TEST 2: Inference time (CPU) < threshold', (tester) async {
  await detector.initialize();

  final stopwatch = Stopwatch()..start();
  final detections = await detector.detectFromImage(testImage);
  stopwatch.stop();

  final inferenceMs = stopwatch.elapsedMilliseconds;
  final threshold = thresholds['inferenceMs']!; // 300ms

  expect(inferenceMs, lessThan(threshold),
    reason: 'Inference should complete in < ${threshold}ms');
});
```

### Herramientas de Profiling

#### 1. Flutter DevTools (Oficial, Gratuito)

**Comando:**
```bash
flutter run --profile
flutter pub global run devtools
# URL: http://127.0.0.1:9100
```

**Funcionalidades:**
- **Performance tab:** Timeline de eventos Flutter
- **CPU profiler:** Flame chart de ejecución Dart
- **Memory profiler:** Heap snapshots y detección de leaks
- **Network profiler:** Requests de Firebase

**Métricas a revisar:**
- Frame rendering time (< 16ms para 60 FPS)
- Hotspots en CPU (funciones lentas)
- Memory leaks (objetos retenidos)
- GPU/CPU/Raster timeline

#### 2. Android Profiler (Android Studio, Gratuito)

**Comando:**
```bash
# En Android Studio:
# Run > Profile 'app' (Shift+F9)
# View > Tool Windows > Profiler
```

**Funcionalidades:**
- **CPU profiler:** Traces nativos de C++ (yuv_to_rgb.cpp)
- **GPU profiler:** Render stages de overlay
- **Memory profiler:** Native heap + Dart heap
- **Energy profiler:** Consumo de batería

**Métricas clave:**
- Verificar que conversión YUV→RGB usa C++ NEON (traces nativos)
- Render time para bounding boxes overlay
- Memory total < 150 MB (filtrar por package)
- CPU usage < 15% en idle

#### 3. TFLite Benchmark Tool (TensorFlow Oficial)

**Propósito:** Comparar rendimiento de delegates (CPU/GPU/NNAPI).

**Instalación:**
```bash
git clone https://github.com/tensorflow/tensorflow.git
cd tensorflow/tensorflow/lite/tools/benchmark

bazel build -c opt \
  --config=android_arm64 \
  tensorflow/lite/tools/benchmark:benchmark_model
```

**Uso con yolov11n_float32.tflite:**

```bash
# Push modelo al dispositivo
adb push assets/models/yolov11n_float32.tflite /data/local/tmp/

# Benchmark CPU (XNNPack)
adb shell /data/local/tmp/benchmark_model \
  --graph=/data/local/tmp/yolov11n_float32.tflite \
  --num_threads=4 \
  --use_xnnpack=true

# Benchmark GPU delegate
adb shell /data/local/tmp/benchmark_model \
  --graph=/data/local/tmp/yolov11n_float32.tflite \
  --use_gpu=true

# Output esperado:
# Average inference: 150-300ms (CPU) / 50-100ms (GPU)
```

#### 4. ¿Por qué NO k6 ni JMeter?

**k6** y **JMeter** son herramientas de **load testing para APIs HTTP/backends**. NO aplican para:
- Modelos ML on-device (TFLite)
- Procesamiento local de imágenes
- APIs nativas de Android

**Razones:**
- ❌ No pueden invocar `interpreter.run()` de TFLite
- ❌ No miden GPU/CPU del dispositivo
- ❌ No simulan streaming de cámara
- ❌ No acceden a código C++ nativo

### Thresholds por Dispositivo

Los thresholds se ajustan automáticamente según tipo de dispositivo:

| Dispositivo | Model Load | Inference | Total | FPS |
|-------------|------------|-----------|-------|-----|
| **Emulador x86_64** | 3000ms | 600ms | 800ms | 1 FPS |
| **ARM64 Real (CPU)** | 2000ms | 300ms | 500ms | 10 FPS |
| **ARM64 Real (GPU)** | 2000ms | 100ms | 200ms | 15 FPS |

**Configuración en código:**

```dart
// integration_test/performance_test.dart
class PerformanceThresholds {
  static const Map<String, int> emulator = {...};
  static const Map<String, int> realDevice = {...};
  static const Map<String, int> gpu = {...};

  static Map<String, int> get current {
    final deviceType = detectDeviceType();
    return deviceType == 'emulator' ? emulator : realDevice;
  }
}
```

### Interpretación de Resultados

#### Salida Exitosa ✅

```
═══════════════════════════════════════════════════════
Performance Tests - Device: realDevice
═══════════════════════════════════════════════════════

✓ Model load time: 1200ms (threshold: 2000ms)
✓ Inference time: 250ms (threshold: 300ms)
  Detections found: 5
✓ Preprocess time: 8ms (threshold: 20ms)
✓ Total pipeline: 280ms (threshold: 500ms)
✓ FPS (10 frames): 12.5 FPS (min: 10 FPS)
✓ Memory test completed (< 150 MB)
✓ Batch inference (50 frames):
  Avg: 265.3ms | Min: 230ms | Max: 310ms

All tests passed! ✅
```

#### Problemas Comunes ❌

**TEST 1 falla (Model loading > 2000ms):**
- **Causa:** I/O lento, modelo corrupto
- **Solución:** Verificar integridad del modelo, limpiar cache (`flutter clean`)

**TEST 2 falla (Inference > 300ms):**
- **Causa:** CPU throttling, emulador x86
- **Solución:** Usar dispositivo ARM64 real, considerar GPU delegate

**TEST 6 falla (FPS < 10):**
- **Causa:** Conversión YUV→RGB no usa C++ NEON
- **Solución:** Verificar que código nativo está compilado (`android/app/src/main/cpp/`)

**TEST 7 falla (Memory > 150 MB):**
- **Causa:** Memory leaks, cache no liberado
- **Solución:** Profiling con Android Studio, buscar objetos retenidos

### Comandos Útiles

```bash
# Tests unitarios (445 tests)
flutter test

# Integration tests de performance
flutter test integration_test/performance_test.dart

# Profile mode con DevTools
flutter run --profile

# Benchmark TFLite
adb shell /data/local/tmp/benchmark_model \
  --graph=/data/local/tmp/yolov11n_float32.tflite \
  --use_xnnpack=true
```

### Referencias

- [Flutter Performance Profiling](https://docs.flutter.dev/perf/ui-performance)
- [Integration Testing Guide](https://docs.flutter.dev/cookbook/testing/integration/profiling)
- [TFLite Benchmark Tools](https://www.tensorflow.org/lite/performance/measurement)
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools/overview)

---

## 📊 Métricas del Proyecto

### Cobertura de Código

| Módulo | Tests | Cobertura |
|--------|-------|-----------|
| YoloDetector | 7 | ~90% |
| Logging | 39 | ~95% |
| Security (InputValidator) | 133 | ~98% |
| Nutrition Models | 56 | ~95% |
| Auth State | 33 | ~95% |
| Camera Settings | 23 | ~92% |
| User Profile | 38 | ~93% |
| Ingredient Quantity | 45 | ~96% |
| Quantities Notifier | 115 | ~97% |
| **Total** | **445** | **~94%** |

### Rendimiento

**Nota:** Métricas actualizadas con instrumentación de `PerformanceMetrics`.

| Métrica | Emulador x86_64 | Dispositivo ARM64 | Threshold |
|---------|-----------------|-------------------|-----------|
| **Carga de modelo** | ~2000-3000ms | ~1000-1500ms | < 2000ms |
| **Conversión YUV→RGB (C++ NEON)** | N/A | ~10-15ms | < 50ms |
| **Conversión YUV→RGB (Dart isolate)** | ~80-120ms | ~50-80ms | < 150ms |
| **Preprocesamiento** | ~15-25ms | ~5-10ms | < 20ms |
| **Inferencia (CPU XNNPack)** | ~400-600ms | ~150-300ms | < 300ms |
| **Inferencia (GPU delegate)** | N/A | ~50-100ms | < 100ms |
| **Postprocesamiento + NMS** | ~30-50ms | ~10-30ms | < 50ms |
| **Total por frame** | ~600-800ms | ~200-400ms | < 500ms |
| **FPS (Live detection)** | ~1-2 FPS | ~10-15 FPS | > 10 FPS |
| **Memoria total** | ~120-140 MB | ~80-110 MB | < 150 MB |

**Observaciones:**
- GPU delegate solo disponible en dispositivos reales con GPU compatible
- C++ NEON solo en ARM64 (dispositivos físicos, no emuladores x86)
- FPS objetivo (10 FPS) se alcanza solo en dispositivos reales con optimizaciones nativas
- Métricas medidas con `PerformanceMetrics` class y validadas con integration tests

---

## 👨‍💻 Autor

**Kevin**  
Trabajo de Integración Curricular  
Escuela Politécnica Nacional (EPN)  
Quito, Ecuador — 2025

---

## 📄 Licencia

Este proyecto es parte de un Trabajo de Integración Curricular y su uso está sujeto a las políticas académicas de la EPN.

---

<div align="center">

**🍽️ NutriVisionAIEPN Mobile v1.0**

*Detección inteligente de ingredientes alimenticios con información nutricional*

✅ 445 tests pasando | ✅ 0 issues en flutter analyze | ✅ Firebase Auth integrado | ✅ FASE 6B completada

Made with ❤️ and Flutter

</div>
