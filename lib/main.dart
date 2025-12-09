// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                              main.dart                                        ║
// ║                     NutriVisionAIEPN Mobile                                   ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Punto de entrada de la aplicación Flutter.                                   ║
// ║  Configura el tema, navegación con go_router y Riverpod.                      ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

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

  // Ejecutar la aplicación envuelta en ProviderScope para Riverpod
  runApp(
    const ProviderScope(
      child: NutriVisionApp(),
    ),
  );
}

/// Aplicación principal NutriVisionAIEPN
class NutriVisionApp extends StatelessWidget {
  const NutriVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // ═══════════════════════════════════════════════════════════════════════
      // CONFIGURACIÓN BÁSICA
      // ═══════════════════════════════════════════════════════════════════════
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ═══════════════════════════════════════════════════════════════════════
      // NAVEGACIÓN CON GO_ROUTER
      // ═══════════════════════════════════════════════════════════════════════
      routerConfig: appRouter,

      // ═══════════════════════════════════════════════════════════════════════
      // TEMA DE LA APLICACIÓN
      // ═══════════════════════════════════════════════════════════════════════
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}
