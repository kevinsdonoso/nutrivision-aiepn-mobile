// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                          build.gradle (app level)                             ║
// ║                        NutriVisionAIEPN Mobile                                ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Configuración de build para el módulo de la aplicación Android.              ║
// ║  Define: SDK versions, dependencias nativas, opciones de compilación,         ║
// ║          configuración de firma y optimizaciones para TensorFlow Lite.        ║
// ║                                                                               ║
// ║  Documentación:                                                               ║
// ║  - Android Gradle Plugin: https://developer.android.com/build                 ║
// ║  - Flutter Gradle Plugin: https://docs.flutter.dev/deployment/android         ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

// ═══════════════════════════════════════════════════════════════════════════════
// SECCIÓN 1: PLUGINS
// ═══════════════════════════════════════════════════════════════════════════════
// Los plugins se aplican en orden específico:
// 1. com.android.application - Plugin base de Android para apps
// 2. kotlin-android - Soporte para Kotlin en Android
// 3. dev.flutter.flutter-gradle-plugin - DEBE ir después de Android y Kotlin

plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter DEBE aplicarse después de los plugins de Android y Kotlin
    // para que pueda acceder a las configuraciones definidas por ellos
    id("dev.flutter.flutter-gradle-plugin")
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECCIÓN 2: CONFIGURACIÓN DE ANDROID
// ═══════════════════════════════════════════════════════════════════════════════

android {
    // ─────────────────────────────────────────────────────────────────────────────
    // NAMESPACE
    // ─────────────────────────────────────────────────────────────────────────────
    // Identificador único del paquete para la generación de la clase R
    // Debe coincidir con el applicationId o ser un subconjunto válido
    // Formato: dominio invertido + nombre de la app
    namespace = "edu.epn.nutrivision.nutrivision_aiepn_mobile"
    
    // ─────────────────────────────────────────────────────────────────────────────
    // COMPILE SDK VERSION
    // ─────────────────────────────────────────────────────────────────────────────
    // Versión del SDK de Android contra la cual se compila la app
    // flutter.compileSdkVersion se define en flutter.gradle (actualmente 35)
    // Usar la última versión disponible para acceder a las APIs más recientes
    compileSdk = flutter.compileSdkVersion
    
    // ─────────────────────────────────────────────────────────────────────────────
    // NDK VERSION
    // ─────────────────────────────────────────────────────────────────────────────
    // Native Development Kit - Necesario para código nativo C/C++
    // CRÍTICO para tflite_flutter que usa bibliotecas nativas de TensorFlow
    // flutter.ndkVersion asegura compatibilidad con los plugins de Flutter
    ndkVersion = flutter.ndkVersion

    // ─────────────────────────────────────────────────────────────────────────────
    // OPCIONES DE COMPILACIÓN JAVA
    // ─────────────────────────────────────────────────────────────────────────────
    // Define la versión de Java para compilación de código fuente y bytecode
    // Java 17 es el estándar actual para Android (AGP 8.0+)
    // Nota: Java 8 está obsoleto y genera warnings
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // OPCIONES DE KOTLIN
    // ─────────────────────────────────────────────────────────────────────────────
    // JVM target para código Kotlin - debe coincidir con compileOptions
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // DEFAULT CONFIG
    // ─────────────────────────────────────────────────────────────────────────────
    // Configuración por defecto aplicada a todas las variantes de build
    defaultConfig {
        // Application ID: Identificador único en Google Play Store
        // Formato recomendado: dominio invertido de la organización + nombre app
        // IMPORTANTE: Una vez publicado, NO se puede cambiar
        applicationId = "edu.epn.nutrivision.nutrivision_aiepn_mobile"
        
        // ═══════════════════════════════════════════════════════════════════════
        // MIN SDK VERSION - CRÍTICO PARA TFLITE
        // ═══════════════════════════════════════════════════════════════════════
        // Versión mínima de Android requerida para instalar la app
        // 
        // IMPORTANTE: Establecemos minSdk = 26 (Android 8.0 Oreo) porque:
        //
        // 1. TensorFlow Lite GPU Delegate requiere API 26+
        //    - OpenGL ES 3.1 (requerido para GPU delegate) solo está garantizado en API 26+
        //    - NNAPI (Neural Networks API) disponible desde API 27, pero funcional desde 26
        //
        // 2. Camera2 API funcionalidades completas
        //    - El plugin 'camera' usa Camera2 API que funciona mejor en API 26+
        //    - Mejor manejo de orientación y formatos de imagen (YUV_420_888)
        //
        // 3. Cobertura de mercado (2024):
        //    - API 26+ cubre ~95% de dispositivos Android activos
        //    - Sacrificio mínimo de usuarios vs beneficios técnicos
        //
        // 4. Permisos en runtime estables
        //    - Modelo de permisos maduro y consistente desde API 26
        //
        // Si necesitas soportar dispositivos más antiguos, puedes bajar a 24,
        // pero perderás GPU delegate y algunas optimizaciones de cámara.
        minSdk = 26
        
        // Target SDK: Versión de Android para la cual la app está optimizada
        // Usar la última versión para aprovechar nuevas características y
        // cumplir con requisitos de Google Play (obligatorio targetSdk >= 33 desde 2024)
        targetSdk = flutter.targetSdkVersion
        
        // Version Code: Número entero incremental para cada release
        // Google Play usa este número para determinar actualizaciones
        // flutter.versionCode se extrae de pubspec.yaml (version: X.Y.Z+CODE)
        versionCode = flutter.versionCode
        
        // Version Name: Versión visible al usuario (semántica: MAJOR.MINOR.PATCH)
        // flutter.versionName se extrae de pubspec.yaml (version: X.Y.Z+code)
        versionName = flutter.versionName
        
        // ═══════════════════════════════════════════════════════════════════════
        // NDK ABI FILTERS - Arquitecturas de CPU soportadas
        // ═══════════════════════════════════════════════════════════════════════
        // Limita las arquitecturas nativas incluidas en el APK
        //
        // - armeabi-v7a: ARM 32-bit (dispositivos antiguos, ~10% del mercado)
        // - arm64-v8a: ARM 64-bit (mayoría de dispositivos modernos, ~85%)
        // - x86_64: Emuladores y algunos Chromebooks (~5%)
        //
        // NOTA: x86 (32-bit) omitido porque está prácticamente extinto
        //
        // Beneficio: Reduce tamaño del APK al no incluir arquitecturas no usadas
        // Con --split-per-abi, cada APK solo incluye una arquitectura
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // AAPT OPTIONS - Asset Packaging Tool
    // ─────────────────────────────────────────────────────────────────────────────
    // Configuración del empaquetador de recursos de Android
    //
    // ═══════════════════════════════════════════════════════════════════════════
    // CRÍTICO PARA TENSORFLOW LITE
    // ═══════════════════════════════════════════════════════════════════════════
    //
    // Por defecto, AAPT comprime los archivos en assets/ para reducir tamaño del APK.
    // Sin embargo, los modelos TFLite DEBEN permanecer sin comprimir porque:
    //
    // 1. TFLite usa memory mapping (mmap) para cargar modelos eficientemente
    //    - mmap requiere acceso directo al archivo sin descompresión
    //    - Si está comprimido, debe descomprimirse en RAM (consume memoria)
    //
    // 2. Modelos comprimidos causan errores como:
    //    - "Failed to load model"
    //    - "Invalid FlatBuffer"
    //    - "Unexpected end of file"
    //
    // 3. La compresión de modelos .tflite es ineficiente de todos modos
    //    - Los modelos ya están optimizados y no comprimen bien
    //    - Ahorro típico: <5% vs costo de rendimiento significativo
    //
    // noCompress: Lista de extensiones que NO deben comprimirse
    aaptOptions {
        noCompress += listOf("tflite", "lite")
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // BUILD TYPES
    // ─────────────────────────────────────────────────────────────────────────────
    // Define variantes de compilación (debug, release, profile, etc.)
    buildTypes {
        // ─────────────────────────────────────────────────────────────────────
        // DEBUG BUILD
        // ─────────────────────────────────────────────────────────────────────
        // Configuración para desarrollo y testing
        debug {
            // Debug usa firma automática (debug.keystore)
            // No requiere configuración adicional
            
            // Deshabilitamos minificación para debugging más fácil
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Sufijo para diferenciar debug de release en el dispositivo
            // Permite tener ambas versiones instaladas simultáneamente
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        
        // ─────────────────────────────────────────────────────────────────────
        // RELEASE BUILD
        // ─────────────────────────────────────────────────────────────────────
        // Configuración para producción (Google Play Store)
        release {
            // ═══════════════════════════════════════════════════════════════
            // FIRMA DE LA APP
            // ═══════════════════════════════════════════════════════════════
            // Para publicar en Play Store, necesitas crear tu propio keystore:
            //
            // 1. Generar keystore:
            //    keytool -genkey -v -keystore nutrivision-release.jks \
            //            -keyalg RSA -keysize 2048 -validity 10000 \
            //            -alias nutrivision
            //
            // 2. Crear archivo android/key.properties:
            //    storePassword=tu_password
            //    keyPassword=tu_password
            //    keyAlias=nutrivision
            //    storeFile=../nutrivision-release.jks
            //
            // 3. Descomentar el bloque signingConfigs más abajo
            //
            // Por ahora, usamos debug keys para que `flutter run --release` funcione
            signingConfig = signingConfigs.getByName("debug")
            
            // ═══════════════════════════════════════════════════════════════
            // MINIFICACIÓN Y OFUSCACIÓN (R8/ProGuard)
            // ═══════════════════════════════════════════════════════════════
            // R8 es el compilador que reemplazó a ProGuard en Android
            //
            // isMinifyEnabled = true:
            //   - Elimina código no usado (tree shaking)
            //   - Ofusca nombres de clases/métodos (seguridad)
            //   - Optimiza bytecode
            //   - Reduce tamaño del APK significativamente
            //
            // isShrinkResources = true:
            //   - Elimina recursos no referenciados (imágenes, strings, etc.)
            //
            // IMPORTANTE: Requiere proguard-rules.pro configurado para TFLite
            // Ver archivo android/app/proguard-rules.pro
            isMinifyEnabled = true
            isShrinkResources = true
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────────
    // PACKAGING OPTIONS
    // ─────────────────────────────────────────────────────────────────────────────
    // Configuración adicional para el empaquetado del APK/AAB
    packagingOptions {
        // Excluir archivos de metadatos que causan conflictos
        // cuando múltiples librerías incluyen el mismo archivo
        resources {
            excludes += listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt"
            )
        }
        
        // Configuración para librerías nativas (.so)
        jniLibs {
            // Permitir que librerías nativas se incluyan sin comprimir
            // Mejora el tiempo de carga de TFLite
            useLegacyPackaging = true
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECCIÓN 3: CONFIGURACIÓN DE FLUTTER
// ═══════════════════════════════════════════════════════════════════════════════
// Configuración específica del plugin de Flutter

flutter {
    // Ruta al directorio raíz del proyecto Flutter (donde está pubspec.yaml)
    // "../.." significa: android/app/ → android/ → raíz del proyecto
    source = "../.."
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECCIÓN 4: DEPENDENCIAS (Opcional)
// ═══════════════════════════════════════════════════════════════════════════════
// Dependencias adicionales de Android que no vienen de plugins Flutter
// La mayoría de dependencias se manejan automáticamente por los plugins

dependencies {
    // Las dependencias de los plugins Flutter se agregan automáticamente
    // Solo agregar aquí si necesitas dependencias Android nativas adicionales
    
    // Ejemplo: Si necesitas CameraX directamente (no recomendado con plugin camera)
    // implementation("androidx.camera:camera-core:1.3.0")
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTAS TÉCNICAS ADICIONALES
// ═══════════════════════════════════════════════════════════════════════════════
//
// 1. PARA GENERAR APK DE RELEASE:
//    flutter build apk --release
//    flutter build apk --split-per-abi --release  (APKs separados por arquitectura)
//
// 2. PARA GENERAR APP BUNDLE (Play Store):
//    flutter build appbundle --release
//
// 3. PARA DEPURAR PROBLEMAS DE TFLITE:
//    - Verificar que el modelo está en assets/models/
//    - Verificar que está registrado en pubspec.yaml
//    - Verificar que noCompress incluye 'tflite'
//    - Probar con: flutter clean && flutter pub get && flutter run
//
// 4. OPTIMIZACIÓN DE TAMAÑO:
//    - Con --split-per-abi el APK arm64-v8a es ~15-20 MB
//    - Sin split, el APK universal es ~25-30 MB
//    - El modelo TFLite (10.27 MB) es la mayor parte del tamaño
//
// 5. FIRMA PARA PRODUCCIÓN:
//    Antes de publicar, configurar signing correctamente.
//    NUNCA subir key.properties ni el keystore a Git.
//
// ═══════════════════════════════════════════════════════════════════════════════