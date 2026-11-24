import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/perfil_usuario.dart';

// ==========================================================
// SERVICIO DE PERFILES AUTORIZADOS
// ==========================================================

/// Recupera los perfiles privados de autorización
/// almacenados en Cloud Firestore.
///
/// La aplicación consulta directamente el documento cuyo ID
/// coincide con el UID entregado por Firebase Authentication.
class PerfilUsuarioService {
  // ========================================================
  // INSTANCIA COMPARTIDA
  // ========================================================

  /// Instancia única utilizada por toda la aplicación.
  static final PerfilUsuarioService instancia = PerfilUsuarioService._interno();

  /// Constructor privado que evita crear instancias
  /// independientes accidentalmente.
  PerfilUsuarioService._interno();

  // ========================================================
  // FIRESTORE
  // ========================================================

  /// Instancia utilizada para consultar Cloud Firestore.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================================
  // CONSULTA DEL PERFIL
  // ========================================================

  /// Recupera el perfil correspondiente al UID autenticado.
  ///
  /// Devuelve `null` cuando:
  ///
  /// - El identificador está vacío.
  /// - El documento no existe.
  /// - Los datos no están disponibles.
  ///
  /// Los errores de conexión o permisos se propagan para que
  /// la interfaz pueda distinguirlos de una cuenta no autorizada.
  Future<PerfilUsuario?> obtenerPerfil(String usuarioId) async {
    final String idLimpio = usuarioId.trim();

    if (idLimpio.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> documento = await _firestore
        .collection('usuarios')
        .doc(idLimpio)
        .get();

    if (!documento.exists) {
      return null;
    }

    final Map<String, dynamic>? datos = documento.data();

    if (datos == null) {
      return null;
    }

    return PerfilUsuario.fromMap(id: documento.id, datos: datos);
  }
}
