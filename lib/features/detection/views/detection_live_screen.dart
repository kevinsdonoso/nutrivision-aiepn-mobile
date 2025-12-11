// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                       detection_live_screen.dart                              ║
// ║              Pantalla de detección de ingredientes en tiempo real             ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Implementa detección usando la cámara del dispositivo.                       ║
// ║  Muestra preview con overlay de bounding boxes.                               ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_constants.dart';
import '../services/camera_frame_processor.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/camera_provider.dart';
import '../providers/detector_provider.dart';
import '../widgets/camera_controls.dart';
import '../widgets/detection_overlay.dart';

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
  CameraFrameProcessor? _frameProcessor;

  bool _isInitializing = true;
  String? _errorMessage;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Diferir inicialización hasta después del primer frame
    // para evitar modificar providers durante build del widget tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAll();
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
        _stopImageStream();
        _cameraController?.dispose();
        _cameraController = null;
        break;
      case AppLifecycleState.resumed:
        _initializeCamera();
        break;
      default:
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _initializeAll() async {
    final notifier = ref.read(cameraStateProvider.notifier);
    notifier.startInitializing();

    // 1. Verificar permisos
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) {
      notifier.setPermissionDenied();
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Permiso de cámara denegado';
      });
      return;
    }

    // 2. Esperar e inicializar detector YOLO
    try {
      final detector = await ref.read(yoloDetectorProvider.future);
      _frameProcessor = CameraFrameProcessor(detector);
      await _initializeCamera();
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Error cargando modelo: $e';
      });
      notifier.setError('Error cargando modelo');
    }
  }

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

  Future<void> _initializeCamera() async {
    final notifier = ref.read(cameraStateProvider.notifier);

    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'No se encontraron cámaras';
        });
        notifier.setError('No se encontraron cámaras');
        return;
      }

      // Usar cámara trasera por defecto
      final cameraState = ref.read(cameraStateProvider);
      final cameraIndex = cameraState.isFrontCamera ? 1 : 0;
      final camera = _cameras![cameraIndex.clamp(0, _cameras!.length - 1)];

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium, // 720x480 - balance entre calidad y rendimiento
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage = null;
      });

      notifier.setReady();

      // Iniciar streaming automáticamente
      await _startImageStream();
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Error inicializando cámara: $e';
      });
      notifier.setError('Error inicializando cámara');
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

  Future<void> _onFrameAvailable(CameraImage cameraImage) async {
    if (_frameProcessor == null || _frameProcessor!.isBusy) return;

    final notifier = ref.read(cameraStateProvider.notifier);
    final cameraState = ref.read(cameraStateProvider);

    try {
      notifier.setProcessing(true);

      final sensorOrientation =
          _cameraController?.description.sensorOrientation ?? 90;

      final result = await _frameProcessor!.processFrame(
        cameraImage,
        sensorOrientation: sensorOrientation,
        isFrontCamera: cameraState.isFrontCamera,
      );

      if (result != null && mounted) {
        notifier.updateDetections(result.detections, result.inferenceTimeMs);
      }
    } catch (e) {
      // Ignorar errores de frames individuales para no interrumpir streaming
      debugPrint('Error procesando frame: $e');
    }
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

    try {
      _stopImageStream();

      final xFile = await _cameraController!.takePicture();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imagen capturada: ${xFile.path}'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }

      // Reiniciar streaming después de captura
      await _startImageStream();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // OPTIMIZACIÓN: Usar providers granulares para evitar rebuilds innecesarios
    // Solo el AppBar necesita FPS, el body se reconstruye por separado
    final cameraStatus = ref.watch(cameraStatusProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Volver',
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Detección en vivo',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // FPS Badge separado para no reconstruir todo el scaffold
          if (AppConstants.showDebugFps) const _FpsBadge(),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _buildBody(cameraStatus),
    );
  }

  Widget _buildBody(CameraStatus cameraStatus) {
    // Estado de inicialización
    if (_isInitializing) {
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
          imageWidth: _cameraController!.value.previewSize?.height.toInt() ?? 640,
          imageHeight: _cameraController!.value.previewSize?.width.toInt() ?? 480,
        ),

        // Controles - Widget separado con su propio estado
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _CameraControlsWrapper(
            onCapture: _captureAndAnalyze,
            onToggleFlash: _toggleFlash,
            onSwitchCamera: _cameras != null && _cameras!.length > 1
                ? _switchCamera
                : null,
          ),
        ),

        // Badge de conteo de detecciones - Widget separado
        const _DetectionCountBadge(),
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
            'Inicializando cámara...',
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
              onPressed: _initializeAll,
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
              'Permiso de cámara requerido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Activa el permiso de cámara en la configuración '
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
              label: const Text('Abrir configuración'),
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

/// Badge de FPS que solo se reconstruye cuando cambia el FPS.
class _FpsBadge extends ConsumerWidget {
  const _FpsBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fps = ref.watch(estimatedFpsProvider);

    if (fps <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${fps.toStringAsFixed(1)} FPS',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

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
  final VoidCallback onCapture;
  final VoidCallback onToggleFlash;
  final VoidCallback? onSwitchCamera;

  const _CameraControlsWrapper({
    required this.onCapture,
    required this.onToggleFlash,
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
