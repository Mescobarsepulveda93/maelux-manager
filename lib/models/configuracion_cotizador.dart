// ==========================================================
// CONFIGURACIÓN PERSISTENTE DEL COTIZADOR
// ==========================================================

/// Representa los supuestos productivos, financieros
/// y tributarios utilizados por el cotizador de MAELUX.
///
/// La configuración puede convertirse a un mapa para guardarse
/// localmente y reconstruirse al iniciar la aplicación.
class ConfiguracionCotizador {
  // ========================================================
  // SUPUESTOS DE PRODUCCIÓN
  // ========================================================

  /// Precio cobrado por cada kilowatt-hora consumido.
  final double costoKwh;

  /// Consumo promedio de la impresora durante una hora.
  final double consumoImpresoraKwh;

  /// Coste por hora destinado a desgaste, mantenimiento
  /// y amortización de la impresora.
  final double desgasteHora;

  /// Porcentaje destinado a cubrir errores, pérdidas
  /// y repeticiones de impresión.
  final double margenErrorPorcentaje;

  // ========================================================
  // SUPUESTOS FINANCIEROS
  // ========================================================

  /// Total mensual asociado a servicios bancarios
  /// y otros gastos financieros recurrentes.
  final double gastosBancariosMensuales;

  /// Cantidad estimada de unidades vendidas durante el mes.
  final int unidadesMensualesEstimadas;

  // ========================================================
  // SUPUESTOS TRIBUTARIOS
  // ========================================================

  /// Porcentaje de IVA aplicado a la venta del producto.
  final double ivaProductoPorcentaje;

  // ========================================================
  // SUPUESTOS DE TARJETA
  // ========================================================

  /// Porcentaje aplicado a las transacciones con tarjeta.
  final double comisionTarjetaPorcentaje;

  /// Cargo fijo por transacción expresado en UF.
  final double cargoFijoTarjetaUf;

  /// Valor manual de respaldo para convertir UF a pesos.
  final double valorUf;

  const ConfiguracionCotizador({
    required this.costoKwh,
    required this.consumoImpresoraKwh,
    required this.desgasteHora,
    required this.margenErrorPorcentaje,
    required this.gastosBancariosMensuales,
    required this.unidadesMensualesEstimadas,
    required this.ivaProductoPorcentaje,
    required this.comisionTarjetaPorcentaje,
    required this.cargoFijoTarjetaUf,
    required this.valorUf,
  });

  // ========================================================
  // CONFIGURACIÓN PREDETERMINADA
  // ========================================================

  /// Valores iniciales utilizados cuando todavía no existe
  /// una configuración guardada localmente.
  factory ConfiguracionCotizador.predeterminada() {
    return const ConfiguracionCotizador(
      costoKwh: 294,
      consumoImpresoraKwh: 0.15,
      desgasteHora: 125,
      margenErrorPorcentaje: 5,
      gastosBancariosMensuales: 30500,
      unidadesMensualesEstimadas: 100,
      ivaProductoPorcentaje: 19,
      comisionTarjetaPorcentaje: 1.44,
      cargoFijoTarjetaUf: 0.0018,

      // La UF continúa vacía hasta que el administrador
      // introduzca un valor manual válido.
      valorUf: 0,
    );
  }

  // ========================================================
  // SERIALIZACIÓN
  // ========================================================

  /// Convierte la configuración en un mapa serializable.
  Map<String, dynamic> toMap() {
    return {
      'costoKwh': costoKwh,
      'consumoImpresoraKwh': consumoImpresoraKwh,
      'desgasteHora': desgasteHora,
      'margenErrorPorcentaje': margenErrorPorcentaje,
      'gastosBancariosMensuales': gastosBancariosMensuales,
      'unidadesMensualesEstimadas': unidadesMensualesEstimadas,
      'ivaProductoPorcentaje': ivaProductoPorcentaje,
      'comisionTarjetaPorcentaje': comisionTarjetaPorcentaje,
      'cargoFijoTarjetaUf': cargoFijoTarjetaUf,
      'valorUf': valorUf,
    };
  }

  /// Reconstruye una configuración desde un mapa.
  ///
  /// Si algún valor no existe o no es válido, utiliza
  /// el valor correspondiente de la configuración inicial.
  factory ConfiguracionCotizador.fromMap(Map<String, dynamic> mapa) {
    final ConfiguracionCotizador predeterminada =
        ConfiguracionCotizador.predeterminada();

    return ConfiguracionCotizador(
      costoKwh: _convertirADouble(mapa['costoKwh'], predeterminada.costoKwh),
      consumoImpresoraKwh: _convertirADouble(
        mapa['consumoImpresoraKwh'],
        predeterminada.consumoImpresoraKwh,
      ),
      desgasteHora: _convertirADouble(
        mapa['desgasteHora'],
        predeterminada.desgasteHora,
      ),
      margenErrorPorcentaje: _convertirADouble(
        mapa['margenErrorPorcentaje'],
        predeterminada.margenErrorPorcentaje,
      ),
      gastosBancariosMensuales: _convertirADouble(
        mapa['gastosBancariosMensuales'],
        predeterminada.gastosBancariosMensuales,
      ),
      unidadesMensualesEstimadas: _convertirAEntero(
        mapa['unidadesMensualesEstimadas'],
        predeterminada.unidadesMensualesEstimadas,
      ),
      ivaProductoPorcentaje: _convertirADouble(
        mapa['ivaProductoPorcentaje'],
        predeterminada.ivaProductoPorcentaje,
      ),
      comisionTarjetaPorcentaje: _convertirADouble(
        mapa['comisionTarjetaPorcentaje'],
        predeterminada.comisionTarjetaPorcentaje,
      ),
      cargoFijoTarjetaUf: _convertirADouble(
        mapa['cargoFijoTarjetaUf'],
        predeterminada.cargoFijoTarjetaUf,
      ),
      valorUf: _convertirADouble(mapa['valorUf'], predeterminada.valorUf),
    );
  }

  // ========================================================
  // COPIA Y ACTUALIZACIÓN
  // ========================================================

  /// Genera una copia reemplazando únicamente
  /// los valores indicados.
  ConfiguracionCotizador copiarCon({
    double? costoKwh,
    double? consumoImpresoraKwh,
    double? desgasteHora,
    double? margenErrorPorcentaje,
    double? gastosBancariosMensuales,
    int? unidadesMensualesEstimadas,
    double? ivaProductoPorcentaje,
    double? comisionTarjetaPorcentaje,
    double? cargoFijoTarjetaUf,
    double? valorUf,
  }) {
    return ConfiguracionCotizador(
      costoKwh: costoKwh ?? this.costoKwh,
      consumoImpresoraKwh: consumoImpresoraKwh ?? this.consumoImpresoraKwh,
      desgasteHora: desgasteHora ?? this.desgasteHora,
      margenErrorPorcentaje:
          margenErrorPorcentaje ?? this.margenErrorPorcentaje,
      gastosBancariosMensuales:
          gastosBancariosMensuales ?? this.gastosBancariosMensuales,
      unidadesMensualesEstimadas:
          unidadesMensualesEstimadas ?? this.unidadesMensualesEstimadas,
      ivaProductoPorcentaje:
          ivaProductoPorcentaje ?? this.ivaProductoPorcentaje,
      comisionTarjetaPorcentaje:
          comisionTarjetaPorcentaje ?? this.comisionTarjetaPorcentaje,
      cargoFijoTarjetaUf: cargoFijoTarjetaUf ?? this.cargoFijoTarjetaUf,
      valorUf: valorUf ?? this.valorUf,
    );
  }

  // ========================================================
  // CONVERSIONES INTERNAS
  // ========================================================

  /// Convierte un valor dinámico en decimal.
  static double _convertirADouble(dynamic valor, double valorPredeterminado) {
    if (valor is num) {
      return valor.toDouble();
    }

    if (valor is String) {
      return double.tryParse(valor.replaceAll(',', '.')) ?? valorPredeterminado;
    }

    return valorPredeterminado;
  }

  /// Convierte un valor dinámico en entero.
  static int _convertirAEntero(dynamic valor, int valorPredeterminado) {
    if (valor is int) {
      return valor;
    }

    if (valor is num) {
      return valor.toInt();
    }

    if (valor is String) {
      return int.tryParse(valor) ?? valorPredeterminado;
    }

    return valorPredeterminado;
  }
}
