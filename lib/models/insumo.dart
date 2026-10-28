// ==========================================================
// MODELO DE INSUMO
// ==========================================================

/// Representa un material complementario utilizado para fabricar,
/// completar o presentar un producto de MAELUX.
///
/// Un insumo puede corresponder a packaging, stickers, adhesivos,
/// accesorios u otros elementos que no forman parte del filamento.
class Insumo {
  // ========================================================
  // IDENTIFICACIÓN
  // ========================================================

  /// Nombre comercial o descriptivo del insumo.
  final String nombre;

  /// Categoría utilizada para organizar los insumos.
  final String categoria;

  /// Unidad mediante la cual se controla el inventario.
  ///
  /// Ejemplos:
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

  /// Calcula automáticamente el costo correspondiente
  /// a una unidad del insumo.
  ///
  /// Ejemplo:
  ///
  /// $5.000 ÷ 100 bolsas = $50 por bolsa.
  double get costoUnitario {
    if (cantidadComprada <= 0) {
      return 0;
    }

    return costoCompra / cantidadComprada;
  }

  // ========================================================
  // COPIA Y ACTUALIZACIÓN
  // ========================================================

  /// Genera una copia del insumo reemplazando solamente
  /// los valores que necesitan modificarse.
  Insumo copiarCon({
    String? nombre,
    String? categoria,
    String? unidadMedida,
    double? costoCompra,
    double? cantidadComprada,
    bool? activo,
  }) {
    return Insumo(
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      costoCompra: costoCompra ?? this.costoCompra,
      cantidadComprada: cantidadComprada ?? this.cantidadComprada,
      activo: activo ?? this.activo,
    );
  }
}
