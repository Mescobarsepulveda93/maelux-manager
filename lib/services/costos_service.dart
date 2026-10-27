import '../models/material_3d.dart';

// ==========================================================
// SERVICIO CENTRAL DE CÁLCULO DE COSTOS
// ==========================================================

/// Contiene las reglas financieras y productivas utilizadas
/// por el cotizador interno de MAELUX.
///
/// La interfaz no debe realizar cálculos directamente.
/// Las fórmulas del negocio deben permanecer centralizadas
/// en este servicio para facilitar su mantenimiento y revisión.

class CostosService {
  // ========================================================
  // COSTOS DIRECTOS DE FABRICACIÓN
  // ========================================================

  /// Calcula el costo del filamento utilizado por una unidad.
  ///
  /// Convierte el peso ingresado desde gramos a kilogramos
  /// y lo multiplica por el precio del material seleccionado.

  static double calcularMaterial(double gramos, Material3D material) {
    final double kilogramos = gramos / 1000;

    return kilogramos * material.precioKg;
  }

  /// Calcula el costo eléctrico según la duración de la impresión,
  /// el precio del kWh y el consumo promedio de la impresora.
  static double calcularElectricidad({
    required double minutos,
    required double costoKwh,
    required double consumoKwhHora,
  }) {
    final double horas = minutos / 60;

    return horas * consumoKwhHora * costoKwh;
  }

  /// Calcula el costo asociado al desgaste, mantenimiento
  /// y amortización de la impresora.
  ///
  /// [minutos] representa la duración total de la impresión.
  ///
  /// [desgasteHora] corresponde al costo configurado
  /// por cada hora de funcionamiento.
  static double calcularDesgaste({
    required double minutos,
    required double desgasteHora,
  }) {
    final double horas = minutos / 60;

    return horas * desgasteHora;
  }

  // ========================================================
  // COSTOS OPERACIONALES POR UNIDAD
  // ========================================================

  /// Devuelve el costo unitario utilizado para packaging.
  ///
  /// Incluye provisionalmente bolsa, etiqueta u otros elementos
  /// básicos de presentación del producto.

  static double calcularPackaging() {
    const double costoPackaging = 50;

    return costoPackaging;
  }

  /// Calcula el gasto financiero asignado a cada unidad.
  ///
  /// [gastosMensuales] representa el total mensual asociado
  /// a cuenta bancaria, terminal de pago u otros servicios.
  ///
  /// [unidadesMensualesEstimadas] representa la cantidad aproximada
  /// de unidades entre las cuales se distribuirán esos gastos.
  static double calcularGastosBancarios({
    required double gastosMensuales,
    required int unidadesMensualesEstimadas,
  }) {
    if (gastosMensuales < 0 || unidadesMensualesEstimadas <= 0) {
      return 0;
    }

    return gastosMensuales / unidadesMensualesEstimadas;
  }

  // ========================================================
  // COMISIONES POR TARJETA
  // ========================================================

  /// Calcula la comisión completa de una transacción con tarjeta.
  ///
  /// [montoTransaccion] es el importe total pagado por el cliente.
  ///
  /// [porcentaje] representa la tarifa porcentual expresada
  /// como decimal. Por ejemplo, 0,63 % se representa como 0.0063.
  ///
  /// [cargoFijoUf] es el componente fijo de la tarifa expresado
  /// en unidades de fomento.
  ///
  /// [valorUf] convierte el componente fijo desde UF a pesos.
  ///
  /// [porcentajeIva] corresponde al IVA aplicado sobre la comisión,
  /// no al IVA asociado a la venta del producto.

  static double calcularComisionTarjeta({
    required double montoTransaccion,
    required double porcentaje,
    required double cargoFijoUf,
    required double valorUf,
    double porcentajeIva = 0.19,
  }) {
    final double cargoPorcentual = montoTransaccion * porcentaje;

    final double cargoFijoClp = cargoFijoUf * valorUf;

    final double comisionNeta = cargoPorcentual + cargoFijoClp;

    final double ivaComision = comisionNeta * porcentajeIva;

    return comisionNeta + ivaComision;
  }

  /// Calcula la comisión correspondiente al medio de pago.
  ///
  /// Efectivo y transferencia no generan comisión transaccional.
  ///
  /// Los parámetros de tarjeta son configurados por el administrador
  /// y deben proporcionarse en formato decimal.
  static double calcularComisionPorMedioPago({
    required String medioPago,
    required double montoTransaccion,
    required double valorUf,
    required double porcentajeComision,
    required double cargoFijoUf,
    required double porcentajeIvaComision,
  }) {
    switch (medioPago) {
      case 'Tarjeta':
        return calcularComisionTarjeta(
          montoTransaccion: montoTransaccion,
          porcentaje: porcentajeComision,
          cargoFijoUf: cargoFijoUf,
          valorUf: valorUf,
          porcentajeIva: porcentajeIvaComision,
        );

      case 'Efectivo':
      case 'Transferencia':
      default:
        return 0;
    }
  }
  // ========================================================
  // PRECIO FINAL E IVA DE LA VENTA
  // ========================================================

  /// Obtiene el IVA incluido dentro del precio final cobrado.
  ///
  /// [precioFinal] se considera un importe bruto, por lo que
  /// ya contiene el impuesto correspondiente a la venta.
  static double extraerIvaVenta({
    required double precioFinal,
    double porcentajeIva = 0.19,
  }) {
    final double precioNeto = precioFinal / (1 + porcentajeIva);

    return precioFinal - precioNeto;
  }

  /// Calcula el precio final que debe pagar el cliente.
  ///
  /// El IVA del producto se incorpora en todos los medios de pago.
  ///
  /// Cuando se selecciona Tarjeta, el cálculo protege el ingreso
  /// neto esperado frente a la comisión financiera configurada.
  static double calcularPrecioFinalPedido({
    required String medioPago,
    required double montoNetoObjetivo,
    required double valorUf,
    required double porcentajeIva,
    required double porcentajeComision,
    required double cargoFijoUf,
  }) {
    switch (medioPago) {
      case 'Tarjeta':
        return _calcularPrecioFinalConTarjeta(
          montoNetoObjetivo: montoNetoObjetivo,
          porcentajeComision: porcentajeComision,
          cargoFijoUf: cargoFijoUf,
          valorUf: valorUf,
          porcentajeIva: porcentajeIva,
        );

      case 'Efectivo':
      case 'Transferencia':
      default:
        return montoNetoObjetivo * (1 + porcentajeIva);
    }
  }

  /// Calcula de forma inversa el precio que debe pagar
  /// el cliente cuando utiliza una tarjeta.
  ///
  /// La fórmula evita que la comisión financiera disminuya
  /// el ingreso neto esperado por MAELUX.
  static double _calcularPrecioFinalConTarjeta({
    required double montoNetoObjetivo,
    required double porcentajeComision,
    required double cargoFijoUf,
    required double valorUf,
    required double porcentajeIva,
  }) {
    final double factorIva = 1 + porcentajeIva;

    final double cargoFijoClp = cargoFijoUf * valorUf;

    // Representa la parte del precio bruto que queda disponible
    // después de separar el IVA del producto y la comisión.
    final double divisor = (1 / factorIva) - (porcentajeComision * factorIva);

    if (divisor <= 0) {
      return 0;
    }

    // El cargo fijo también incorpora internamente
    // el IVA correspondiente al servicio financiero.
    final double numerador = montoNetoObjetivo + (cargoFijoClp * factorIva);

    return numerador / divisor;
  }
}
