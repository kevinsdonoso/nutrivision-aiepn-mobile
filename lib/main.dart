// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║                              main.dart                                        ║
// ║                     NutriVisionAIEPN Mobile                                   ║
// ╠═══════════════════════════════════════════════════════════════════════════════╣
// ║  Punto de entrada de la aplicación Flutter.                                   ║
// ║  Configura orientación, barra de estado y lanza la app con Riverpod.          ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

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
