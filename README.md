# 🍽️ NutriVisionAIEPN Mobile

> **Aplicación móvil Flutter para reconocimiento automático de alimentos mediante visión por computador usando YOLO11n (TensorFlow Lite) ejecutado on-device. Estima macronutrientes consultando una base de datos SQLite local.**
>
> 📚 *Proyecto de Trabajo de Integración Curricular — Escuela Politécnica Nacional (EPN)*

---

## 📋 Tabla de Contenidos

1. [Descripción del Proyecto](#-descripción-del-proyecto)
2. [Requisitos Previos](#-requisitos-previos)
3. [Instalación del Entorno de Desarrollo](#-instalación-del-entorno-de-desarrollo)
4. [Estructura del Proyecto](#-estructura-del-proyecto)
5. [Configuración Inicial](#-configuración-inicial)
6. [Dependencias (pubspec.yaml)](#-dependencias-pubspecyaml)
7. [Configuración de Android](#-configuración-de-android)
8. [Integración del Modelo TFLite](#-integración-del-modelo-tflite)
9. [Sistema de Excepciones](#-sistema-de-excepciones)
10. [Permisos de Cámara y Galería](#-permisos-de-cámara-y-galería)
11. [Arquitectura de la Aplicación](#-arquitectura-de-la-aplicación)
12. [Testing](#-testing)
13. [Comandos Útiles](#-comandos-útiles)
14. [Generación de Builds](#-generación-de-builds)
15. [Roadmap de Desarrollo](#-roadmap-de-desarrollo)
16. [Solución de Problemas Comunes](#-solución-de-problemas-comunes)
17. [Referencias y Recursos](#-referencias-y-recursos)

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

## 💻 Requisitos Previos

### Hardware mínimo (PC de desarrollo)

- **RAM:** 8 GB (recomendado 16 GB)
- **Almacenamiento:** 10 GB libres para SDKs
- **SO:** Windows 10/11 64-bit

### Software requerido

| Software | Versión | Descarga |
|----------|---------|----------|
| Flutter SDK | 3.27.x (stable) | [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install) |
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
[✓] Flutter (Channel stable, 3.27.x)
[✓] Windows Version (Windows 11)
[✓] Android toolchain - develop for Android devices (Android SDK 35.0.0)
[✓] Android Studio (version 2024.x)
[✓] VS Code (optional)
[✓] Connected device (1 available)
```

---

## 📁 Estructura del Proyecto

### Estado Actual (Implementado)

```
nutrivision_aiepn_mobile/
│
├── android/                          # ✅ Configuración nativa Android
│   ├── app/
│   │   ├── build.gradle.kts         # Configuración de build Android
│   │   ├── proguard-rules.pro       # Reglas ProGuard para TFLite
│   │   └── src/main/
│   │       ├── AndroidManifest.xml  # Permisos de la app
│   │       └── res/                 # Recursos Android
│   └── build.gradle.kts             # Configuración Gradle del proyecto
│
├── assets/                          # ✅ Recursos de la app
│   ├── models/
│   │   └── yolov11n_float32.tflite # Modelo YOLO11n exportado (~10 MB)
│   └── labels/
│       └── labels.txt              # 83 clases de ingredientes
│
├── lib/                             # Código fuente Dart/Flutter
│   ├── main.dart                   # ✅ Punto de entrada de la app
│   │
│   ├── core/                       # ✅ Núcleo de la aplicación
│   │   └── exceptions/
│   │       └── app_exceptions.dart # Sistema completo de excepciones
│   │
│   ├── data/models/
│   │   └── detection.dart          # ✅ Modelo de detección con validaciones
│   │
│   ├── presentation/pages/
│   │   └── gallery_detection_page.dart  # ✅ Pantalla de detección desde galería
│   │
│   └── ml/
│       └── yolo_detector.dart      # ✅ Detector YOLO con desnormalización
│
├── test/                            # ✅ Tests automatizados
│   ├── ml/
│   │   └── yolo_detector_test.dart # 42 tests pasando
│   └── test_assets/test_images/    # 51 imágenes de prueba
│
├── pubspec.yaml                     # ✅ Dependencias configuradas
├── analysis_options.yaml            # ✅ Reglas de linting
├── .gitignore                       # ✅ Archivos ignorados
└── README.md                        # Este archivo
```

### Estructura Planeada (Pendiente)

```
lib/
├── core/                            # ✅ Implementado
│   ├── constants/                   # ❌ Pendiente
│   ├── utils/                       # ❌ Pendiente
│   └── exceptions/                  # ✅ app_exceptions.dart
│
├── data/                            # ⚠️ Parcial
│   ├── models/                      # ✅ detection.dart
│   ├── repositories/                # ❌ Pendiente
│   └── datasources/                 # ❌ Pendiente
│
├── domain/                          # ❌ Pendiente
│   ├── entities/                    # Entidades de dominio
│   ├── usecases/                    # Casos de uso
│   └── repositories/                # Interfaces
│
├── presentation/                    # ⚠️ Parcial
│   ├── providers/                   # ❌ Riverpod (pendiente)
│   ├── pages/                       # ✅ gallery_detection_page.dart
│   └── widgets/                     # ❌ Widgets reutilizables (pendiente)
│
└── ml/                              # ✅ Completo
    └── yolo_detector.dart
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
New-Item -ItemType Directory -Force -Path "assets\models"
New-Item -ItemType Directory -Force -Path "assets\labels"
New-Item -ItemType Directory -Force -Path "assets\database"
New-Item -ItemType Directory -Force -Path "lib\core\constants"
New-Item -ItemType Directory -Force -Path "lib\core\utils"
New-Item -ItemType Directory -Force -Path "lib\core\exceptions"
New-Item -ItemType Directory -Force -Path "lib\data\models"
New-Item -ItemType Directory -Force -Path "lib\data\repositories"
New-Item -ItemType Directory -Force -Path "lib\data\datasources"
New-Item -ItemType Directory -Force -Path "lib\domain\entities"
New-Item -ItemType Directory -Force -Path "lib\domain\usecases"
New-Item -ItemType Directory -Force -Path "lib\domain\repositories"
New-Item -ItemType Directory -Force -Path "lib\presentation\providers"
New-Item -ItemType Directory -Force -Path "lib\presentation\pages"
New-Item -ItemType Directory -Force -Path "lib\presentation\widgets"
New-Item -ItemType Directory -Force -Path "lib\ml"
New-Item -ItemType Directory -Force -Path "test\ml"
New-Item -ItemType Directory -Force -Path "test\unit"
New-Item -ItemType Directory -Force -Path "test\widget"
New-Item -ItemType Directory -Force -Path "test\test_assets\test_images"
New-Item -ItemType Directory -Force -Path "integration_test"
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
    - assets/database/
    
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

### lib/ml/yolo_detector.dart

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
└── DatabaseException
    └── IngredientNotFoundException # Ingrediente no en BD
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

### Resumen de Tests

| Grupo | Tests | Estado |
|-------|-------|--------|
| YoloDetector - Inicialización | 5 | ✅ |
| Detection - Propiedades | 14 | ✅ |
| DetectionListExtension | 10 | ✅ |
| YoloDetector - Detección | 3 | ✅ |
| YoloDetector - Consistencia | 1 | ✅ |
| YoloDetector - Imágenes Kaggle | 2 | ✅ |
| YoloDetector - Rendimiento | 1 | ✅ |
| Excepciones - Comportamiento | 6 | ✅ |
| **TOTAL** | **42** | ✅ |

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
- [x] Implementar pantalla de pruebas (`GalleryDetectionPage`)
- [x] Implementar `BoundingBoxPainter` con escalado correcto
- [x] Implementar filtrado por ingrediente

### Fase 3: Sistema de Excepciones ✅ (100%)
- [x] Crear jerarquía de excepciones personalizadas
- [x] Implementar `ExceptionHandler` para manejo centralizado
- [x] Integrar excepciones en `YoloDetector`
- [x] Integrar excepciones en `Detection`
- [x] Integrar excepciones en `GalleryDetectionPage`
- [x] Agregar validaciones en constructores

### Fase 4: Testing ✅ (100%)
- [x] Crear estructura de tests automatizados
- [x] Implementar 42 tests unitarios
- [x] Tests de YoloDetector (inicialización, detección, consistencia)
- [x] Tests de Detection (propiedades, validaciones, serialización)
- [x] Tests de excepciones
- [x] Tests con 51 imágenes de Kaggle
- [x] Tests de rendimiento (< 600ms inferencia)

### Fase 5: Cámara (Pendiente)
- [x] Implementar captura desde galería (ImagePicker)
- [ ] Implementar preview de cámara en tiempo real
- [ ] Integrar detección con cámara
- [x] Dibujar bounding boxes en overlay

### Fase 6: UI/UX (Pendiente)
- [ ] Diseñar pantalla principal
- [ ] Diseñar pantalla de resultados
- [ ] Implementar cards de ingredientes
- [ ] Agregar animaciones y transiciones

### Fase 7: Base de Datos (Pendiente)
- [ ] Crear schema SQLite de nutrientes
- [ ] Poblar base de datos inicial
- [ ] Implementar consultas de nutrientes
- [ ] Mostrar información nutricional

### Fase 8: Features Adicionales (Pendiente)
- [ ] Historial de análisis
- [ ] Compartir resultados
- [ ] Configuraciones de usuario
- [ ] Optimización de rendimiento

### Fase 9: Release (Pendiente)
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

## 📊 Métricas del Proyecto

### Cobertura de Código

| Módulo | Tests | Cobertura |
|--------|-------|-----------|
| `yolo_detector.dart` | 12 | ~95% |
| `detection.dart` | 24 | ~98% |
| `app_exceptions.dart` | 6 | ~90% |
| **Total** | **42** | **~94%** |

### Rendimiento

| Métrica | Valor | Dispositivo |
|---------|-------|-------------|
| Tiempo de inferencia | ~400-600ms | Emulador x86_64 |
| Tiempo de inferencia | ~150-300ms | Dispositivo ARM64 |
| Memoria modelo | ~10.27 MB | - |
| Frames procesados | ~3-5 FPS | Estimado |

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

*Detección inteligente de ingredientes alimenticios*

✅ 42 tests pasando | ✅ 0 issues en flutter analyze | ✅ Bounding boxes funcionando

Made with ❤️ and Flutter

</div>
