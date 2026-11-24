import 'package:firebase_auth/firebase_auth.dart';
import '../data/insumos_repository.dart';

// ==========================================================
// SERVICIO DE AUTENTICACIÓN DE MAELUX
// ==========================================================

/// Centraliza las operaciones relacionadas con el acceso
/// privado al área administrativa de MAELUX.
///
/// Las cuentas administrativas se crean inicialmente desde
/// Firebase Console. La aplicación no permite registrar
/// públicamente nuevos usuarios.
class AuthService {
  // ========================================================
  // INSTANCIA COMPARTIDA
  // ========================================================

  /// Instancia única utilizada por toda la aplicación.
  static final AuthService instancia = AuthService._interno();

  /// Constructor privado para impedir que se creen
  /// servicios de autenticación independientes.
  AuthService._interno();

  // ========================================================
  // FIREBASE AUTHENTICATION
  // ========================================================

  /// Instancia de Firebase responsable de las sesiones.
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // ========================================================
  // CONSULTAS DE SESIÓN
  // ========================================================

  /// Emite el usuario actual cada vez que cambia
  /// el estado de autenticación.
  ///
  /// Devuelve `null` cuando no existe una sesión activa.
  Stream<User?> get cambiosDeSesion {
    return _firebaseAuth.authStateChanges();
  }

  /// Devuelve el usuario autenticado actualmente.
  ///
  /// Devuelve `null` cuando nadie ha iniciado sesión.
  User? get usuarioActual {
    return _firebaseAuth.currentUser;
  }

  /// Indica si existe una sesión activa.
  bool get haySesionActiva {
    return usuarioActual != null;
  }

  // ========================================================
  // INICIO DE SESIÓN
  // ========================================================

  /// Intenta iniciar sesión mediante correo electrónico
  /// y contraseña.
  ///
  /// Si Firebase rechaza la operación, devuelve un mensaje
  /// comprensible para mostrar en la interfaz.
  Future<String?> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final String correoLimpio = correo.trim().toLowerCase();

    if (correoLimpio.isEmpty || contrasena.isEmpty) {
      return 'Introduce el correo y la contraseña.';
    }

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: correoLimpio,
        password: contrasena,
      );

      return null;
    } on FirebaseAuthException catch (error) {
      return _traducirError(error);
    } catch (_) {
      return 'No fue posible iniciar sesión. '
          'Inténtalo nuevamente.';
    }
  }

  // ========================================================
  // CIERRE DE SESIÓN
  // ========================================================

  /// Cierra la sesión del usuario actual.
  Future<String?> cerrarSesion() async {
    try {
      // Detiene primero las escuchas privadas de Firestore.
      await InsumosRepository.instancia.desconectarDeNube();

      // Después elimina la sesión de Firebase Authentication.
      await _firebaseAuth.signOut();

      return null;
    } on FirebaseAuthException catch (error) {
      return _traducirError(error);
    } catch (_) {
      return 'No fue posible cerrar la sesión.';
    }
  }

  // ========================================================
  // RECUPERACIÓN DE CONTRASEÑA
  // ========================================================

  /// Envía un correo para restablecer la contraseña.
  ///
  /// Por seguridad, la interfaz puede mostrar un mensaje
  /// general aunque la cuenta no exista.
  Future<String?> enviarRecuperacion({required String correo}) async {
    final String correoLimpio = correo.trim().toLowerCase();

    if (correoLimpio.isEmpty) {
      return 'Introduce tu correo electrónico.';
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: correoLimpio);

      return null;
    } on FirebaseAuthException catch (error) {
      return _traducirError(error);
    } catch (_) {
      return 'No fue posible enviar el correo '
          'de recuperación.';
    }
  }

  // ========================================================
  // TRADUCCIÓN DE ERRORES
  // ========================================================

  /// Convierte los códigos técnicos de Firebase en mensajes
  /// comprensibles para las personas usuarias.
  String _traducirError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';

      case 'user-disabled':
        return 'Esta cuenta se encuentra deshabilitada.';

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'El correo o la contraseña no son correctos.';

      case 'too-many-requests':
        return 'Se realizaron demasiados intentos. '
            'Espera unos minutos antes de volver a intentarlo.';

      case 'network-request-failed':
        return 'No fue posible conectar con el servicio. '
            'Revisa tu conexión a Internet.';

      case 'operation-not-allowed':
        return 'El método de acceso no está habilitado.';

      case 'weak-password':
        return 'La contraseña no cumple los requisitos '
            'mínimos de seguridad.';

      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';

      default:
        return 'No fue posible completar la operación.';
    }
  }
}
