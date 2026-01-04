# ═══════════════════════════════════════════════════════════════════
# ProGuard Rules para NutriVisionAIEPN Mobile
# ═══════════════════════════════════════════════════════════════════

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# TensorFlow Lite (CRÍTICO)
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }

# TFLite Flutter Plugin
-keep class com.tfliteflutter.** { *; }

# Métodos nativos
-keepclasseswithmembernames class * {
    native <methods>;
}

-dontwarn org.tensorflow.lite.gpu.**

# Google Play Core (Deferred Components)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**