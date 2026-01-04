// =====================================================================================
// ||                       camera_settings_panel.dart                               ||
// ||              Panel de configuracion de camara para deteccion                   ||
// =====================================================================================
// ||  Widget BottomSheet que permite ajustar parametros de rendimiento en tiempo    ||
// ||  real. Incluye controles para frame skip, resolucion, confianza y debug.       ||
// =====================================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/camera_settings.dart';
import '../providers/camera_settings_provider.dart';

/// Panel de configuracion de camara.
///
/// Se muestra como un BottomSheet modal con opciones para ajustar
/// parametros de rendimiento de la deteccion en tiempo real.
///
/// Uso:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => const CameraSettingsPanel(),
/// );
/// ```
class CameraSettingsPanel extends ConsumerWidget {
  const CameraSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(cameraSettingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : AppColors.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: settingsAsync.when(
        loading: () => const _LoadingPanel(),
        error: (error, _) => _ErrorPanel(error: error.toString()),
        data: (settings) => _SettingsContent(settings: settings),
      ),
    );
  }
}

/// Contenido principal del panel de configuracion.
class _SettingsContent extends ConsumerStatefulWidget {
  final CameraSettings settings;

  const _SettingsContent({required this.settings});

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  late CameraSettings _localSettings;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _localSettings = widget.settings;
  }

  void _updateSetting(CameraSettings newSettings) {
    setState(() {
      _localSettings = newSettings;
      _hasChanges = _localSettings != widget.settings;
    });
  }

  Future<void> _saveSettings() async {
    await ref
        .read(cameraSettingsProvider.notifier)
        .updateSettings(_localSettings);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _resetToDefaults() async {
    final defaults =
        await ref.read(cameraSettingsProvider.notifier).resetToDefaults();
    setState(() {
      _localSettings = defaults;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle del BottomSheet
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Titulo
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: AppColors.primaryGreen,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Configuracion de Camara',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                // Boton cerrar
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  tooltip: 'Cerrar',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ======== SECCION: RENDIMIENTO ========
            _SectionHeader(
              icon: Icons.speed,
              title: 'Rendimiento',
            ),
            const SizedBox(height: 12),

            // Frame Skip
            _FrameSkipSlider(
              value: _localSettings.frameSkip,
              onChanged: (value) {
                _updateSetting(_localSettings.copyWith(frameSkip: value));
              },
            ),

            const SizedBox(height: 16),

            // Resolucion
            _ResolutionSelector(
              value: _localSettings.resolution,
              onChanged: (resolution) {
                _updateSetting(_localSettings.copyWith(resolution: resolution));
              },
            ),

            const SizedBox(height: 24),

            // ======== SECCION: DETECCION ========
            _SectionHeader(
              icon: Icons.center_focus_strong,
              title: 'Deteccion',
            ),
            const SizedBox(height: 12),

            // Umbral de confianza
            _ConfidenceSlider(
              value: _localSettings.confidenceThreshold,
              onChanged: (value) {
                _updateSetting(
                    _localSettings.copyWith(confidenceThreshold: value));
              },
            ),

            const SizedBox(height: 16),

            // Umbral IoU
            _IouThresholdSlider(
              value: _localSettings.iouThreshold,
              onChanged: (value) {
                _updateSetting(_localSettings.copyWith(iouThreshold: value));
              },
            ),

            const SizedBox(height: 24),

            // ======== SECCION: VISUALIZACION ========
            _SectionHeader(
              icon: Icons.visibility,
              title: 'Visualizacion',
            ),
            const SizedBox(height: 12),

            // Toggle FPS
            _SettingToggle(
              icon: Icons.timer,
              title: 'Mostrar FPS',
              subtitle: 'Muestra frames por segundo en pantalla',
              value: _localSettings.showFps,
              onChanged: (value) {
                _updateSetting(_localSettings.copyWith(showFps: value));
              },
            ),

            const SizedBox(height: 8),

            // Toggle Memoria
            _SettingToggle(
              icon: Icons.memory,
              title: 'Mostrar Memoria',
              subtitle: 'Muestra uso aproximado de memoria',
              value: _localSettings.showMemoryInfo,
              onChanged: (value) {
                _updateSetting(_localSettings.copyWith(showMemoryInfo: value));
              },
            ),

            const SizedBox(height: 24),

            // ======== BOTONES DE ACCION ========
            Row(
              children: [
                // Restaurar valores por defecto
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _localSettings.isDefault ? null : _resetToDefaults,
                    icon: const Icon(Icons.restore),
                    label: const Text('Restaurar'),
                  ),
                ),
                const SizedBox(width: 12),
                // Aplicar cambios
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _hasChanges ? _saveSettings : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Aplicar'),
                  ),
                ),
              ],
            ),

            // Espacio adicional para dispositivos con barra de navegacion
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

/// Header de seccion.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primaryGreen,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.primaryGreen,
          ),
        ),
        const Expanded(child: SizedBox()),
        Container(
          height: 1,
          width: 100,
          color: AppColors.primaryGreen.withAlpha(50),
        ),
      ],
    );
  }
}

/// Slider para frame skip.
class _FrameSkipSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _FrameSkipSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.skip_next,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 8),
                Text(
                  'Procesar cada',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$value frame${value != 1 ? 's' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Slider(
          value: value.toDouble(),
          min: CameraSettings.minFrameSkip.toDouble(),
          max: CameraSettings.maxFrameSkip.toDouble(),
          divisions: CameraSettings.maxFrameSkip - CameraSettings.minFrameSkip,
          activeColor: AppColors.primaryGreen,
          inactiveColor: AppColors.primaryGreen.withAlpha(50),
          onChanged: (v) => onChanged(v.round()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mayor precision',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Text(
                'Mejor rendimiento',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Selector de resolucion.
class _ResolutionSelector extends StatelessWidget {
  final CameraResolution value;
  final ValueChanged<CameraResolution> onChanged;

  const _ResolutionSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.high_quality,
              size: 20,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              'Resolucion de camara',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: CameraResolution.values.map((resolution) {
            final isSelected = resolution == value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: resolution != CameraResolution.values.last ? 8 : 0,
                ),
                child: _ResolutionChip(
                  resolution: resolution,
                  isSelected: isSelected,
                  onTap: () => onChanged(resolution),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Chip de resolucion individual.
class _ResolutionChip extends StatelessWidget {
  final CameraResolution resolution;
  final bool isSelected;
  final VoidCallback onTap;

  const _ResolutionChip({
    required this.resolution,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen
              : (isDark ? Colors.white10 : Colors.black.withAlpha(10)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen
                : (isDark ? Colors.white24 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              resolution.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              resolution.description,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: isSelected
                    ? Colors.white70
                    : (isDark ? Colors.white38 : Colors.black38),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Slider para umbral de confianza.
class _ConfidenceSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _ConfidenceSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percentage = (value * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 8),
                Text(
                  'Confianza minima',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getConfidenceColor(value).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$percentage%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getConfidenceColor(value),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Slider(
          value: value,
          min: CameraSettings.minConfidence,
          max: CameraSettings.maxConfidence,
          divisions: 10,
          activeColor: _getConfidenceColor(value),
          inactiveColor: _getConfidenceColor(value).withAlpha(50),
          onChanged: onChanged,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mas detecciones',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Text(
                'Mayor precision',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return AppColors.confidenceHigh;
    if (confidence >= 0.5) return AppColors.confidenceMedium;
    return AppColors.confidenceLow;
  }
}

/// Slider para umbral IoU (Non-Maximum Suppression).
class _IouThresholdSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _IouThresholdSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percentage = (value * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grid_on,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 8),
                Text(
                  'IoU (NMS)',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getIouColor(value).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$percentage%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getIouColor(value),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Slider(
          value: value,
          min: CameraSettings.minIouThreshold,
          max: CameraSettings.maxIouThreshold,
          divisions: 6,
          activeColor: _getIouColor(value),
          inactiveColor: _getIouColor(value).withAlpha(50),
          onChanged: onChanged,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mas agresivo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Text(
                'Mas detecciones',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getIouColor(double iou) {
    if (iou <= 0.25) return AppColors.secondaryOrange;
    if (iou <= 0.35) return AppColors.primaryGreen;
    return AppColors.confidenceMedium;
  }
}

/// Toggle para opciones booleanas.
class _SettingToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: value
                ? AppColors.primaryGreen
                : (isDark ? Colors.white38 : Colors.black38),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primaryGreen.withAlpha(180),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primaryGreen;
              }
              return null;
            }),
          ),
        ],
      ),
    );
  }
}

/// Panel de carga.
class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }
}

/// Panel de error.
class _ErrorPanel extends StatelessWidget {
  final String error;

  const _ErrorPanel({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error cargando configuracion',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

/// Muestra el panel de configuracion como BottomSheet.
///
/// Retorna true si se aplicaron cambios, false o null en caso contrario.
Future<bool?> showCameraSettingsPanel(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const CameraSettingsPanel(),
  );
}
