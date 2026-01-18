// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         detector_provider.dart                                ║
// ║              Provider Riverpod para el detector YOLO                          ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Gestiona el ciclo de vida del YoloDetector como singleton.                   ║
// ║  Permite compartir la instancia entre páginas (galería y cámara).             ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/yolo_service.dart';

/// Provider que gestiona la instancia única del detector YOLO.
///
/// Uso:
/// ```dart
/// final detectorAsync = ref.watch(yoloDetectorProvider);
/// detectorAsync.when(
///   data: (detector) => detector.detect(image),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
/// ```
final yoloDetectorProvider = FutureProvider<YoloDetector>((ref) async {
  final detector = YoloDetector();
  await detector.initialize();

  // Liberar recursos cuando el provider ya no se use
  ref.onDispose(() {
    detector.dispose();
  });

  return detector;
});

/// Provider para verificar si el detector está inicializado.
///
/// Útil para mostrar estados de carga en la UI.
final isDetectorReadyProvider = Provider<bool>((ref) {
  final detectorAsync = ref.watch(yoloDetectorProvider);
  return detectorAsync.maybeWhen(
    data: (detector) => detector.isInitialized,
    orElse: () => false,
  );
});

/// Provider que expone las etiquetas del modelo.
///
/// Retorna lista vacía si el detector no está listo.
final detectorLabelsProvider = Provider<List<String>>((ref) {
  final detectorAsync = ref.watch(yoloDetectorProvider);
  return detectorAsync.maybeWhen(
    data: (detector) => detector.labels,
    orElse: () => [],
  );
});

/// Provider para obtener el número de clases del modelo.
final detectorClassCountProvider = Provider<int>((ref) {
  final labels = ref.watch(detectorLabelsProvider);
  return labels.length;
});
