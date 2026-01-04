// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         camera_controls.dart                                  ║
// ║              Controles de cámara para detección en tiempo real                ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Botones de captura, flash y cambio de cámara.                                ║
// ║  Se superpone sobre el preview de cámara.                                     ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Controles de cámara superpuestos sobre el preview.
class CameraControls extends StatelessWidget {
  /// Callback al presionar capturar. Null si está deshabilitado.
  final VoidCallback? onCapture;

  /// Callback al alternar flash. Null si está deshabilitado.
  final VoidCallback? onToggleFlash;

  /// Callback al cambiar cámara. Null si solo hay una cámara o está deshabilitado.
  final VoidCallback? onSwitchCamera;

  /// Indica si se está procesando (para mostrar indicador).
  final bool isProcessing;

  /// Estado actual del flash.
  final bool flashEnabled;

  /// Número de detecciones actuales.
  final int detectionCount;

  const CameraControls({
    super.key,
    this.onCapture,
    this.onToggleFlash,
    this.onSwitchCamera,
    this.isProcessing = false,
    this.flashEnabled = false,
    this.detectionCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withAlpha(180),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botón de flash
            _ControlButton(
              icon: flashEnabled ? Icons.flash_on : Icons.flash_off,
              label: 'Flash',
              isActive: flashEnabled,
              onPressed: onToggleFlash,
            ),

            // Botón de captura (principal)
            _CaptureButton(
              onPressed: onCapture,
              isProcessing: isProcessing,
            ),

            // Botón de cambiar cámara (siempre visible pero puede estar deshabilitado)
            _ControlButton(
              icon: Icons.cameraswitch,
              label: 'Cambiar',
              onPressed: onSwitchCamera,
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de control secundario (flash, cambiar cámara).
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isActive;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isDisabled
              ? Colors.white.withAlpha(10)
              : (isActive
                  ? AppColors.primaryGreen.withAlpha(50)
                  : Colors.white.withAlpha(30)),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDisabled
                      ? Colors.white.withAlpha(30)
                      : (isActive
                          ? AppColors.primaryGreen
                          : Colors.white.withAlpha(100)),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: isDisabled
                    ? Colors.white.withAlpha(50)
                    : (isActive ? AppColors.primaryGreen : Colors.white),
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Botón principal de captura.
class _CaptureButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isProcessing;

  const _CaptureButton({
    this.onPressed,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: (isProcessing || isDisabled) ? null : onPressed,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDisabled ? Colors.white38 : Colors.white,
                width: 4,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isProcessing
                    ? AppColors.primaryGreen.withAlpha(150)
                    : (isDisabled ? Colors.white38 : Colors.white),
              ),
              child: isProcessing
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.camera,
                      color: AppColors.primaryGreenDark,
                      size: 32,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Capturar',
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Widget para mostrar indicador de detecciones en tiempo real.
class DetectionIndicator extends StatelessWidget {
  final int count;

  const DetectionIndicator({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withAlpha(220),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$count detectado${count != 1 ? 's' : ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
