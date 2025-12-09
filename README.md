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
9. [Permisos de Cámara y Galería](#-permisos-de-cámara-y-galería)
10. [Arquitectura de la Aplicación](#-arquitectura-de-la-aplicación)
11. [Testing](#-testing)
12. [Comandos Útiles](#-comandos-útiles)
13. [Generación de Builds](#-generación-de-builds)
14. [Roadmap de Desarrollo](#-roadmap-de-desarrollo)
15. [Solución de Problemas Comunes](#-solución-de-problemas-comunes)
16. [Referencias y Recursos](#-referencias-y-recursos)

---

## 🎯 Descripción del Proyecto

**NutriVisionAIEPN Mobile** es una aplicación Android desarrollada en Flutter que permite:

- 📸 Capturar imágenes de platos de comida ecuatoriana/mediterránea
- 🔍 Detectar automáticamente los ingredientes usando el modelo YOLO11n
- 🥗 Identificar hasta **83 clases** de ingredientes alimenticios
- 📊 Estimar macronutrientes (calorías, proteínas, carbohidratos, grasas)
- 💾 Funcionar **100% offline** sin necesidad de conexión a internet

### Modelo de ML

| Propiedad | Valor |
|-----------|-------|
| Arquitectura | YOLO11n (Ultralytics) |
| Formato | TensorFlow Lite (FP32) |
| Tamaño de entrada | 640×640 píxeles |
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
│   ├── data/models/
│   │   └── detection.dart          # ✅ Modelo de detección + extensiones
│   │
│   ├── presentation/pages/
│   │   └── detection_test_screen.dart  # ✅ Pantalla de pruebas con bounding boxes
│   │
│   └── ml/
│       └── yolo_detector.dart      # ✅ Detector YOLO completo (letterbox + NMS)
│
├── test/                            # ✅ Tests automatizados
│   ├── ml/
│   │   └── yolo_detector_test.dart # 26 tests pasando
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
├── core/                            # ❌ Pendiente
│   ├── constants/                   # Constantes de app, ML, tema
│   ├── utils/                       # Utilidades de imagen, permisos
│   └── exceptions/                  # Excepciones personalizadas
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
│   ├── pages/                       # ✅ detection_test_screen.dart
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
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11
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

## 🧠 Integración del Modelo TFLite

### lib/ml/yolo_detector.dart

El detector YOLO está implementado con las siguientes características:

| Componente | Descripción |
|------------|-------------|
| **Preprocesamiento** | Letterbox resize a 640×640 con padding gris (114,114,114) |
| **Inferencia** | TFLite con XNNPack delegate para compatibilidad universal |
| **Postprocesamiento** | Non-Maximum Suppression (NMS) por clase |
| **Configuración** | Confianza: 0.40, IoU: 0.45 |

```dart
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../data/models/detection.dart';

/// Detector YOLO11n para identificación de ingredientes alimenticios
class YoloDetector {
  // ═══════════════════════════════════════════════════════════════
  // CONSTANTES DEL MODELO
  // ═══════════════════════════════════════════════════════════════
  static const int inputSize = 640;
  static const int numClasses = 83;
  static const double defaultConfidenceThreshold = 0.40;
  static const double defaultIouThreshold = 0.45;

  // ═══════════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════════
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<String> get labels => List.unmodifiable(_labels);
  int get numLabels => _labels.length;

  // ═══════════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════

  /// Inicializa el detector cargando el modelo y las etiquetas
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configurar opciones del intérprete
      final options = InterpreterOptions()..threads = 4;

      // Cargar modelo desde assets
      _interpreter = await Interpreter.fromAsset(
        'assets/models/yolov11n_float32.tflite',
        options: options,
      );
      _interpreter!.allocateTensors();

      // Cargar etiquetas
      final labelsData = await rootBundle.loadString('assets/labels/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      _isInitialized = true;
      print('✅ YoloDetector inicializado: ${_labels.length} clases');
    } catch (e) {
      print('❌ Error inicializando YoloDetector: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // INFERENCIA
  // ═══════════════════════════════════════════════════════════════

  /// Ejecuta detección sobre una imagen
  Future<List<Detection>> detect(
    img.Image image, {
    double confidenceThreshold = defaultConfidenceThreshold,
    double iouThreshold = defaultIouThreshold,
  }) async {
    if (!_isInitialized || _interpreter == null) {
      throw StateError('YoloDetector no inicializado. Llama a initialize() primero.');
    }

    // 1. Preprocesamiento: letterbox resize
    final preprocessed = _preprocessImage(image);

    // 2. Preparar tensor de salida
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final outputBuffer = List.generate(
      outputShape[0],
      (_) => List.generate(
        outputShape[1],
        (_) => List.filled(outputShape[2], 0.0),
      ),
    );

    // 3. Ejecutar inferencia
    _interpreter!.run(preprocessed.tensor, outputBuffer);

    // 4. Postprocesamiento
    final detections = _postprocess(
      outputBuffer,
      preprocessed.scale,
      preprocessed.padLeft,
      preprocessed.padTop,
      image.width,
      image.height,
      confidenceThreshold,
      iouThreshold,
    );

    return detections;
  }

  // ═══════════════════════════════════════════════════════════════
  // PREPROCESAMIENTO (Letterbox)
  // ═══════════════════════════════════════════════════════════════

  _PreprocessResult _preprocessImage(img.Image image) {
    final int origW = image.width;
    final int origH = image.height;

    // Calcular escala manteniendo aspect ratio
    final double scale = (inputSize / origW) < (inputSize / origH)
        ? inputSize / origW
        : inputSize / origH;

    final int newW = (origW * scale).round();
    final int newH = (origH * scale).round();

    // Redimensionar
    final resized = img.copyResize(
      image,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear,
    );

    // Crear canvas con padding gris (114, 114, 114)
    final padded = img.Image(width: inputSize, height: inputSize);
    img.fill(padded, color: img.ColorRgb8(114, 114, 114));

    final padLeft = (inputSize - newW) ~/ 2;
    final padTop = (inputSize - newH) ~/ 2;

    img.compositeImage(padded, resized, dstX: padLeft, dstY: padTop);

    // Convertir a tensor normalizado [0, 1] con shape [1, 640, 640, 3]
    final tensor = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = padded.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          },
        ),
      ),
    );

    return _PreprocessResult(
      tensor: tensor,
      scale: scale,
      padLeft: padLeft,
      padTop: padTop,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // POSTPROCESAMIENTO (NMS)
  // ═══════════════════════════════════════════════════════════════

  List<Detection> _postprocess(
    List<List<List<double>>> output,
    double scale,
    int padLeft,
    int padTop,
    int origWidth,
    int origHeight,
    double confidenceThreshold,
    double iouThreshold,
  ) {
    List<Detection> detections = [];
    final int numPredictions = output[0][0].length;

    for (int i = 0; i < numPredictions; i++) {
      final double cx = output[0][0][i];
      final double cy = output[0][1][i];
      final double w = output[0][2][i];
      final double h = output[0][3][i];

      double maxScore = 0;
      int classId = 0;

      for (int c = 0; c < numClasses; c++) {
        final score = output[0][4 + c][i];
        if (score > maxScore) {
          maxScore = score;
          classId = c;
        }
      }

      if (maxScore < confidenceThreshold) continue;

      // Convertir coordenadas
      final double x1Model = cx - w / 2 - padLeft;
      final double y1Model = cy - h / 2 - padTop;
      final double x2Model = cx + w / 2 - padLeft;
      final double y2Model = cy + h / 2 - padTop;

      final double x1 = (x1Model / scale).clamp(0, origWidth.toDouble());
      final double y1 = (y1Model / scale).clamp(0, origHeight.toDouble());
      final double x2 = (x2Model / scale).clamp(0, origWidth.toDouble());
      final double y2 = (y2Model / scale).clamp(0, origHeight.toDouble());

      detections.add(Detection(
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
        confidence: maxScore,
        classId: classId,
        label: _labels[classId],
      ));
    }

    return _nonMaxSuppression(detections, iouThreshold);
  }

  List<Detection> _nonMaxSuppression(List<Detection> detections, double iouThreshold) {
    if (detections.isEmpty) return [];

    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    List<Detection> result = [];
    List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      result.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        if (detections[i].classId != detections[j].classId) continue;

        final iou = detections[i].iou(detections[j]);
        if (iou >= iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════
  // LIMPIEZA
  // ═══════════════════════════════════════════════════════════════

  void dispose() {
    if (_isInitialized && _interpreter != null) {
      _interpreter!.close();
      _interpreter = null;
      _isInitialized = false;
    }
  }
}

class _PreprocessResult {
  final List<List<List<List<double>>>> tensor;
  final double scale;
  final int padLeft;
  final int padTop;

  _PreprocessResult({
    required this.tensor,
    required this.scale,
    required this.padLeft,
    required this.padTop,
  });
}
```

### lib/data/models/detection.dart

```dart
/// Resultado de detección de un ingrediente
class Detection {
  final double x1, y1, x2, y2;
  final double confidence;
  final int classId;
  final String label;

  const Detection({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.confidence,
    required this.classId,
    required this.label,
  });

  double get width => x2 - x1;
  double get height => y2 - y1;
  double get area => width * height;
  double get centerX => (x1 + x2) / 2;
  double get centerY => (y1 + y2) / 2;
  double get aspectRatio => width / height;

  /// Calcula IoU (Intersection over Union) con otra detección
  double iou(Detection other) {
    final xi1 = x1 > other.x1 ? x1 : other.x1;
    final yi1 = y1 > other.y1 ? y1 : other.y1;
    final xi2 = x2 < other.x2 ? x2 : other.x2;
    final yi2 = y2 < other.y2 ? y2 : other.y2;

    final interW = (xi2 - xi1) > 0 ? (xi2 - xi1) : 0;
    final interH = (yi2 - yi1) > 0 ? (yi2 - yi1) : 0;
    final intersection = interW * interH;

    final union = area + other.area - intersection;
    return union > 0 ? intersection / union : 0;
  }

  Detection copyWith({
    double? x1, double? y1, double? x2, double? y2,
    double? confidence, int? classId, String? label,
  }) {
    return Detection(
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      x2: x2 ?? this.x2,
      y2: y2 ?? this.y2,
      confidence: confidence ?? this.confidence,
      classId: classId ?? this.classId,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {
    'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2,
    'confidence': confidence, 'classId': classId, 'label': label,
  };

  factory Detection.fromJson(Map<String, dynamic> json) => Detection(
    x1: (json['x1'] as num).toDouble(),
    y1: (json['y1'] as num).toDouble(),
    x2: (json['x2'] as num).toDouble(),
    y2: (json['y2'] as num).toDouble(),
    confidence: (json['confidence'] as num).toDouble(),
    classId: json['classId'] as int,
    label: json['label'] as String,
  );

  @override
  String toString() => 'Detection($label: ${(confidence * 100).toStringAsFixed(1)}%)';
}
```

---

## 🧪 Testing

### Tipos de Testing

| Tipo | Ubicación | Descripción |
|------|-----------|-------------|
| **Manual (UI)** | `lib/presentation/pages/detection_test_screen.dart` | Pantalla para probar detección desde galería |
| **Automatizado** | `test/ml/yolo_detector_test.dart` | Tests unitarios del detector |
| **Integración** | `integration_test/` | Tests de flujo completo |

### Configurar Test Assets

1. Crear carpeta para imágenes de prueba:

```powershell
mkdir test\test_assets\test_images
```

2. Copiar imágenes de prueba desde Kaggle (`flutter_test_images.zip`) a `test/test_assets/test_images/`

### Ejecutar Tests

```powershell
# Ejecutar todos los tests
flutter test

# Ejecutar solo tests del detector
flutter test test/ml/yolo_detector_test.dart

# Ejecutar con verbose output
flutter test --reporter expanded
```

### Pantalla de Pruebas Manuales

La pantalla `DetectionTestScreen` permite:

- 📷 Seleccionar imagen desde galería
- 🔍 Ejecutar detección YOLO
- 📊 Ver resultados con bounding boxes
- ⏱️ Medir tiempo de inferencia

Para acceder, navega a la pantalla desde el menú de la app o temporalmente modifica `main.dart`:

```dart
void main() {
  runApp(MaterialApp(
    home: DetectionTestScreen(),
  ));
}
```

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
- [x] Implementar postprocesamiento (NMS por clase)
- [x] Probar inferencia con imagen estática
- [x] Crear modelo `Detection` con métodos auxiliares
- [x] Implementar pantalla de pruebas (`DetectionTestScreen`)
- [x] Implementar `BoundingBoxPainter` para visualizar detecciones

### Fase 3: Testing ✅ (90%)
- [x] Crear estructura de tests automatizados
- [x] Implementar 26 tests unitarios (YoloDetector + Detection)
- [x] Probar con 51 imágenes de Kaggle (6 platos)
- [x] Tests de rendimiento (< 600ms inferencia)
- [ ] Tests de widgets

### Fase 4: Cámara (Pendiente)
- [x] Implementar captura desde galería (ImagePicker)
- [ ] Implementar preview de cámara en tiempo real
- [ ] Integrar detección con cámara
- [x] Dibujar bounding boxes en overlay

### Fase 5: UI/UX (Pendiente)
- [ ] Diseñar pantalla principal
- [ ] Diseñar pantalla de resultados
- [ ] Implementar cards de ingredientes
- [ ] Agregar animaciones y transiciones

### Fase 6: Base de Datos (Pendiente)
- [ ] Crear schema SQLite de nutrientes
- [ ] Poblar base de datos inicial
- [ ] Implementar consultas de nutrientes
- [ ] Mostrar información nutricional

### Fase 7: Features Adicionales (Pendiente)
- [ ] Historial de análisis
- [ ] Compartir resultados
- [ ] Configuraciones de usuario
- [ ] Optimización de rendimiento

### Fase 8: Release (Pendiente)
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

### Error: "YoloDetector no inicializado"

Asegúrate de llamar `await detector.initialize()` antes de usar `detect()`:

```dart
final detector = YoloDetector();
await detector.initialize();  // ← Necesario antes de detectar
final results = await detector.detect(image);
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
| permission_handler | [pub.dev/packages/permission_handler](https://pub.dev/packages/permission_handler) |
| flutter_riverpod | [pub.dev/packages/flutter_riverpod](https://pub.dev/packages/flutter_riverpod) |
| sqflite | [pub.dev/packages/sqflite](https://pub.dev/packages/sqflite) |

### Recursos del Proyecto

- **Notebook de Kaggle:** Entrenamiento YOLO11n
- **Dataset:** NutriVisionAIEPN (Roboflow)
- **Modelo:** `yolov11n_float32.tflite` (10.27 MB)

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

**🍽️ NutriVisionAIEPN Mobile**

*Detección inteligente de ingredientes alimenticios*

Made with ❤️ and Flutter

</div>
