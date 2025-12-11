// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                        native_image_processor.cpp                             ║
// ║              Procesador de imágenes nativo para NutriVision                   ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Implementación de conversión YUV420 a RGB optimizada con NEON.               ║
// ║  JNI bindings para acceso desde Dart vía Platform Channels.                   ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

#include <jni.h>
#include <android/log.h>
#include <cstdint>
#include <cstring>

#include "yuv_to_rgb.h"

// Para instrucciones NEON en ARM
#if defined(__ARM_NEON) || defined(__ARM_NEON__)
#include <arm_neon.h>
#define USE_NEON 1
#else
#define USE_NEON 0
#endif

// ═══════════════════════════════════════════════════════════════════════════════
// LOGGING
// ═══════════════════════════════════════════════════════════════════════════════

#define LOG_TAG "NutriVisionNative"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// ═══════════════════════════════════════════════════════════════════════════════
// CONVERSIÓN ESCALAR (Fallback)
// ═══════════════════════════════════════════════════════════════════════════════

void convertYuv420ToRgbScalar(
    const uint8_t* yPlane,
    const uint8_t* uPlane,
    const uint8_t* vPlane,
    uint8_t* rgbOutput,
    int width,
    int height,
    int yRowStride,
    int uvRowStride,
    int uvPixelStride
) {
    int rgbIndex = 0;

    for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
            // Índice en plano Y
            int yIndex = row * yRowStride + col;

            // Índice en planos UV (submuestreado 2x2)
            int uvRow = row / 2;
            int uvCol = col / 2;
            int uvIndex = uvRow * uvRowStride + uvCol * uvPixelStride;

            // Valores YUV
            int y = yPlane[yIndex] & 0xFF;
            int u = uPlane[uvIndex] & 0xFF;
            int v = vPlane[uvIndex] & 0xFF;

            // Conversión ITU-R BT.601
            // R = Y + 1.402 * (V - 128)
            // G = Y - 0.344136 * (U - 128) - 0.714136 * (V - 128)
            // B = Y + 1.772 * (U - 128)
            int r = y + (int)(1.402f * (v - 128));
            int g = y - (int)(0.344136f * (u - 128)) - (int)(0.714136f * (v - 128));
            int b = y + (int)(1.772f * (u - 128));

            // Clamp a [0, 255]
            rgbOutput[rgbIndex++] = clamp255(r);
            rgbOutput[rgbIndex++] = clamp255(g);
            rgbOutput[rgbIndex++] = clamp255(b);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONVERSIÓN NEON OPTIMIZADA
// ═══════════════════════════════════════════════════════════════════════════════

#if USE_NEON
void convertYuv420ToRgbNeon(
    const uint8_t* yPlane,
    const uint8_t* uPlane,
    const uint8_t* vPlane,
    uint8_t* rgbOutput,
    int width,
    int height,
    int yRowStride,
    int uvRowStride,
    int uvPixelStride
) {
    // Constantes de conversión en formato Q8 (punto fijo)
    // Multiplicamos por 256 para trabajar con enteros
    const int16x8_t v_c1 = vdupq_n_s16(359);   // 1.402 * 256
    const int16x8_t v_c2 = vdupq_n_s16(88);    // 0.344136 * 256
    const int16x8_t v_c3 = vdupq_n_s16(183);   // 0.714136 * 256
    const int16x8_t v_c4 = vdupq_n_s16(454);   // 1.772 * 256
    const int16x8_t v_128 = vdupq_n_s16(128);

    for (int row = 0; row < height; row++) {
        int uvRow = row / 2;
        int rgbRowOffset = row * width * 3;
        int yRowOffset = row * yRowStride;
        int uvRowOffset = uvRow * uvRowStride;

        // Procesar 8 píxeles a la vez
        int col = 0;
        for (; col + 8 <= width; col += 8) {
            // Cargar 8 valores Y
            uint8x8_t y8 = vld1_u8(&yPlane[yRowOffset + col]);
            int16x8_t y = vreinterpretq_s16_u16(vmovl_u8(y8));

            // Cargar 4 valores U y V (submuestreados), duplicar para 8 píxeles
            uint8_t u_vals[4], v_vals[4];
            for (int i = 0; i < 4; i++) {
                int uvIndex = uvRowOffset + ((col / 2) + i) * uvPixelStride;
                u_vals[i] = uPlane[uvIndex];
                v_vals[i] = vPlane[uvIndex];
            }

            // Duplicar cada valor UV para 2 píxeles adyacentes
            uint8_t u8[8] = {u_vals[0], u_vals[0], u_vals[1], u_vals[1],
                            u_vals[2], u_vals[2], u_vals[3], u_vals[3]};
            uint8_t v8[8] = {v_vals[0], v_vals[0], v_vals[1], v_vals[1],
                            v_vals[2], v_vals[2], v_vals[3], v_vals[3]};

            int16x8_t u = vreinterpretq_s16_u16(vmovl_u8(vld1_u8(u8)));
            int16x8_t v = vreinterpretq_s16_u16(vmovl_u8(vld1_u8(v8)));

            // U - 128, V - 128
            int16x8_t u_shifted = vsubq_s16(u, v_128);
            int16x8_t v_shifted = vsubq_s16(v, v_128);

            // Calcular R, G, B
            // R = Y + 1.402 * V'
            int16x8_t r_contrib = vshrq_n_s16(vmulq_s16(v_c1, v_shifted), 8);
            int16x8_t r = vaddq_s16(y, r_contrib);

            // G = Y - 0.344136 * U' - 0.714136 * V'
            int16x8_t g_contrib1 = vshrq_n_s16(vmulq_s16(v_c2, u_shifted), 8);
            int16x8_t g_contrib2 = vshrq_n_s16(vmulq_s16(v_c3, v_shifted), 8);
            int16x8_t g = vsubq_s16(vsubq_s16(y, g_contrib1), g_contrib2);

            // B = Y + 1.772 * U'
            int16x8_t b_contrib = vshrq_n_s16(vmulq_s16(v_c4, u_shifted), 8);
            int16x8_t b = vaddq_s16(y, b_contrib);

            // Clamp a [0, 255] y convertir a uint8
            uint8x8_t r8 = vqmovun_s16(r);
            uint8x8_t g8 = vqmovun_s16(g);
            uint8x8_t b8 = vqmovun_s16(b);

            // Intercalar RGB y almacenar
            uint8x8x3_t rgb;
            rgb.val[0] = r8;
            rgb.val[1] = g8;
            rgb.val[2] = b8;
            vst3_u8(&rgbOutput[rgbRowOffset + col * 3], rgb);
        }

        // Procesar píxeles restantes con método escalar
        for (; col < width; col++) {
            int yIndex = yRowOffset + col;
            int uvIndex = uvRowOffset + (col / 2) * uvPixelStride;

            int y_val = yPlane[yIndex];
            int u_val = uPlane[uvIndex];
            int v_val = vPlane[uvIndex];

            int r = y_val + (int)(1.402f * (v_val - 128));
            int g = y_val - (int)(0.344136f * (u_val - 128)) - (int)(0.714136f * (v_val - 128));
            int b_val = y_val + (int)(1.772f * (u_val - 128));

            int rgbIdx = rgbRowOffset + col * 3;
            rgbOutput[rgbIdx] = clamp255(r);
            rgbOutput[rgbIdx + 1] = clamp255(g);
            rgbOutput[rgbIdx + 2] = clamp255(b_val);
        }
    }
}
#endif

// ═══════════════════════════════════════════════════════════════════════════════
// FUNCIÓN PRINCIPAL DE CONVERSIÓN
// ═══════════════════════════════════════════════════════════════════════════════

void convertYuv420ToRgb(
    const uint8_t* yPlane,
    const uint8_t* uPlane,
    const uint8_t* vPlane,
    uint8_t* rgbOutput,
    int width,
    int height,
    int yRowStride,
    int uvRowStride,
    int uvPixelStride
) {
#if USE_NEON
    convertYuv420ToRgbNeon(yPlane, uPlane, vPlane, rgbOutput,
                          width, height, yRowStride, uvRowStride, uvPixelStride);
#else
    convertYuv420ToRgbScalar(yPlane, uPlane, vPlane, rgbOutput,
                            width, height, yRowStride, uvRowStride, uvPixelStride);
#endif
}

// ═══════════════════════════════════════════════════════════════════════════════
// JNI BINDINGS
// ═══════════════════════════════════════════════════════════════════════════════

extern "C" {

/**
 * Convierte frame YUV420 a RGB888.
 *
 * @param yBuffer ByteBuffer del plano Y
 * @param uBuffer ByteBuffer del plano U
 * @param vBuffer ByteBuffer del plano V
 * @param width Ancho de la imagen
 * @param height Alto de la imagen
 * @param yRowStride Stride del plano Y
 * @param uvRowStride Stride del plano UV
 * @param uvPixelStride Stride de píxel UV
 * @return ByteArray con datos RGB (width * height * 3 bytes)
 */
JNIEXPORT jbyteArray JNICALL
Java_edu_epn_nutrivision_nutrivision_1aiepn_1mobile_NativeImageProcessor_convertYuvToRgb(
    JNIEnv* env,
    jclass clazz,
    jobject yBuffer,
    jobject uBuffer,
    jobject vBuffer,
    jint width,
    jint height,
    jint yRowStride,
    jint uvRowStride,
    jint uvPixelStride
) {
    // Obtener punteros a los buffers
    auto* yPlane = static_cast<uint8_t*>(env->GetDirectBufferAddress(yBuffer));
    auto* uPlane = static_cast<uint8_t*>(env->GetDirectBufferAddress(uBuffer));
    auto* vPlane = static_cast<uint8_t*>(env->GetDirectBufferAddress(vBuffer));

    if (!yPlane || !uPlane || !vPlane) {
        LOGE("Error: buffers inválidos");
        return nullptr;
    }

    // Crear buffer de salida RGB
    int rgbSize = width * height * 3;
    auto* rgbOutput = new uint8_t[rgbSize];

    // Convertir
    convertYuv420ToRgb(yPlane, uPlane, vPlane, rgbOutput,
                       width, height, yRowStride, uvRowStride, uvPixelStride);

    // Crear y llenar array Java
    jbyteArray result = env->NewByteArray(rgbSize);
    env->SetByteArrayRegion(result, 0, rgbSize, reinterpret_cast<jbyte*>(rgbOutput));

    // Liberar memoria
    delete[] rgbOutput;

    return result;
}

/**
 * Verifica si NEON está disponible.
 */
JNIEXPORT jboolean JNICALL
Java_edu_epn_nutrivision_nutrivision_1aiepn_1mobile_NativeImageProcessor_isNeonSupported(
    JNIEnv* env,
    jclass clazz
) {
#if USE_NEON
    return JNI_TRUE;
#else
    return JNI_FALSE;
#endif
}

} // extern "C"
