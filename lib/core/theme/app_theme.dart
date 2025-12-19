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

/// Extension para acceso rapido a colores de confianza.
extension ConfidenceColorExtension on double {
  /// Obtiene el color correspondiente al nivel de confianza.
  Color get confidenceColor {
    if (this >= 0.70) return AppColors.confidenceHigh;
    if (this >= 0.50) return AppColors.confidenceMedium;
    return AppColors.confidenceLow;
  }
}

// =============================================================================
// ICONOGRAFIA CONSISTENTE
// =============================================================================

/// Iconos estandarizados de la aplicacion.
///
/// Define todos los iconos usados en la aplicacion para mantener
/// consistencia visual y facilitar cambios futuros.
///
/// Ejemplo de uso:
/// ```dart
/// Icon(AppIcons.detection.camera)
/// Icon(AppIcons.nutrition.calories)
/// ```
abstract class AppIcons {
  // ===========================================================================
  // NAVEGACION
  // ===========================================================================

  /// Iconos de navegacion.
  static const navigation = _NavigationIcons();

  // ===========================================================================
  // DETECCION
  // ===========================================================================

  /// Iconos relacionados con deteccion.
  static const detection = _DetectionIcons();

  // ===========================================================================
  // NUTRICION
  // ===========================================================================

  /// Iconos de nutricion.
  static const nutrition = _NutritionIcons();

  // ===========================================================================
  // PERFIL
  // ===========================================================================

  /// Iconos de perfil y usuario.
  static const profile = _ProfileIcons();

  // ===========================================================================
  // ACCIONES
  // ===========================================================================

  /// Iconos de acciones generales.
  static const actions = _ActionIcons();

  // ===========================================================================
  // ESTADO
  // ===========================================================================

  /// Iconos de estado y feedback.
  static const status = _StatusIcons();
}

/// Iconos de navegacion.
class _NavigationIcons {
  const _NavigationIcons();

  /// Retroceder.
  IconData get back => Icons.arrow_back;

  /// Cerrar.
  IconData get close => Icons.close;

  /// Menu.
  IconData get menu => Icons.menu;

  /// Inicio.
  IconData get home => Icons.home_outlined;

  /// Inicio activo.
  IconData get homeActive => Icons.home;

  /// Configuracion.
  IconData get settings => Icons.settings_outlined;

  /// Configuracion activo.
  IconData get settingsActive => Icons.settings;

  /// Mas opciones.
  IconData get more => Icons.more_vert;

  /// Expandir.
  IconData get expand => Icons.expand_more;

  /// Contraer.
  IconData get collapse => Icons.expand_less;

  /// Siguiente.
  IconData get next => Icons.chevron_right;

  /// Anterior.
  IconData get previous => Icons.chevron_left;
}

/// Iconos de deteccion.
class _DetectionIcons {
  const _DetectionIcons();

  /// Camara.
  IconData get camera => Icons.camera_alt_outlined;

  /// Camara activo.
  IconData get cameraActive => Icons.camera_alt;

  /// Galeria.
  IconData get gallery => Icons.photo_library_outlined;

  /// Galeria activo.
  IconData get galleryActive => Icons.photo_library;

  /// Deteccion activa.
  IconData get detectionOn => Icons.radar;

  /// Deteccion inactiva.
  IconData get detectionOff => Icons.radar_outlined;

  /// Escanear.
  IconData get scan => Icons.document_scanner_outlined;

  /// Flash encendido.
  IconData get flashOn => Icons.flash_on;

  /// Flash apagado.
  IconData get flashOff => Icons.flash_off;

  /// Flash automatico.
  IconData get flashAuto => Icons.flash_auto;

  /// Cambiar camara.
  IconData get switchCamera => Icons.cameraswitch_outlined;

  /// Capturar.
  IconData get capture => Icons.camera;

  /// Zoom.
  IconData get zoom => Icons.zoom_in;

  /// Ingrediente detectado.
  IconData get ingredient => Icons.egg_outlined;

  /// Plato detectado.
  IconData get dish => Icons.restaurant;
}

/// Iconos de nutricion.
class _NutritionIcons {
  const _NutritionIcons();

  /// Calorias.
  IconData get calories => Icons.local_fire_department;

  /// Proteinas.
  IconData get protein => Icons.fitness_center;

  /// Grasas.
  IconData get fat => Icons.water_drop;

  /// Carbohidratos.
  IconData get carbs => Icons.grain;

  /// Fibra.
  IconData get fiber => Icons.grass;

  /// Sodio.
  IconData get sodium => Icons.science_outlined;

  /// Porcion.
  IconData get portion => Icons.pie_chart_outline;

  /// Gramos.
  IconData get grams => Icons.scale;

  /// Meta nutricional.
  IconData get goal => Icons.flag_outlined;

  /// Meta cumplida.
  IconData get goalReached => Icons.flag;

  /// Informacion nutricional.
  IconData get info => Icons.info_outline;
}

/// Iconos de perfil y usuario.
class _ProfileIcons {
  const _ProfileIcons();

  /// Usuario.
  IconData get user => Icons.person_outlined;

  /// Usuario activo.
  IconData get userActive => Icons.person;

  /// Editar perfil.
  IconData get edit => Icons.edit_outlined;

  /// Email.
  IconData get email => Icons.email_outlined;

  /// Fecha de nacimiento.
  IconData get birthday => Icons.cake_outlined;

  /// Genero.
  IconData get gender => Icons.wc_outlined;

  /// Ubicacion.
  IconData get location => Icons.location_on_outlined;

  /// Peso.
  IconData get weight => Icons.monitor_weight_outlined;

  /// Altura.
  IconData get height => Icons.height;

  /// IMC.
  IconData get bmi => Icons.speed_outlined;

  /// Actividad fisica.
  IconData get activity => Icons.directions_run_outlined;

  /// Perfil verificado.
  IconData get verified => Icons.verified;

  /// Perfil incompleto.
  IconData get incomplete => Icons.account_circle_outlined;

  /// Cerrar sesion.
  IconData get logout => Icons.logout;
}

/// Iconos de acciones generales.
class _ActionIcons {
  const _ActionIcons();

  /// Agregar.
  IconData get add => Icons.add;

  /// Eliminar.
  IconData get delete => Icons.delete_outlined;

  /// Guardar.
  IconData get save => Icons.save_outlined;

  /// Compartir.
  IconData get share => Icons.share_outlined;

  /// Descargar.
  IconData get download => Icons.download_outlined;

  /// Subir.
  IconData get upload => Icons.upload_outlined;

  /// Refrescar.
  IconData get refresh => Icons.refresh;

  /// Buscar.
  IconData get search => Icons.search;

  /// Filtrar.
  IconData get filter => Icons.filter_list;

  /// Ordenar.
  IconData get sort => Icons.sort;

  /// Copiar.
  IconData get copy => Icons.copy_outlined;

  /// Pegar.
  IconData get paste => Icons.paste_outlined;

  /// Deshacer.
  IconData get undo => Icons.undo;

  /// Rehacer.
  IconData get redo => Icons.redo;

  /// Favorito.
  IconData get favorite => Icons.favorite_border;

  /// Favorito activo.
  IconData get favoriteActive => Icons.favorite;

  /// Ayuda.
  IconData get help => Icons.help_outline;
}

/// Iconos de estado y feedback.
class _StatusIcons {
  const _StatusIcons();

  /// Exito.
  IconData get success => Icons.check_circle;

  /// Exito outlined.
  IconData get successOutlined => Icons.check_circle_outline;

  /// Error.
  IconData get error => Icons.error;

  /// Error outlined.
  IconData get errorOutlined => Icons.error_outline;

  /// Advertencia.
  IconData get warning => Icons.warning_amber_rounded;

  /// Informacion.
  IconData get info => Icons.info;

  /// Informacion outlined.
  IconData get infoOutlined => Icons.info_outline;

  /// Cargando.
  IconData get loading => Icons.hourglass_empty;

  /// Sin conexion.
  IconData get offline => Icons.wifi_off;

  /// Conectado.
  IconData get online => Icons.wifi;

  /// Sincronizando.
  IconData get syncing => Icons.sync;

  /// Bloqueado.
  IconData get locked => Icons.lock_outlined;

  /// Desbloqueado.
  IconData get unlocked => Icons.lock_open_outlined;

  /// Visible.
  IconData get visible => Icons.visibility;

  /// Oculto.
  IconData get hidden => Icons.visibility_off;

  /// Tiempo.
  IconData get time => Icons.access_time;

  /// Calendario.
  IconData get calendar => Icons.calendar_today_outlined;
}
