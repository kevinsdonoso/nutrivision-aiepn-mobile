// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                              main.dart                                        ║
// ║                     NutriVisionAIEPN Mobile                                   ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Punto de entrada de la aplicación Flutter.                                   ║
// ║  Configura el tema, navegación y pantalla inicial.                            ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'presentation/pages/detection_test_screen.dart';

void main() {
  // Asegurar que Flutter esté inicializado antes de cualquier operación
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación preferida (solo portrait para esta app)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar estilo de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const NutriVisionApp());
}

/// Aplicación principal NutriVisionAIEPN
class NutriVisionApp extends StatelessWidget {
  const NutriVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ═══════════════════════════════════════════════════════════════════════
      // CONFIGURACIÓN BÁSICA
      // ═══════════════════════════════════════════════════════════════════════
      title: 'NutriVision AI',
      debugShowCheckedModeBanner: false, // Ocultar banner de debug

      // ═══════════════════════════════════════════════════════════════════════
      // TEMA DE LA APLICACIÓN
      // ═══════════════════════════════════════════════════════════════════════
      theme: ThemeData(
        // Esquema de colores basado en verde (nutrición/salud)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // Verde Material
          brightness: Brightness.light,
        ),

        // Usar Material Design 3
        useMaterial3: true,

        // Configuración de AppBar
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),

        // Configuración de Cards
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // Configuración de botones elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // Tema oscuro (opcional, para futuro)
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      // Usar tema del sistema
      themeMode: ThemeMode.system,

      // ═══════════════════════════════════════════════════════════════════════
      // PANTALLA INICIAL
      // ═══════════════════════════════════════════════════════════════════════
      // Por ahora usamos la pantalla de prueba de detección
      // Después se reemplazará por la navegación completa con go_router
      home: const DetectionTestScreen(),
    );
  }
}
