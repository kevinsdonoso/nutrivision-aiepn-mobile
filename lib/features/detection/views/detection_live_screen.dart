// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                       detection_live_screen.dart                              ║
// ║              Pantalla de detección de ingredientes en tiempo real             ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Implementa detección usando la cámara del dispositivo.                       ║
// ║  Muestra preview con overlay de bounding boxes.                               ║
// ║  Soporta configuracion de rendimiento ajustable en tiempo real.               ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/camera_settings.dart';
import '../services/detection_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/camera_provider.dart';
import '../providers/camera_settings_provider.dart';
import '../providers/detector_provider.dart';
import '../widgets/camera_controls.dart';
import '../widgets/camera_settings_panel.dart';
import '../widgets/detection_overlay.dart';
import 'detection_results_screen.dart';

/// Pantalla de detección de ingredientes en tiempo real desde cámara.
class CameraDetectionPage extends ConsumerStatefulWidget {
  const CameraDetectionPage({super.key});

  @override
  ConsumerState<CameraDetectionPage> createState() =>
      _CameraDetectionPageState();
}

class _CameraDetectionPageState extends ConsumerState<CameraDetectionPage>
    with WidgetsBindingObserver {
  // ═══════════════════════════════════════════════════════════════════════════
  // PROPIEDADES
  // ═══════════════════════════════════════════════════════════════════════════

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  // NUEVO: Controller centralizado para lazy loading
  late final DetectionController _detectionController;

  bool _isInitializingCamera = true;
  bool _isInitializingDetector = false;
  String? _errorMessage;

  // Estado para indicar que se esta capturando
  bool _isCapturing = false;

  // Contador de frames para logging periódico (FASE 3)
  int _frameCounter = 0;

  // Configuracion de rendimiento
  CameraResolution _currentResolution = CameraSettings.defaultResolution;

  // Métricas actuales (manejadas por controller)
  RuntimeMetrics _currentMetrics = RuntimeMetrics.empty();

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS DE ESTADO (Fuente única de verdad)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Indica si el modelo YOLO está cargado en memoria.
  bool get isModelLoaded => _detectionController.isInitialized;

  /// Indica si la detección está activa (stream + procesamiento).
  bool get isDetectionOn => _detectionController.isDetectionActive;

  /// Indica si el sistema está inicializando (cámara o detector).
  bool get isInitializing => _isInitializingCamera || _detectionController.isInitializing;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Crear controller y registrar callbacks
    _detectionController = DetectionController()
      ..registerCallbacks(
        onDetectionsUpdated: (detections, metrics) {
          if (mounted) {
            setState(() {
              _currentMetrics = metrics;
            });
            // También actualizar el provider para compatibilidad con widgets existentes
            ref.read(cameraStateProvider.notifier).updateDetections(
                  detections,
                  metrics.avgLatencyMs,
                );
          }
        },
        onError: (message) {
          if (mounted) {
            setState(() => _errorMessage = message);
            _showSnackBar(message, AppColors.error);
          }
        },
        onInitializingChanged: (isInitializing) {
          if (mounted) {
            setState(() => _isInitializingDetector = isInitializing);
          }
        },
      );

    // Inicializar SOLO la cámara (NO el detector)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Detener stream directamente SIN usar provider (evita error de ref)
    // No llamar _stopImageStream() porque usa ref.read() que ya está invalidado
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    _cameraController?.dispose();

    // Liberar TODOS los recursos del detector
    _detectionController.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // Pausar detección y detener stream (detector permanece en memoria)
        _detectionController.stopDetection();
        _stopImageStream();
        _cameraController?.dispose();
        _cameraController = null;
        break;
      case AppLifecycleState.resumed:
        // Reinicializar cámara (detector permanece en memoria)
        _initializeCamera();
        break;
      default:
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // Mostrar diálogo para abrir configuración
      if (mounted) {
        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permiso requerido'),
            content: const Text(
              'Se necesita acceso a la cámara para detectar ingredientes. '
              '¿Deseas abrir la configuración?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Abrir configuración'),
              ),
            ],
          ),
        );

        if (shouldOpen == true) {
          await openAppSettings();
        }
      }
      return false;
    }

    return false;
  }

  /// Inicializa SOLO la cámara (sin detector).
  Future<void> _initializeCamera({CameraResolution? resolution}) async {
    setState(() {
      _isInitializingCamera = true;
      _errorMessage = null;
    });

    final notifier = ref.read(cameraStateProvider.notifier);
    notifier.startInitializing();

    try {
      // 1. Verificar permisos
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        notifier.setPermissionDenied();
        setState(() {
          _isInitializingCamera = false;
          _errorMessage = 'Permiso de cámara denegado';
        });
        return;
      }

      // 2. Obtener cámaras disponibles
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _isInitializingCamera = false;
          _errorMessage = 'No se encontraron cámaras';
        });
        notifier.setError('No se encontraron cámaras');
        return;
      }

      // 3. Obtener resolución de la configuración si no se especifica
      if (resolution == null) {
        final settings = ref.read(cameraSettingsProvider).valueOrNull;
        resolution = settings?.resolution ?? CameraSettings.defaultResolution;
      }

      // Guardar la resolución actual para detectar cambios
      _currentResolution = resolution;

      // 4. Crear controller (cámara trasera por defecto)
      final cameraState = ref.read(cameraStateProvider);
      final cameraIndex = cameraState.isFrontCamera ? 1 : 0;
      final camera = _cameras![cameraIndex.clamp(0, _cameras!.length - 1)];

      _cameraController = CameraController(
        camera,
        resolution.toResolutionPreset(),
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitializingCamera = false;
        _errorMessage = null;
      });

      notifier.setReady();

      // 5. Iniciar stream de frames
      // ELIMINADO: await _startImageStream();
      // Stream se iniciará solo al presionar toggle ON (lazy loading)

      AppLogger.info('Cámara inicializada - Solo preview (sin stream)', tag: 'CameraDetection');
    } catch (e, stackTrace) {
      setState(() {
        _isInitializingCamera = false;
        _errorMessage = 'Error inicializando cámara: $e';
      });
      notifier.setError('Error inicializando cámara');

      AppLogger.error('Error inicializando cámara',
          tag: 'CameraDetection', error: e, stackTrace: stackTrace);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAMING DE FRAMES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _startImageStream() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isStreamingImages) {
      return;
    }

    final notifier = ref.read(cameraStateProvider.notifier);
    notifier.startStreaming();

    await _cameraController!.startImageStream(_onFrameAvailable);
  }

  void _stopImageStream() {
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
      // Evitar usar ref si el widget ya fue dispuesto
      if (mounted) {
        ref.read(cameraStateProvider.notifier).stopStreaming();
      }
    }
  }

  /// Callback que recibe cada frame de la cámara.
  Future<void> _onFrameAvailable(CameraImage cameraImage) async {
    // GUARD 1: No ejecutar si detección está OFF
    if (!_detectionController.isDetectionActive) {
      return; // Salir inmediatamente sin procesar
    }

    // GUARD 2: No procesar si está capturando foto
    if (_isCapturing) return;

    // FASE 3: Logging periódico de info de cámara (cada 60 frames)
    _frameCounter++;
    if (_frameCounter % 60 == 0) {
      final sensorOrientation =
          _cameraController?.description.sensorOrientation ?? 90;
      final lensDirection =
          _cameraController?.description.lensDirection.toString() ?? 'unknown';
      final cameraState = ref.read(cameraStateProvider);
      final settings = ref.read(cameraSettingsProvider).valueOrNull;
      final previewSize = _cameraController?.value.previewSize;

      AppLogger.tree(
        '📸 Camera Configuration (Frame #$_frameCounter)',
        [
          '📹 Lens: $lensDirection',
          '🔄 Sensor Rotation: $sensorOrientation°',
          '📐 Preview Size: ${previewSize?.width.toInt()}x${previewSize?.height.toInt()}',
          '⚙️  Resolution Setting: ${settings?.resolution.displayName ?? "unknown"} (${settings?.resolution.description ?? "unknown"})',
          '⏭️  Frame Skip: ${settings?.frameSkip ?? "unknown"} (procesa 1 de cada ${settings?.frameSkip ?? "?"} frames)',
          '🎚️  Confidence: ${settings != null ? settings.confidenceThreshold.toStringAsFixed(2) : "unknown"}',
          '🔲 IoU (NMS): ${settings != null ? settings.iouThreshold.toStringAsFixed(2) : "unknown"}',
          '🎯 Front Camera: ${cameraState.isFrontCamera}',
        ],
        tag: 'LiveDetection',
      );
    }

    // Delegar completamente al controller (incluye todos los guards)
    final settings = ref.read(cameraSettingsProvider).valueOrNull;
    final cameraState = ref.read(cameraStateProvider);
    final sensorOrientation =
        _cameraController?.description.sensorOrientation ?? 90;

    await _detectionController.processFrame(
      cameraImage,
      sensorOrientation: sensorOrientation,
      isFrontCamera: cameraState.isFrontCamera,
      frameSkip: settings?.frameSkip ?? CameraSettings.defaultFrameSkip,
      confidenceThreshold: settings?.confidenceThreshold ??
          CameraSettings.defaultConfidenceThreshold,
      iouThreshold: settings?.iouThreshold ?? CameraSettings.defaultIouThreshold,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCIONES DE USUARIO
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    final notifier = ref.read(cameraStateProvider.notifier);
    final cameraState = ref.read(cameraStateProvider);

    try {
      if (cameraState.flashEnabled) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      notifier.toggleFlash();
    } catch (e) {
      debugPrint('Error cambiando flash: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final notifier = ref.read(cameraStateProvider.notifier);

    _stopImageStream();
    await _cameraController?.dispose();

    notifier.toggleCamera();
    notifier.clearDetections();

    await _initializeCamera();
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    // Evitar multiples capturas simultaneas
    if (_isCapturing) return;

    try {
      setState(() {
        _isCapturing = true;
        _errorMessage = null;
      });

      // Pausar streaming durante la captura
      _stopImageStream();

      // Capturar imagen
      final xFile = await _cameraController!.takePicture();
      final file = File(xFile.path);

      // Leer y decodificar imagen
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      // Ejecutar detección usando el provider (para one-off detection)
      // NOTA: Esto cargará el detector si aún no está cargado
      final detector = await ref.read(yoloDetectorProvider.future);
      final detections = await detector.detect(image);

      if (!mounted) return;

      setState(() {
        _isCapturing = false;
      });

      // Navegar a pantalla de resultados
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetectionResultsScreen(
              imageFile: file,
              detections: detections,
              imageWidth: image.width,
              imageHeight: image.height,
              title: 'Resultados de Captura',
              retakeButtonText: 'Nueva Captura',
              showShareButton: false,
              onRetakePressed: () => Navigator.pop(context),
            ),
          ),
        );

        // Al volver de resultados, reiniciar streaming
        if (mounted) {
          await _startImageStream();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        _showSnackBar('Error al capturar: $e', AppColors.error);
        // Reiniciar streaming si hubo error
        await _startImageStream();
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  /// Toggle de detección (ON ↔ OFF).
  Future<void> _toggleLiveDetection() async {
    if (_detectionController.isDetectionActive) {
      // ═══════════════════════════════════════════════════════════
      // OFF: Detener TODO en orden
      // ═══════════════════════════════════════════════════════════

      // 1. Detener detección (cancela inferencias en curso)
      _detectionController.stopDetection();

      // 2. Detener stream de cámara
      _stopImageStream();

      // 3. Opcional: Liberar interpreter (omitido - mantener en memoria)
      // _disposeInterpreter();

      // 4. Limpiar UI y métricas
      if (mounted) {
        setState(() {
          _currentMetrics = RuntimeMetrics.empty();
        });
        ref.read(cameraStateProvider.notifier).clearDetections();
      }

      AppLogger.info('Detección DESACTIVADA (modelo en memoria)', tag: 'CameraDetection');

    } else {
      // ═══════════════════════════════════════════════════════════
      // ON: Activar TODO en orden
      // ═══════════════════════════════════════════════════════════

      // 1. Asegurar que interpreter está creado
      final success = await _ensureInterpreter();
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error cargando modelo de detección')),
          );
        }
        return;
      }

      // 2. Iniciar stream de cámara
      await _startImageStream();

      // 3. Activar detección
      await _detectionController.startDetection();

      AppLogger.info('Detección ACTIVADA', tag: 'CameraDetection');
    }
  }

  /// Asegura que el interpreter (modelo YOLO) está inicializado.
  ///
  /// Retorna `true` si el modelo está listo para detectar.
  Future<bool> _ensureInterpreter() async {
    if (_detectionController.isInitialized) {
      return true; // Ya cargado
    }

    try {
      // Mostrar indicador de carga si mounted
      if (mounted) {
        setState(() {
          _isInitializingCamera = true; // Reusar flag visual
        });
      }

      // Delegar al DetectionController para lazy loading
      // El controller internamente llama a _ensureDetectorInitialized()
      await _detectionController.startDetection();

      // Detener inmediatamente (solo queríamos inicializar)
      _detectionController.stopDetection();

      if (mounted) {
        setState(() {
          _isInitializingCamera = false;
        });
      }

      return _detectionController.isInitialized;
    } catch (e, stackTrace) {
      AppLogger.error('Error cargando interpreter',
          tag: 'CameraDetection', error: e, stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _isInitializingCamera = false;
        });
      }

      return false;
    }
  }

  Future<void> _openSettings() async {
    // Guardar la resolucion actual antes de abrir configuracion
    final previousResolution = _currentResolution;

    // Mostrar panel de configuracion
    final result = await showCameraSettingsPanel(context);

    // Si se aplicaron cambios, verificar si cambio la resolucion
    if (result == true && mounted) {
      final settings = ref.read(cameraSettingsProvider).valueOrNull;
      final newResolution =
          settings?.resolution ?? CameraSettings.defaultResolution;

      // Si cambio la resolucion, reinicializar la camara
      if (newResolution != previousResolution) {
        _stopImageStream();
        await _cameraController?.dispose();
        _cameraController = null;

        setState(() {
          _isInitializingCamera = true;
        });

        await _initializeCamera(resolution: newResolution);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // OPTIMIZACION: Usar providers granulares para evitar rebuilds innecesarios
    final cameraStatus = ref.watch(cameraStatusProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Volver',
          onPressed: () => context.goBackOrHome(),
        ),
        title: const Text(
          'Deteccion en vivo',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Toggle de deteccion en tiempo real
          _buildLiveDetectionToggle(),
          // FPS Badge ELIMINADO (duplicado con metrics overlay)
          // FPS se muestra SOLO en _buildMetricsOverlay
          // Boton de configuracion (bloqueado cuando detección ON)
          IconButton(
            icon: Icon(
              Icons.tune,
              color: isDetectionOn ? Colors.white38 : Colors.white,
            ),
            tooltip: isDetectionOn
                ? 'Detén la detección primero'
                : 'Configuración',
            onPressed: isDetectionOn ? null : _openSettings,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _buildBody(cameraStatus),
    );
  }

  Widget _buildLiveDetectionToggle() {
    final isActive = _detectionController.isDetectionActive;
    final isInitializing = _isInitializingDetector;

    return Tooltip(
      message: isInitializing
          ? 'Cargando modelo...'
          : (isActive
              ? 'Detección activa - Tap para pausar'
              : 'Detección pausada - Tap para activar'),
      child: InkWell(
        onTap: isInitializing ? null : _toggleLiveDetection,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryGreen.withAlpha(40)
                : Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? AppColors.primaryGreen : Colors.white54,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de carga o icono de radar
              if (isInitializing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                )
              else
                Icon(
                  isActive ? Icons.sensors : Icons.sensors_off,
                  color: isActive ? AppColors.primaryGreen : Colors.white54,
                  size: 18,
                ),
              const SizedBox(width: 6),
              // Texto descriptivo
              Text(
                isInitializing ? 'Cargando...' : (isActive ? 'ON' : 'OFF'),
                style: TextStyle(
                  color: isActive ? AppColors.primaryGreen : Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(CameraStatus cameraStatus) {
    // Estado de inicialización de cámara o detector
    if (_isInitializingCamera || _isInitializingDetector) {
      return _buildLoadingState();
    }

    // Error
    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    // Permiso denegado
    if (cameraStatus == CameraStatus.permissionDenied) {
      return _buildPermissionDeniedState();
    }

    // Cámara no inicializada
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return _buildLoadingState();
    }

    // Vista de cámara con overlay - usa widgets optimizados
    return _buildCameraView();
  }

  Widget _buildCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Preview de cámara (no depende del estado)
        _buildCameraPreview(),

        // Overlay de detecciones - Widget separado que escucha solo detections
        _DetectionOverlayWrapper(
          previewSize: MediaQuery.of(context).size,
          imageWidth:
              _cameraController!.value.previewSize?.height.toInt() ?? 640,
          imageHeight:
              _cameraController!.value.previewSize?.width.toInt() ?? 480,
        ),

        // Controles - Widget separado con su propio estado
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _CameraControlsWrapper(
            onCapture: isDetectionOn ? null : () => _captureAndAnalyze(),
            onToggleFlash: isDetectionOn ? null : _toggleFlash,
            onSwitchCamera: isDetectionOn
                ? null
                : (_cameras != null && _cameras!.length > 1 ? _switchCamera : null),
          ),
        ),

        // Badge de conteo de detecciones - Widget separado
        const _DetectionCountBadge(),

        // Badge de informacion de memoria - Widget separado
        _MemoryInfoBadge(isModelLoaded: isModelLoaded),

        // Badge de advertencia de resolución baja - Widget separado
        const _LowResolutionWarning(),

        // Overlay de métricas runtime (NEW)
        if (_detectionController.isDetectionActive &&
            _currentMetrics.totalFramesProcessed > 0)
          _buildMetricsOverlay(),
      ],
    );
  }

  /// Widget de overlay de métricas runtime.
  Widget _buildMetricsOverlay() {
    return Positioned(
      top: 180,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primaryGreen.withAlpha(100),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricRow(
              Icons.speed,
              'FPS',
              _currentMetrics.avgFps.toStringAsFixed(1),
            ),
            const SizedBox(height: 4),
            _buildMetricRow(
              Icons.timer,
              'Latency',
              '${_currentMetrics.avgLatencyMs}ms',
            ),
            const SizedBox(height: 4),
            _buildMetricRow(
              Icons.trending_up,
              'Confidence',
              '${(_currentMetrics.avgConfidence * 100).toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 4),
            _buildMetricRow(
              Icons.grid_on,
              'Frames',
              '${_currentMetrics.totalFramesProcessed}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 14),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null) {
      return const SizedBox.shrink();
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize?.height ?? 0,
            height: _cameraController!.value.previewSize?.width ?? 0,
            child: CameraPreview(_cameraController!),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryGreen,
          ),
          const SizedBox(height: 24),
          Text(
            _isInitializingDetector
                ? 'Cargando modelo de IA...'
                : 'Inicializando cámara...',
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withAlpha(200),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.white.withAlpha(150),
            ),
            const SizedBox(height: 24),
            const Text(
              'Permiso de camara requerido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Activa el permiso de camara en la configuracion '
              'para detectar ingredientes en tiempo real.',
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Abrir configuracion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go(AppConstants.routeHome),
              child: const Text(
                'Volver al inicio',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS OPTIMIZADOS (Consumer separados para evitar rebuilds)
// ═══════════════════════════════════════════════════════════════════════════════

// Badge de FPS ELIMINADO - duplicado con metrics overlay
// FPS se muestra SOLO en _buildMetricsOverlay para evitar inconsistencias

/// Wrapper del overlay que solo se reconstruye cuando cambian detecciones.
class _DetectionOverlayWrapper extends ConsumerWidget {
  final Size previewSize;
  final int imageWidth;
  final int imageHeight;

  const _DetectionOverlayWrapper({
    required this.previewSize,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detections = ref.watch(currentDetectionsProvider);
    final isFrontCamera = ref.watch(
      cameraStateProvider.select((state) => state.isFrontCamera),
    );

    if (detections.isEmpty) return const SizedBox.shrink();

    return DetectionOverlay(
      detections: detections,
      previewSize: previewSize,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      isFrontCamera: isFrontCamera,
    );
  }
}

/// Wrapper de controles que solo se reconstruye con su estado específico.
class _CameraControlsWrapper extends ConsumerWidget {
  final VoidCallback? onCapture;
  final VoidCallback? onToggleFlash;
  final VoidCallback? onSwitchCamera;

  const _CameraControlsWrapper({
    this.onCapture,
    this.onToggleFlash,
    this.onSwitchCamera,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(isProcessingProvider);
    final flashEnabled = ref.watch(
      cameraStateProvider.select((state) => state.flashEnabled),
    );
    final detectionCount = ref.watch(detectionCountProvider);

    return CameraControls(
      onCapture: onCapture,
      onToggleFlash: onToggleFlash,
      onSwitchCamera: onSwitchCamera,
      isProcessing: isProcessing,
      flashEnabled: flashEnabled,
      detectionCount: detectionCount,
    );
  }
}

/// Badge que muestra el conteo de detecciones.
class _DetectionCountBadge extends ConsumerWidget {
  const _DetectionCountBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(detectionCountProvider);

    if (count == 0) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withAlpha(200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$count ingrediente${count != 1 ? 's' : ''}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Badge que muestra informacion de memoria (opcional).
class _MemoryInfoBadge extends ConsumerWidget {
  final bool isModelLoaded; // ← NUEVO parámetro

  const _MemoryInfoBadge({required this.isModelLoaded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showMemoryInfo = ref.watch(showMemoryInfoProvider);

    // Mostrar SOLO si config habilitada Y modelo cargado
    if (!showMemoryInfo || !isModelLoaded) {
      return const SizedBox.shrink();
    }

    // Nota: En Flutter no hay acceso directo a la memoria del proceso,
    // esto es una estimacion aproximada basada en el heap de Dart
    return Positioned(
      top: 140,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.memory,
              color: Colors.white70,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'Modelo activo',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge de advertencia cuando la resolución es LOW.
class _LowResolutionWarning extends ConsumerWidget {
  const _LowResolutionWarning();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(cameraSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        // Solo mostrar si la resolución es LOW
        if (settings.resolution != CameraResolution.low) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 180,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade900.withAlpha(230),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.shade400,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange.shade200,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'RESOLUCIÓN BAJA (352x288) - Cambia a MEDIA (720x480) en ajustes ⚙️',
                    style: TextStyle(
                      color: Colors.orange.shade100,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
