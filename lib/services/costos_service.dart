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

  /// Calcula el costo eléctrico asociado al tiempo de impresión.
  ///
  /// Actualmente utiliza un costo operacional de $27,5 por hora.
  /// Este valor será reemplazado posteriormente por una fórmula
  /// configurable basada en consumo de la impresora y valor del kWh.

  static double calcularElectricidad(double minutos) {
    const double costoHora = 27.5;

    final double horas = minutos / 60;

    return horas * costoHora;
  }

  /// Calcula el desgaste y la amortización de la impresora.
  ///
  /// Actualmente utiliza un costo de $125 por hora.
  /// Posteriormente, este valor podrá depender de la impresora
  /// seleccionada y de sus parámetros de mantenimiento.

  static double calcularDesgaste(double minutos) {
    const double desgasteHora = 125;

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

  /// Devuelve el gasto bancario fijo prorrateado por unidad.
  ///
  /// El valor actual considera una estimación de 100 ventas
  /// mensuales. Posteriormente se calculará dinámicamente con:
  ///
  /// gastos financieros mensuales / ventas mensuales estimadas.

  static double calcularGastosBancarios() {
    const double gastoBancarioUnitario = 305;

    return gastoBancarioUnitario;
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
  /// La opción Tarjeta utiliza la tarifa contractual de crédito
  /// nacional como criterio conservador:
  ///
  /// 1,44 % del importe + 0,0018 UF, más IVA de la comisión.
  static double calcularComisionPorMedioPago({
    required String medioPago,
    required double montoTransaccion,
    required double valorUf,
  }) {
    switch (medioPago) {
      case 'Tarjeta':
        return calcularComisionTarjeta(
          montoTransaccion: montoTransaccion,
          porcentaje: 0.0144,
          cargoFijoUf: 0.0018,
          valorUf: valorUf,
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
  /// El IVA del producto se incorpora en todos los medios
  /// de pago.
  ///
  /// La opción Tarjeta utiliza la tarifa conservadora de
  /// crédito nacional y protege el ingreso neto de MAELUX.
  static double calcularPrecioFinalPedido({
    required String medioPago,
    required double montoNetoObjetivo,
    required double valorUf,
    double porcentajeIva = 0.19,
  }) {
    switch (medioPago) {
      case 'Tarjeta':
        return _calcularPrecioFinalConTarjeta(
          montoNetoObjetivo: montoNetoObjetivo,
          porcentajeComision: 0.0144,
          cargoFijoUf: 0.0018,
          valorUf: valorUf,
          porcentajeIva: porcentajeIva,
        );

      case 'Efectivo':
      case 'Transferencia':
      default:
        // El IVA del producto se aplica independientemente
        // del medio utilizado para realizar el pago.
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
