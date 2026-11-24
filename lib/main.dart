import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/configuracion_cotizador_repository.dart';
import 'data/insumos_repository.dart';
import 'data/productos_repository.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_gate.dart';

// ==========================================================
// INICIALIZACIÓN DE MAELUX MANAGER
// ==========================================================

/// Punto de entrada principal de la aplicación.
///
/// Antes de construir la interfaz, inicializa el repositorio
/// para recuperar los insumos almacenados localmente.
Future<void> main() async {
  // Inicializa la comunicación entre Flutter y las
  // plataformas antes de utilizar complementos externos.
  WidgetsFlutterBinding.ensureInitialized();

  // Conecta MAELUX con la aplicación Firebase correspondiente
  // a la plataforma actual, Web o Android.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Mientras preparamos la migración a la nube, se mantienen
  // activos los repositorios locales existentes.
  await Future.wait([
    InsumosRepository.instancia.inicializar(),
    ConfiguracionCotizadorRepository.instancia.inicializar(),
    ProductosRepository.instancia.inicializar(),
  ]);

  runApp(const MaeluxApp());
}

// ==========================================================
// APLICACIÓN PRINCIPAL
// ==========================================================

/// Configura el tema, el título y la pantalla inicial
/// de MAELUX Manager.
class MaeluxApp extends StatelessWidget {
  const MaeluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MAELUX Manager',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
