import 'insumo.dart';

// ==========================================================
// MODELO DE INSUMO UTILIZADO EN UNA COTIZACIÓN
// ==========================================================

/// Representa un insumo seleccionado para formar parte
/// del cálculo de una cotización.
///
/// El modelo conserva el insumo original y la cantidad
/// utilizada para fabricar o presentar una unidad del producto.
///
/// Ejemplo:
///
/// Insumo: Bolsa transparente.
///
/// Cantidad utilizada: 1 unidad.
///
/// Costo unitario: $50.
///
/// Costo total aplicado: $50.
class InsumoCotizacion {
  // ========================================================
  // DATOS DEL INSUMO SELECCIONADO
  // ========================================================

  /// Insumo registrado en el repositorio de MAELUX.
  final Insumo insumo;

  /// Cantidad del insumo utilizada para fabricar o presentar
  /// una unidad del producto cotizado.
  ///
  /// Puede contener valores decimales. Por ejemplo:
  ///
  /// - 1 unidad.
  /// - 2 stickers.
  /// - 0,5 mililitros de adhesivo.
  /// - 1,25 metros de cinta.
  final double cantidadUtilizada;

  const InsumoCotizacion({
    required this.insumo,
    required this.cantidadUtilizada,
  });

  // ========================================================
  // VALORES CALCULADOS
  // ========================================================

  /// Calcula el coste del insumo aplicado a una unidad
  /// del producto cotizado.
  ///
  /// Fórmula:
  ///
  /// costo unitario del insumo × cantidad utilizada.
  double get costoTotal {
    if (cantidadUtilizada <= 0) {
      return 0;
    }

    return insumo.costoUnitario * cantidadUtilizada;
  }

  // ========================================================
  // COPIA Y ACTUALIZACIÓN
  // ========================================================

  /// Genera una copia del registro reemplazando únicamente
  /// los valores indicados.
  InsumoCotizacion copiarCon({Insumo? insumo, double? cantidadUtilizada}) {
    return InsumoCotizacion(
      insumo: insumo ?? this.insumo,
      cantidadUtilizada: cantidadUtilizada ?? this.cantidadUtilizada,
    );
  }
}
