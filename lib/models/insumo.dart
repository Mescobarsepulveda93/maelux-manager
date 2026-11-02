// ==========================================================
// MODELO DE INSUMO
// ==========================================================

/// Representa un material complementario utilizado para fabricar,
/// completar o presentar un producto de MAELUX.
///
/// Cada insumo posee un identificador estable que permite
/// reconocerlo aunque sus demás datos sean modificados.
///
/// El modelo también puede convertirse a un mapa y reconstruirse
/// posteriormente desde el almacenamiento local.
class Insumo {
  // ========================================================
  // IDENTIFICACIÓN
  // ========================================================

  /// Identificador único y permanente del insumo.
  final String id;

  /// Nombre comercial o descriptivo del insumo.
  final String nombre;

  /// Categoría utilizada para organizar los insumos.
  final String categoria;

  /// Unidad mediante la cual se controla el inventario.
  ///
  /// Ejemplos:
  ///
  /// - unidad
  /// - metro
  /// - mililitro
  /// - gramo
  final String unidadMedida;

  // ========================================================
  // INFORMACIÓN DE COMPRA
  // ========================================================

  /// Importe total pagado por la compra.
  final double costoCompra;

  /// Cantidad total recibida en la compra.
  final double cantidadComprada;

  // ========================================================
  // ESTADO DEL INSUMO
  // ========================================================

  /// Indica si el insumo puede seleccionarse en el cotizador.
  final bool activo;

  const Insumo({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.unidadMedida,
    required this.costoCompra,
    required this.cantidadComprada,
    this.activo = true,
  });

  // ========================================================
  // VALORES CALCULADOS
  // ========================================================

  /// Calcula automáticamente el coste correspondiente
  /// a una unidad del insumo.
  ///
  /// Fórmula:
  ///
  /// coste total de compra ÷ cantidad comprada.
  double get costoUnitario {
    if (cantidadComprada <= 0 ||
        !cantidadComprada.isFinite ||
        !costoCompra.isFinite) {
      return 0;
    }

    return costoCompra / cantidadComprada;
  }

  // ========================================================
  // SERIALIZACIÓN
  // ========================================================

  /// Convierte el insumo en un mapa que puede serializarse
  /// y guardarse posteriormente en el almacenamiento local.
  ///
  /// El coste unitario no se guarda porque puede calcularse
  /// nuevamente utilizando el coste y la cantidad comprada.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'unidadMedida': unidadMedida,
      'costoCompra': costoCompra,
      'cantidadComprada': cantidadComprada,
      'activo': activo,
    };
  }

  /// Construye un insumo a partir de un mapa recuperado
  /// desde el almacenamiento local.
  ///
  /// Se aplican valores seguros cuando algún dato opcional
  /// no se encuentra disponible.
  factory Insumo.fromMap(Map<String, dynamic> mapa) {
    return Insumo(
      id: mapa['id']?.toString() ?? '',
      nombre: mapa['nombre']?.toString() ?? '',
      categoria: mapa['categoria']?.toString() ?? 'Otros',
      unidadMedida: mapa['unidadMedida']?.toString() ?? 'unidad',
      costoCompra: _convertirADouble(mapa['costoCompra']),
      cantidadComprada: _convertirADouble(mapa['cantidadComprada']),
      activo: mapa['activo'] is bool ? mapa['activo'] as bool : true,
    );
  }

  // ========================================================
  // COPIA Y ACTUALIZACIÓN
  // ========================================================

  /// Genera una copia del insumo reemplazando solamente
  /// los valores indicados.
  ///
  /// El identificador se conserva de forma predeterminada.
  Insumo copiarCon({
    String? id,
    String? nombre,
    String? categoria,
    String? unidadMedida,
    double? costoCompra,
    double? cantidadComprada,
    bool? activo,
  }) {
    return Insumo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      costoCompra: costoCompra ?? this.costoCompra,
      cantidadComprada: cantidadComprada ?? this.cantidadComprada,
      activo: activo ?? this.activo,
    );
  }

  // ========================================================
  // CONVERSIONES INTERNAS
  // ========================================================

  /// Convierte un valor dinámico en un número decimal.
  ///
  /// Esta protección permite recuperar correctamente números
  /// almacenados como `int`, `double` o texto numérico.
  static double _convertirADouble(dynamic valor) {
    if (valor is double) {
      return valor;
    }

    if (valor is int) {
      return valor.toDouble();
    }

    if (valor is num) {
      return valor.toDouble();
    }

    if (valor is String) {
      return double.tryParse(valor.replaceAll(',', '.')) ?? 0;
    }

    return 0;
  }
}
