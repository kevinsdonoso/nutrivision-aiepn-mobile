// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                              app.dart                                         ║
// ║                   Configuración principal de la aplicación                    ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Widget raíz que configura MaterialApp con tema, rutas y localización.        ║
// ║  Extraído de main.dart para mejor organización del código.                    ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/router/app_router.dart';

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
