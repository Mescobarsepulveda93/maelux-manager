import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/perfil_usuario.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../services/perfil_usuario_service.dart';
import '../data/insumos_repository.dart';

// ==========================================================
// CONTROL DE ACCESO DE MAELUX
// ==========================================================

/// Decide qué pantalla debe mostrarse según la autenticación
/// y la autorización administrativa del usuario.
///
/// El acceso requiere:
///
/// 1. Una sesión válida en Firebase Authentication.
/// 2. Un documento en `usuarios/{uid}`.
/// 3. Un perfil activo.
/// 4. Un rol reconocido por MAELUX.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // ========================================================
  // INTERFAZ
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instancia.cambiosDeSesion,
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
          return const _AuthLoadingScreen(mensaje: 'Comprobando sesión...');
        }

        final User? usuario = snapshot.data;

        // --------------------------------------------------
        // USUARIO SIN AUTENTICAR
        // --------------------------------------------------

        if (usuario == null) {
          return const LoginScreen();
        }

        // --------------------------------------------------
        // USUARIO AUTENTICADO
        // --------------------------------------------------

        // Después de verificar la identidad, se comprueba
        // el perfil privado almacenado en Firestore.
        return _PerfilGate(usuario: usuario);
      },
    );
  }
}

// ==========================================================
// COMPROBACIÓN DEL PERFIL AUTORIZADO
// ==========================================================

/// Consulta el documento privado del usuario autenticado
/// y comprueba su estado y su rol administrativo.
class _PerfilGate extends StatefulWidget {
  /// Usuario cuya autorización debe comprobarse.
  final User usuario;

  const _PerfilGate({required this.usuario});

  @override
  State<_PerfilGate> createState() => _PerfilGateState();
}

class _PerfilGateState extends State<_PerfilGate> {
  // ========================================================
  // SERVICIO DE PERFILES
  // ========================================================

  final PerfilUsuarioService perfilService = PerfilUsuarioService.instancia;

  // ========================================================
  // CONSULTA EN CURSO
  // ========================================================

  late Future<PerfilUsuario?> _perfilFuture;

  // ========================================================
  // INICIALIZACIÓN
  // ========================================================

  @override
  void initState() {
    super.initState();

    _consultarPerfil();
  }

  @override
  void didUpdateWidget(covariant _PerfilGate oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si cambia el usuario autenticado, se consulta
    // el perfil correspondiente al nuevo UID.
    if (oldWidget.usuario.uid != widget.usuario.uid) {
      _consultarPerfil();
    }
  }

  // ========================================================
  // CONSULTA DEL PERFIL
  // ========================================================

  /// Inicia o repite la lectura del perfil privado.
  void _consultarPerfil() {
    _perfilFuture = perfilService.obtenerPerfil(widget.usuario.uid);
  }

  /// Vuelve a consultar el perfil y reconstruye la pantalla.
  void _reintentar() {
    setState(() {
      _consultarPerfil();
    });
  }

  // ========================================================
  // INTERFAZ
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PerfilUsuario?>(
      future: _perfilFuture,
      builder: (context, snapshot) {
        // --------------------------------------------------
        // CONSULTA EN CURSO
        // --------------------------------------------------

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen(
            mensaje: 'Comprobando autorización...',
          );
        }

        // --------------------------------------------------
        // ERROR DE CONEXIÓN O PERMISOS
        // --------------------------------------------------

        if (snapshot.hasError) {
          return _PerfilErrorScreen(alReintentar: _reintentar);
        }

        final PerfilUsuario? perfil = snapshot.data;

        // --------------------------------------------------
        // PERFIL INEXISTENTE
        // --------------------------------------------------

        if (perfil == null) {
          return const _AccesoDenegadoScreen(
            titulo: 'Cuenta no autorizada',
            mensaje:
                'La cuenta inició sesión correctamente, '
                'pero no posee un perfil administrativo.',
          );
        }

        // --------------------------------------------------
        // PERFIL DESACTIVADO
        // --------------------------------------------------

        if (!perfil.activo) {
          return const _AccesoDenegadoScreen(
            titulo: 'Cuenta desactivada',
            mensaje:
                'Esta cuenta no tiene acceso habilitado '
                'al área administrativa de MAELUX.',
          );
        }

        // --------------------------------------------------
        // ROL DESCONOCIDO
        // --------------------------------------------------

        if (!perfil.tieneRolValido) {
          return const _AccesoDenegadoScreen(
            titulo: 'Rol no autorizado',
            mensaje:
                'La cuenta no tiene asignado un rol '
                'administrativo reconocido.',
          );
        }

        // --------------------------------------------------
        // ACCESO AUTORIZADO
        // --------------------------------------------------

        return _InsumosCloudGate(perfil: perfil);
      },
    );
  }
}

// ==========================================================
// CONEXIÓN DE DATOS COMPARTIDOS
// ==========================================================

/// Conecta los repositorios compartidos únicamente después
/// de validar la identidad, el estado y el rol del usuario.
class _InsumosCloudGate extends StatefulWidget {
  final PerfilUsuario perfil;

  const _InsumosCloudGate({required this.perfil});

  @override
  State<_InsumosCloudGate> createState() => _InsumosCloudGateState();
}

class _InsumosCloudGateState extends State<_InsumosCloudGate> {
  late Future<void> _conexionFuture;

  @override
  void initState() {
    super.initState();

    _conexionFuture = InsumosRepository.instancia.conectarConNube();
  }

  /// Reintenta la conexión con Firestore.
  void _reintentar() {
    setState(() {
      _conexionFuture = InsumosRepository.instancia.conectarConNube();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _conexionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen(mensaje: 'Sincronizando insumos...');
        }

        if (snapshot.hasError) {
          return _PerfilErrorScreen(alReintentar: _reintentar);
        }

        return const HomeScreen();
      },
    );
  }
}

// ==========================================================
// PANTALLA DE CARGA
// ==========================================================

/// Se muestra mientras Firebase comprueba la sesión
/// o Firestore recupera el perfil de autorización.
class _AuthLoadingScreen extends StatelessWidget {
  final String mensaje;

  const _AuthLoadingScreen({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),

              const SizedBox(height: 16),

              Text(mensaje, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// ACCESO DENEGADO
// ==========================================================

/// Se muestra cuando la cuenta está autenticada, pero no
/// tiene un perfil administrativo válido y activo.
class _AccesoDenegadoScreen extends StatelessWidget {
  final String titulo;
  final String mensaje;

  const _AccesoDenegadoScreen({required this.titulo, required this.mensaje});

  /// Cierra la sesión para permitir el acceso con otra cuenta.
  Future<void> _cerrarSesion(BuildContext context) async {
    final String? error = await AuthService.instancia.cerrarSesion();

    if (!context.mounted || error == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.gpp_bad_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        titulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(mensaje, textAlign: TextAlign.center),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            _cerrarSesion(context);
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('CERRAR SESIÓN'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// ERROR AL CONSULTAR EL PERFIL
// ==========================================================

/// Se muestra cuando Firestore no puede recuperar
/// correctamente el perfil privado.
class _PerfilErrorScreen extends StatelessWidget {
  final VoidCallback alReintentar;

  const _PerfilErrorScreen({required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'No fue posible comprobar tu perfil',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Revisa tu conexión a Internet '
                        'e inténtalo nuevamente.',
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: alReintentar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('REINTENTAR'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {
                            AuthService.instancia.cerrarSesion();
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('CERRAR SESIÓN'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// ERROR DE AUTENTICACIÓN
// ==========================================================

/// Se muestra si Firebase no puede determinar correctamente
/// el estado de Authentication.
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
