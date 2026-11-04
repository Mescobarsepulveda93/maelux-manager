import 'package:flutter/material.dart';

import 'data/configuracion_cotizador_repository.dart';
import 'data/insumos_repository.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

// ==========================================================
// INICIALIZACIÓN DE MAELUX MANAGER
// ==========================================================

/// Punto de entrada principal de la aplicación.
///
/// Antes de construir la interfaz, inicializa el repositorio
/// para recuperar los insumos almacenados localmente.
Future<void> main() async {
  // Inicializa la comunicación entre Flutter y los complementos
  // de plataforma antes de utilizar shared_preferences.
  WidgetsFlutterBinding.ensureInitialized();

  // Se cargan simultáneamente los datos que necesita
  // la aplicación antes de construir la interfaz.
  await Future.wait([
    InsumosRepository.instancia.inicializar(),
    ConfiguracionCotizadorRepository.instancia.inicializar(),
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
      home: const HomeScreen(),
    );
  }
}
