// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                    quantity_adjustment_dialog.dart                            ║
// ║                Diálogo para ajustar cantidad de ingrediente                   ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Permite al usuario seleccionar porciones estándar o ingresar gramos.         ║
// ║  Actualiza el estado de cantidades en tiempo real.                            ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/ingredient_quantity.dart';
import '../../../data/models/standard_portion.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/quantity_provider.dart';
import '../state/ingredient_quantities_notifier.dart';

/// Diálogo para ajustar la cantidad de un ingrediente.
///
/// Permite dos formas de ajuste:
/// 1. Selección de porción estándar (si disponible)
/// 2. Input manual en gramos
///
/// Ejemplo de uso:
/// ```dart
/// await showDialog(
///   context: context,
///   builder: (context) => QuantityAdjustmentDialog(
///     ingredientLabel: 'tomate',
///     currentQuantity: quantity,
///   ),
/// );
/// ```
class QuantityAdjustmentDialog extends ConsumerStatefulWidget {
  /// Etiqueta del ingrediente a ajustar.
  final String ingredientLabel;

  /// Cantidad actual (puede ser null para nuevo ingrediente).
  final IngredientQuantity? currentQuantity;

  const QuantityAdjustmentDialog({
    super.key,
    required this.ingredientLabel,
    this.currentQuantity,
  });

  @override
  ConsumerState<QuantityAdjustmentDialog> createState() =>
      _QuantityAdjustmentDialogState();
}

class _QuantityAdjustmentDialogState
    extends ConsumerState<QuantityAdjustmentDialog> {
  late TextEditingController _gramsController;
  StandardPortion? _selectedPortion;
  bool _isManualMode = false;

  @override
  void initState() {
    super.initState();
    final initialGrams =
        widget.currentQuantity?.grams ?? IngredientQuantity.defaultGrams;
    _gramsController = TextEditingController(
      text: initialGrams.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  void _updateQuantity(double grams) {
    final notifier = ref.read(ingredientQuantitiesProvider.notifier);
    notifier.updateQuantityGrams(widget.ingredientLabel, grams);
  }

  void _updateFromPortion(StandardPortion portion) {
    final notifier = ref.read(ingredientQuantitiesProvider.notifier);
    notifier.updateQuantityFromPortion(widget.ingredientLabel, portion);
    setState(() {
      _selectedPortion = portion;
      _gramsController.text = portion.grams.toStringAsFixed(0);
      _isManualMode = false;
    });
  }

  void _saveAndClose() {
    // Validar y guardar cantidad manual
    final grams = double.tryParse(_gramsController.text);
    if (grams != null && IngredientQuantitiesNotifier.isValidGrams(grams)) {
      _updateQuantity(grams);
      Navigator.of(context).pop(true);
    } else {
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cantidad inválida. Debe estar entre ${IngredientQuantity.minGrams}g y ${IngredientQuantity.maxGrams}g',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portionsAsync =
        ref.watch(availablePortionsProvider(widget.ingredientLabel));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.scale, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ajustar Cantidad',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.ingredientLabel.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withAlpha(230), // 0.9 * 255 ≈ 230
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Input manual de gramos
                    _buildManualInput(theme),
                    const SizedBox(height: 24),

                    // Porciones estándar (si disponible)
                    portionsAsync.when(
                      data: (portions) => portions.isNotEmpty
                          ? _buildPortionsSection(portions, theme)
                          : const SizedBox.shrink(),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // Footer con botones
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GradientButton.primary(
                      text: 'Guardar',
                      icon: Icons.check,
                      onPressed: _saveAndClose,
                      size: GradientButtonSize.medium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit, size: 20, color: Color(0xFF4CAF50)),
            const SizedBox(width: 8),
            Text(
              'Cantidad en gramos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _gramsController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (_) => setState(() => _isManualMode = true),
          decoration: InputDecoration(
            hintText: 'Ej: 150',
            suffixText: 'g',
            suffixStyle: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rango válido: ${IngredientQuantity.minGrams.toInt()}g - ${IngredientQuantity.maxGrams.toInt()}g',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPortionsSection(
      List<StandardPortion> portions, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.restaurant_menu,
                size: 20, color: Color(0xFFFF9800)),
            const SizedBox(width: 8),
            Text(
              'Porciones estándar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              portions.map((portion) => _buildPortionChip(portion)).toList(),
        ),
      ],
    );
  }

  Widget _buildPortionChip(StandardPortion portion) {
    final isSelected = _selectedPortion == portion && !_isManualMode;

    return FilterChip(
      label: Text(portion.displayName),
      selected: isSelected,
      onSelected: (_) => _updateFromPortion(portion),
      selectedColor: const Color(0xFFFF9800).withAlpha(51), // 0.2 * 255 ≈ 51
      checkmarkColor: const Color(0xFFFF9800),
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFFF9800) : Colors.grey[800],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFFFF9800) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }
}
