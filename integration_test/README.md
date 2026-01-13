# Integration Tests - Performance

Tests de integración para validar el rendimiento del sistema de detección YOLO11n.

## Requisitos

- Flutter SDK >= 3.38.0
- Dispositivo Android físico (recomendado) o emulador
- Modelo TFLite en `assets/models/yolov11n_float32.tflite`
- Imagen de prueba en `test/test_assets/test_images/pizza.jpg` (opcional)

## Ejecutar Tests

### Opción 1: Ejecutar todos los tests

```bash
flutter test integration_test/performance_test.dart
```

### Opción 2: Con profiling habilitado

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/performance_test.dart \
  --profile
```

### Opción 3: Generar timeline JSON

```bash
flutter drive \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/performance_test.dart \
  --profile \
  --trace-startup \
  --timeline-summary-file=performance_timeline.json
```

## Tests Implementados

| Test | Descripción | Threshold |
|------|-------------|-----------|
| **TEST 1** | Carga de modelo | < 2000ms |
| **TEST 2** | Inferencia (CPU) | < 300ms |
| **TEST 3** | Preprocesamiento | < 20ms |
| **TEST 4** | Postprocesamiento | Cualitativo |
| **TEST 5** | Pipeline completo | < 500ms |
| **TEST 6** | FPS (10 frames) | > 10 FPS |
| **TEST 7** | Memory footprint | < 150 MB |
| **TEST 8** | Estabilidad (50 frames) | Sin crashes |

## Interpretar Resultados

### Salida de Ejemplo (Dispositivo ARM64 Real)

```
═══════════════════════════════════════════════════════
Performance Tests - Device Type: realDevice
Thresholds: {modelLoadMs: 2000, inferenceMs: 300, ...}
═══════════════════════════════════════════════════════

✓ Model load time: 1200ms (threshold: 2000ms)
✓ Inference time: 250ms (threshold: 300ms)
  Detections found: 5
✓ Preprocess time (approx): 8ms (threshold: 20ms)
✓ Postprocessing completed (5 detections)
✓ Total pipeline: 280ms (threshold: 500ms)
  Detections: 5
✓ FPS (10 frames): 12.5 FPS
  Min threshold: 10 FPS
✓ Memory test completed (verify manually with Android Profiler)
  Expected: < 150 MB
✓ Batch inference (50 frames):
  Avg: 265.3ms
  Min: 230ms
  Max: 310ms
  Range: 80ms

All tests passed! ✅
```

### Qué Hacer si Falla un Test

#### TEST 1 Falla (Model loading > 2000ms)

**Posibles causas:**
- Disco lento (I/O)
- Modelo corrupto
- Primera carga (cache frío)

**Solución:**
```bash
# Verificar integridad del modelo
ls -lh assets/models/yolov11n_float32.tflite
# Debería ser ~10.27 MB

# Limpiar cache
flutter clean
flutter pub get
```

#### TEST 2 Falla (Inference > 300ms CPU)

**Posibles causas:**
- CPU throttling (sobrecalentamiento)
- Emulador x86 (no ARM64)
- GPU delegate no disponible

**Solución:**
```bash
# Verificar arquitectura del dispositivo
adb shell getprop ro.product.cpu.abi
# Debería ser: arm64-v8a

# Considerar GPU delegate (ver README principal)
```

#### TEST 6 Falla (FPS < 10)

**Posibles causas:**
- Dispositivo lento
- Thermal throttling
- Conversión YUV→RGB no usa C++ NEON

**Solución:**
- Verificar que código nativo C++ está compilado (ver `android/app/src/main/cpp/`)
- Reducir resolución de entrada (640 → 416)
- Habilitar frame throttling (ya implementado en `camera_frame_processor.dart`)

#### TEST 7 Falla (Memory > 150 MB)

**Posibles causas:**
- Memory leaks
- Cache de nutrición no liberado
- Multiple instancias de detector

**Solución:**
```bash
# Profiling con Android Studio
# View > Tool Windows > Profiler
# Capturar heap dump y buscar objetos retenidos
```

## Thresholds por Dispositivo

Los thresholds se ajustan automáticamente según el tipo de dispositivo:

| Dispositivo | Model Load | Inference | Total | FPS |
|-------------|------------|-----------|-------|-----|
| **Emulador x86_64** | 3000ms | 600ms | 800ms | 1 FPS |
| **ARM64 Real (CPU)** | 2000ms | 300ms | 500ms | 10 FPS |
| **ARM64 Real (GPU)** | 2000ms | 100ms | 200ms | 15 FPS |

Para forzar un threshold específico, editar `PerformanceThresholds.detectDeviceType()`.

## Profiling Adicional

### Con Flutter DevTools

```bash
# 1. Ejecutar app en modo profile
flutter run --profile

# 2. Abrir DevTools
flutter pub global activate devtools
flutter pub global run devtools

# 3. Navegar a http://127.0.0.1:9100
# 4. Performance tab > Record > Ejecutar detección
```

### Con Android Profiler

```bash
# 1. Abrir Android Studio
# 2. Run > Profile 'app'
# 3. View > Tool Windows > Profiler
# 4. Seleccionar CPU/Memory/GPU según necesidad
```

## Continuous Integration

Para ejecutar en CI/CD:

```yaml
# .github/workflows/performance.yml
name: Performance Tests
on: [push]

jobs:
  performance:
    runs-on: macos-latest  # Requerido para emulador
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Run integration tests
        run: flutter test integration_test/performance_test.dart
      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: performance-results
          path: performance_timeline.json
```

## Referencias

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [TFLite Benchmark Tool](https://www.tensorflow.org/lite/performance/measurement)
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools/overview)
