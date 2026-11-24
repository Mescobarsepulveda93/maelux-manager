// ==========================================================
// PERFIL PRIVADO DE USUARIO
// ==========================================================

/// Representa la autorización administrativa asociada
/// a una cuenta autenticada en MAELUX.
///
/// La identidad principal procede de Firebase Authentication.
/// Este modelo conserva únicamente la información necesaria
/// para decidir el acceso y los permisos internos.
class PerfilUsuario {
  // ========================================================
  // IDENTIFICACIÓN
  // ========================================================

  /// UID asignado por Firebase Authentication.
  final String id;

  /// Nombre utilizado dentro del área administrativa.
  final String nombre;

  // ========================================================
  // AUTORIZACIÓN
  // ========================================================

  /// Rol administrativo asignado a la persona usuaria.
  ///
  /// Valores previstos:
  ///
  /// - administrador
  /// - vendedor
  /// - produccion
  final String rol;

  /// Indica si la cuenta puede acceder actualmente
  /// al área administrativa.
  final bool activo;

  const PerfilUsuario({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.activo,
  });

  // ========================================================
  // PERMISOS CALCULADOS
  // ========================================================

  /// Indica si el perfil tiene el rol de administrador.
  bool get esAdministrador {
    return rol == 'administrador';
  }

  /// Indica si el perfil corresponde a un vendedor.
  bool get esVendedor {
    return rol == 'vendedor';
  }

  /// Indica si el perfil corresponde al área de producción.
  bool get esProduccion {
    return rol == 'produccion';
  }

  /// Indica si el rol pertenece a los perfiles reconocidos
  /// actualmente por MAELUX.
  bool get tieneRolValido {
    return esAdministrador || esVendedor || esProduccion;
  }

  /// Indica si el perfil puede acceder al área privada.
  bool get tieneAcceso {
    return activo && tieneRolValido;
  }

  // ========================================================
  // CONSTRUCCIÓN DESDE FIRESTORE
  // ========================================================

  /// Construye un perfil utilizando el identificador
  /// del documento y sus datos almacenados en Firestore.
  factory PerfilUsuario.fromMap({
    required String id,
    required Map<String, dynamic> datos,
  }) {
    return PerfilUsuario(
      id: id,
      nombre: datos['nombre']?.toString().trim() ?? '',
      rol: datos['rol']?.toString().trim().toLowerCase() ?? '',
      activo: datos['activo'] is bool ? datos['activo'] as bool : false,
    );
  }
}
