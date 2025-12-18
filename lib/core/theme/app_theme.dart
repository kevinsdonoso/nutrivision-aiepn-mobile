// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                         app_theme.dart                                        ║
// ║              Sistema de temas para NutriVisionAIEPN                           ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Define la paleta de colores, tipografía y ThemeData para la aplicación.      ║
// ║  Soporta tema claro y oscuro siguiendo Material Design 3.                     ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colores de la aplicación NutriVision.
abstract class AppColors {
  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES PRIMARIOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Verde principal - representa nutrición y salud
  static const Color primaryGreen = Color(0xFF4CAF50);

  /// Verde oscuro para énfasis
  static const Color primaryGreenDark = Color(0xFF388E3C);

  /// Verde claro para fondos sutiles
  static const Color primaryGreenLight = Color(0xFFC8E6C9);

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES SECUNDARIOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Naranja para acciones secundarias y alertas suaves
  static const Color secondaryOrange = Color(0xFFFF9800);

  /// Naranja oscuro
  static const Color secondaryOrangeDark = Color(0xFFF57C00);

  /// Naranja claro
  static const Color secondaryOrangeLight = Color(0xFFFFE0B2);

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES DE ESTADO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Rojo para errores
  static const Color error = Color(0xFFE53935);

  /// Verde para éxito
  static const Color success = Color(0xFF43A047);

  /// Amarillo para advertencias
  static const Color warning = Color(0xFFFFA000);

  /// Azul para información
  static const Color info = Color(0xFF1E88E5);

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES DE CONFIANZA (Detecciones)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Alta confianza (>= 70%)
  static const Color confidenceHigh = Color(0xFF4CAF50);

  /// Confianza media (50-70%)
  static const Color confidenceMedium = Color(0xFFFF9800);

  /// Baja confianza (< 50%)
  static const Color confidenceLow = Color(0xFFE53935);

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES NEUTROS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fondo claro
  static const Color backgroundLight = Color(0xFFF5F5F5);

  /// Superficie blanca
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  /// Gris para textos secundarios
  static const Color textSecondary = Color(0xFF757575);

  /// Gris oscuro para textos primarios
  static const Color textPrimary = Color(0xFF212121);

  /// Divisores
  static const Color divider = Color(0xFFBDBDBD);

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES PARA MODO OSCURO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fondo oscuro
  static const Color backgroundDark = Color(0xFF121212);

  /// Superficie oscura
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// Superficie elevada oscura (cards, dialogs)
  static const Color surfaceDarkElevated = Color(0xFF2C2C2C);

  /// Superficie contenedor oscura
  static const Color surfaceContainerDark = Color(0xFF252525);

  /// Texto claro para modo oscuro
  static const Color textLightPrimary = Color(0xFFE0E0E0);

  /// Texto secundario claro
  static const Color textLightSecondary = Color(0xFFBDBDBD);

  /// Divisor oscuro
  static const Color dividerDark = Color(0xFF424242);

  /// Verde primario adaptado para modo oscuro (mas brillante)
  static const Color primaryGreenDarkMode = Color(0xFF66BB6A);

  /// Fondo de chips en modo oscuro
  static const Color chipBackgroundDark = Color(0xFF2E3B2E);
}

/// Configuración de temas de la aplicación.
abstract class AppTheme {
  // ═══════════════════════════════════════════════════════════════════════════
  // TEMA CLARO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tema claro de la aplicación
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Esquema de colores
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        brightness: Brightness.light,
        primary: AppColors.primaryGreen,
        secondary: AppColors.secondaryOrange,
        error: AppColors.error,
        surface: AppColors.surfaceWhite,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.backgroundLight,

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.surfaceWhite,
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.primaryGreen, width: 2),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Tipografía
      textTheme: _buildTextTheme(Brightness.light),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryGreenLight,
        labelStyle: GoogleFonts.poppins(
          color: AppColors.primaryGreenDark,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMA OSCURO
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tema oscuro de la aplicacion
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Esquema de colores
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        brightness: Brightness.dark,
        primary: AppColors.primaryGreenDarkMode,
        onPrimary: Colors.black,
        secondary: AppColors.secondaryOrange,
        onSecondary: Colors.black,
        error: AppColors.error,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textLightPrimary,
        onSurfaceVariant: AppColors.textLightSecondary,
        surfaceContainerHighest: AppColors.surfaceDarkElevated,
        outline: AppColors.dividerDark,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.backgroundDark,

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textLightPrimary,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textLightPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textLightPrimary,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.surfaceDarkElevated,
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.primaryGreen, width: 2),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textLightSecondary.withAlpha(100)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textLightSecondary.withAlpha(100)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.textLightSecondary.withAlpha(50),
        thickness: 1,
        space: 1,
      ),

      // Tipografia
      textTheme: _buildTextTheme(Brightness.dark),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textLightPrimary,
        size: 24,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipBackgroundDark,
        labelStyle: GoogleFonts.poppins(
          color: AppColors.primaryGreenDarkMode,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryGreenDarkMode,
        unselectedItemColor: AppColors.textLightSecondary,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceDarkElevated,
        contentTextStyle: GoogleFonts.poppins(
          color: AppColors.textLightPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDarkElevated,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textLightPrimary,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textLightPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ListTile Theme
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textLightSecondary,
        textColor: AppColors.textLightPrimary,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryGreenDarkMode;
          }
          return AppColors.textLightSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryGreenDarkMode.withAlpha(100);
          }
          return AppColors.surfaceContainerDark;
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIPOGRAFÍA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Construye el TextTheme usando Google Fonts
  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color primaryColor = brightness == Brightness.light
        ? AppColors.textPrimary
        : AppColors.textLightPrimary;
    final Color secondaryColor = brightness == Brightness.light
        ? AppColors.textSecondary
        : AppColors.textLightSecondary;

    return TextTheme(
      // Display
      displayLarge: GoogleFonts.poppins(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: primaryColor,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: primaryColor,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: primaryColor,
      ),

      // Headline
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),

      // Title
      titleLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),

      // Body
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primaryColor,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primaryColor,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),

      // Label
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
    );
  }
}

/// Extensión para acceso rápido a colores de confianza.
extension ConfidenceColorExtension on double {
  /// Obtiene el color correspondiente al nivel de confianza.
  Color get confidenceColor {
    if (this >= 0.70) return AppColors.confidenceHigh;
    if (this >= 0.50) return AppColors.confidenceMedium;
    return AppColors.confidenceLow;
  }
}
