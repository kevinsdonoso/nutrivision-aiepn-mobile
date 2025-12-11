// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                            MainActivity.kt                                    ║
// ║              Activity principal de NutriVisionAIEPN Mobile                    ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Configura el MethodChannel para comunicación con código nativo C++.          ║
// ║  Provee conversión YUV→RGB optimizada con NEON para la detección en tiempo    ║
// ║  real desde la cámara.                                                        ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

package edu.epn.nutrivision.nutrivision_aiepn_mobile

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "edu.epn.nutrivision/native_image_processor"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "convertYuvToRgb" -> {
                    try {
                        val yBytes = call.argument<ByteArray>("yBytes")!!
                        val uBytes = call.argument<ByteArray>("uBytes")!!
                        val vBytes = call.argument<ByteArray>("vBytes")!!
                        val width = call.argument<Int>("width")!!
                        val height = call.argument<Int>("height")!!
                        val yRowStride = call.argument<Int>("yRowStride")!!
                        val uvRowStride = call.argument<Int>("uvRowStride")!!
                        val uvPixelStride = call.argument<Int>("uvPixelStride")!!

                        // Crear ByteBuffers directos para JNI
                        val yBuffer = ByteBuffer.allocateDirect(yBytes.size).put(yBytes)
                        val uBuffer = ByteBuffer.allocateDirect(uBytes.size).put(uBytes)
                        val vBuffer = ByteBuffer.allocateDirect(vBytes.size).put(vBytes)

                        // Resetear posición de los buffers
                        yBuffer.rewind()
                        uBuffer.rewind()
                        vBuffer.rewind()

                        val rgbBytes = NativeImageProcessor.convertYuvToRgb(
                            yBuffer, uBuffer, vBuffer,
                            width, height,
                            yRowStride, uvRowStride, uvPixelStride
                        )

                        if (rgbBytes != null) {
                            result.success(rgbBytes)
                        } else {
                            result.error("CONVERSION_ERROR", "Error en conversión nativa", null)
                        }
                    } catch (e: Exception) {
                        result.error("CONVERSION_ERROR", e.message, null)
                    }
                }
                "isNeonSupported" -> {
                    try {
                        result.success(NativeImageProcessor.isNeonSupported())
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
