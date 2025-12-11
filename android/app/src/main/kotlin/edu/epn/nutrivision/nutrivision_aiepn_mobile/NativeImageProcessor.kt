// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         NativeImageProcessor.kt                               ║
// ║              Interfaz Kotlin para procesamiento nativo de imágenes            ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Provee JNI bindings para funciones C++ de conversión YUV→RGB.                ║
// ║  Usado por el MethodChannel para comunicación con Dart.                       ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

package edu.epn.nutrivision.nutrivision_aiepn_mobile

import java.nio.ByteBuffer

/**
 * Procesador de imágenes nativo usando C++ optimizado con NEON.
 *
 * Provee conversión YUV420 a RGB significativamente más rápida
 * que la implementación en Dart puro.
 */
object NativeImageProcessor {

    init {
        try {
            System.loadLibrary("nutrivision_native")
        } catch (e: UnsatisfiedLinkError) {
            android.util.Log.e("NativeImageProcessor", "Error cargando biblioteca nativa: ${e.message}")
        }
    }

    /**
     * Convierte un frame YUV420 a RGB888.
     *
     * @param yBuffer Buffer del plano Y (luminancia)
     * @param uBuffer Buffer del plano U (crominancia)
     * @param vBuffer Buffer del plano V (crominancia)
     * @param width Ancho de la imagen
     * @param height Alto de la imagen
     * @param yRowStride Stride del plano Y en bytes
     * @param uvRowStride Stride del plano UV en bytes
     * @param uvPixelStride Stride entre píxeles UV
     * @return ByteArray con datos RGB (width * height * 3 bytes)
     */
    @JvmStatic
    external fun convertYuvToRgb(
        yBuffer: ByteBuffer,
        uBuffer: ByteBuffer,
        vBuffer: ByteBuffer,
        width: Int,
        height: Int,
        yRowStride: Int,
        uvRowStride: Int,
        uvPixelStride: Int
    ): ByteArray?

    /**
     * Verifica si las optimizaciones NEON están disponibles.
     *
     * @return true si NEON está soportado en este dispositivo
     */
    @JvmStatic
    external fun isNeonSupported(): Boolean
}
