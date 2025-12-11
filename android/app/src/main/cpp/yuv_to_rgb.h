// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                              yuv_to_rgb.h                                     ║
// ║              Header para conversión YUV420 a RGB optimizada                   ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Declaraciones de funciones de conversión de color optimizadas con NEON.     ║
// ║  Incluye versiones scalar (fallback) y SIMD (ARM NEON).                       ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

#ifndef YUV_TO_RGB_H
#define YUV_TO_RGB_H

#include <cstdint>

// ═══════════════════════════════════════════════════════════════════════════════
// FUNCIONES DE CONVERSIÓN
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * @brief Convierte una imagen YUV420 (NV21) a RGB24.
 *
 * @param yPlane     Puntero al plano Y (luminancia)
 * @param uvPlane    Puntero al plano UV entrelazado (NV21: V primero, U segundo)
 * @param rgbOutput  Puntero al buffer de salida RGB (debe tener width * height * 3 bytes)
 * @param width      Ancho de la imagen
 * @param height     Alto de la imagen
 * @param yRowStride Stride del plano Y en bytes
 * @param uvRowStride Stride del plano UV en bytes
 * @param uvPixelStride Stride entre píxeles UV (típicamente 2 para NV21)
 */
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
);

/**
 * @brief Versión escalar (fallback) de conversión YUV a RGB.
 *        Usa fórmulas ITU-R BT.601.
 */
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
);

#if defined(__ARM_NEON) || defined(__ARM_NEON__)
/**
 * @brief Versión NEON optimizada de conversión YUV a RGB.
 *        Procesa 8 píxeles en paralelo usando instrucciones SIMD.
 */
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
);
#endif

// ═══════════════════════════════════════════════════════════════════════════════
// UTILIDADES
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * @brief Clamp de valor al rango [0, 255].
 */
inline uint8_t clamp255(int value) {
    return static_cast<uint8_t>(value < 0 ? 0 : (value > 255 ? 255 : value));
}

#endif // YUV_TO_RGB_H
