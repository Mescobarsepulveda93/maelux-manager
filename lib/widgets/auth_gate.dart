import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';

// ==========================================================
// CONTROL DE ACCESO DE MAELUX
// ==========================================================

/// Decide qué pantalla debe mostrarse según el estado
/// actual de Firebase Authentication.
///
/// - Sin sesión activa: muestra [LoginScreen].
/// - Con sesión activa: muestra [HomeScreen].
///
/// La interfaz se actualiza automáticamente cuando el usuario
/// inicia o cierra sesión.
class AuthGate extends StatelessWidget {
  // ========================================================
  // SERVICIO DE AUTENTICACIÓN
  // ========================================================

  /// Servicio compartido utilizado para observar la sesión.
  final AuthService authService = AuthService.instancia;

  AuthGate({super.key});

  // ========================================================
  // INTERFAZ
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.cambiosDeSesion,
      builder: (context, snapshot) {
        // --------------------------------------------------
        // ERROR DE AUTENTICACIÓN
        // --------------------------------------------------

        if (snapshot.hasError) {
          return const _AuthErrorScreen();
        }

        // --------------------------------------------------
        // RESTAURACIÓN DE LA SESIÓN
        // --------------------------------------------------

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        // --------------------------------------------------
        // USUARIO SIN AUTENTICAR
        // --------------------------------------------------

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // --------------------------------------------------
        // USUARIO AUTENTICADO
        // --------------------------------------------------

        return const HomeScreen();
      },
    );
  }
}

// ==========================================================
// PANTALLA DE CARGA DE AUTENTICACIÓN
// ==========================================================

/// Se muestra mientras Firebase restaura las credenciales
/// guardadas de una sesión anterior.
class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),

              SizedBox(height: 16),

              Text('Comprobando acceso...', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// PANTALLA DE ERROR DE AUTENTICACIÓN
// ==========================================================

/// Se muestra si Firebase no puede determinar correctamente
/// el estado de la sesión.
class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64),

                  SizedBox(height: 16),

                  Text(
                    'No fue posible comprobar el acceso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Revisa tu conexión e inténtalo nuevamente.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
