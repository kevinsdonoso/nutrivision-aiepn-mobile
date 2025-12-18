// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                       detection_live_screen.dart                              ║
// ║              Pantalla de detección de ingredientes en tiempo real             ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Implementa detección usando la cámara del dispositivo.                       ║
// ║  Muestra preview con overlay de bounding boxes.                               ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/detection.dart';
import '../services/camera_frame_processor.dart';
import '../services/yolo_detector.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/camera_provider.dart';
import '../providers/detector_provider.dart';
import '../widgets/camera_controls.dart';
import '../widgets/detection_overlay.dart';
import '../../nutrition/providers/nutrition_provider.dart';
import '../../nutrition/widgets/nutrition_card.dart';

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
  YoloDetector? _detector;

  bool _isInitializing = true;
  String? _errorMessage;

  // Estado para deteccion en tiempo real
  // NOTA: Inicia desactivada para que el usuario controle cuando activarla
  bool _liveDetectionEnabled = false;

  // Estado para captura y resultados
  bool _showCaptureResults = false;
  File? _capturedImage;
  List<Detection> _capturedDetections = [];
  int _capturedImageWidth = 0;
  int _capturedImageHeight = 0;

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
      _detector = await ref.read(yoloDetectorProvider.future);
      _frameProcessor = CameraFrameProcessor(_detector!);
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
    // Si la deteccion live esta deshabilitada o mostrando resultados, no procesar
    if (!_liveDetectionEnabled || _showCaptureResults) return;
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

    if (_detector == null) {
      _showSnackBar('Detector no inicializado', AppColors.error);
      return;
    }

    try {
      // Pausar streaming
      _stopImageStream();

      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      // Capturar imagen
      final xFile = await _cameraController!.takePicture();
      final file = File(xFile.path);

      // Leer y decodificar imagen
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      // Ejecutar deteccion
      final detections = await _detector!.detect(image);

      if (!mounted) return;

      // Guardar resultados
      setState(() {
        _isInitializing = false;
        _showCaptureResults = true;
        _capturedImage = file;
        _capturedDetections = detections;
        _capturedImageWidth = image.width;
        _capturedImageHeight = image.height;
      });

      // Inicializar cantidades para nutricion
      ref.read(ingredientQuantitiesProvider.notifier).setFromDetections(detections);

      if (detections.isEmpty) {
        _showSnackBar('No se detectaron ingredientes', AppColors.warning);
      } else {
        _showSnackBar('Detectados ${detections.length} ingredientes', AppColors.primaryGreen);
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
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

  void _dismissCaptureResults() {
    setState(() {
      _showCaptureResults = false;
      _capturedImage = null;
      _capturedDetections = [];
    });
    // Limpiar detecciones del provider
    ref.read(cameraStateProvider.notifier).clearDetections();
    // Reiniciar streaming
    _startImageStream();
  }

  void _toggleLiveDetection() {
    setState(() {
      _liveDetectionEnabled = !_liveDetectionEnabled;
    });
    if (!_liveDetectionEnabled) {
      // Limpiar detecciones cuando se desactiva
      ref.read(cameraStateProvider.notifier).clearDetections();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Si estamos mostrando resultados de captura, mostrar esa pantalla
    if (_showCaptureResults) {
      return _buildCaptureResultsScreen();
    }

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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Deteccion en vivo',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Toggle de deteccion en tiempo real
          _buildLiveDetectionToggle(),
          // FPS Badge separado para no reconstruir todo el scaffold
          if (AppConstants.showDebugFps && _liveDetectionEnabled) const _FpsBadge(),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _buildBody(cameraStatus),
    );
  }

  Widget _buildLiveDetectionToggle() {
    return Tooltip(
      message: _liveDetectionEnabled
          ? 'Deteccion activa - Tap para pausar'
          : 'Deteccion pausada - Tap para activar',
      child: InkWell(
        onTap: _toggleLiveDetection,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: _liveDetectionEnabled
                ? AppColors.primaryGreen.withAlpha(40)
                : Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _liveDetectionEnabled
                  ? AppColors.primaryGreen
                  : Colors.white54,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de radar para indicar deteccion
              Icon(
                _liveDetectionEnabled ? Icons.sensors : Icons.sensors_off,
                color: _liveDetectionEnabled
                    ? AppColors.primaryGreen
                    : Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 6),
              // Texto descriptivo
              Text(
                _liveDetectionEnabled ? 'ON' : 'OFF',
                style: TextStyle(
                  color: _liveDetectionEnabled
                      ? AppColors.primaryGreen
                      : Colors.white54,
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

  // ═══════════════════════════════════════════════════════════════════════════════
  // PANTALLA DE RESULTADOS DE CAPTURA
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildCaptureResultsScreen() {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver a camara',
          onPressed: _dismissCaptureResults,
        ),
        title: const Text('Resultados de Captura'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Nueva captura',
            onPressed: _dismissCaptureResults,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen capturada con bounding boxes
            if (_capturedImage != null) _buildCapturedImageCard(),
            const SizedBox(height: 16),

            // Resumen de detecciones
            _buildDetectionSummary(theme),
            const SizedBox(height: 16),

            // Lista de ingredientes
            if (_capturedDetections.isNotEmpty) ...[
              _buildIngredientsList(theme),
              const SizedBox(height: 24),

              // Seccion nutricional
              _buildNutritionSection(theme),
            ],

            const SizedBox(height: 24),

            // Boton para nueva captura
            ElevatedButton.icon(
              onPressed: _dismissCaptureResults,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Nueva Captura'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturedImageCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.file(
            _capturedImage!,
            fit: BoxFit.contain,
            width: double.infinity,
          ),
          if (_capturedDetections.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: _CapturedImageBoundingBoxPainter(
                  detections: _capturedDetections,
                  imageWidth: _capturedImageWidth,
                  imageHeight: _capturedImageHeight,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetectionSummary(ThemeData theme) {
    final stats = _capturedDetections.stats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              _capturedDetections.isEmpty ? Icons.search_off : Icons.check_circle,
              size: 48,
              color: _capturedDetections.isEmpty ? Colors.grey : AppColors.primaryGreen,
            ),
            const SizedBox(height: 8),
            Text(
              _capturedDetections.isEmpty
                  ? 'No se detectaron ingredientes'
                  : 'Detectados ${stats.total} ingredientes (${stats.uniqueIngredients} unicos)',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (_capturedDetections.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Confianza promedio: ${(stats.averageConfidence * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsList(ThemeData theme) {
    final grouped = _capturedDetections.groupByLabel();
    final sortedLabels = grouped.keys.toList()
      ..sort((a, b) => grouped[b]!.length.compareTo(grouped[a]!.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredientes Detectados',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...sortedLabels.map((label) {
          final detections = grouped[label]!;
          final avgConfidence = detections
              .map((d) => d.confidence)
              .reduce((a, b) => a + b) / detections.length;

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getConfidenceColor(avgConfidence),
                child: Text(
                  detections.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                label.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Confianza: ${(avgConfidence * 100).toStringAsFixed(1)}%',
              ),
              trailing: Icon(
                avgConfidence >= 0.7
                    ? Icons.check_circle
                    : avgConfidence >= 0.5
                        ? Icons.help
                        : Icons.warning,
                color: _getConfidenceColor(avgConfidence),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNutritionSection(ThemeData theme) {
    final uniqueLabels = _capturedDetections.uniqueLabels.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.restaurant_menu, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Informacion Nutricional',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...uniqueLabels.map((label) => _buildNutritionCardForLabel(label)),
      ],
    );
  }

  Widget _buildNutritionCardForLabel(String label) {
    final nutritionAsync = ref.watch(nutritionByLabelProvider(label));

    return nutritionAsync.when(
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(label.replaceAll('_', ' ')),
            ],
          ),
        ),
      ),
      error: (e, _) => NutritionNotFoundCard(label: label),
      data: (nutrition) {
        if (nutrition == null) {
          return NutritionNotFoundCard(label: label);
        }
        final detectionsForLabel = _capturedDetections.filterByLabel(label);
        final avgConfidence = detectionsForLabel.isNotEmpty
            ? detectionsForLabel
                    .map((d) => d.confidence)
                    .reduce((a, b) => a + b) /
                detectionsForLabel.length
            : null;

        return NutritionCard(
          nutrition: nutrition,
          confidence: avgConfidence,
        );
      },
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAINTER PARA IMAGEN CAPTURADA
// ═══════════════════════════════════════════════════════════════════════════════

class _CapturedImageBoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final int imageWidth;
  final int imageHeight;

  _CapturedImageBoundingBoxPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty || imageWidth <= 0 || imageHeight <= 0) return;

    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final detection in detections) {
      Color boxColor;
      if (detection.isHighConfidence) {
        boxColor = Colors.green;
      } else if (detection.isMediumConfidence) {
        boxColor = Colors.orange;
      } else {
        boxColor = Colors.red;
      }

      strokePaint.color = boxColor;

      final double x1 = detection.x1 * scaleX;
      final double y1 = detection.y1 * scaleY;
      final double x2 = detection.x2 * scaleX;
      final double y2 = detection.y2 * scaleY;

      if (x1.isNaN || y1.isNaN || x2.isNaN || y2.isNaN) continue;
      if (x2 <= x1 || y2 <= y1) continue;

      final rect = Rect.fromLTRB(x1, y1, x2, y2);
      canvas.drawRect(rect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CapturedImageBoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections;
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
