import 'package:flutter/material.dart';

import '../data/configuracion_cotizador_repository.dart';
import '../models/configuracion_cotizador.dart';
import '../data/insumos_repository.dart';
import '../data/materiales_demo.dart';
import '../models/insumo.dart';
import '../models/insumo_cotizacion.dart';
import '../models/material_3d.dart';
import '../services/costos_service.dart';

// ==========================================================
// PANTALLA PRINCIPAL DEL COTIZADOR
// ==========================================================

class CotizadorScreen extends StatefulWidget {
  const CotizadorScreen({super.key});

  @override
  State<CotizadorScreen> createState() => _CotizadorScreenState();
}

class _CotizadorScreenState extends State<CotizadorScreen> {
  // ========================================================
  // CONTROLADORES DEL FORMULARIO
  // ========================================================

  // Estos controladores permiten obtener los valores escritos
  // por el usuario en cada campo del formulario.

  final nombreDisenoController = TextEditingController();
  final gramosController = TextEditingController();
  final horasController = TextEditingController();
  final minutosController = TextEditingController();

  // Cada cotización comienza con una unidad por defecto.

  final cantidadController = TextEditingController(text: '1');

  // Cantidad del insumo que se utilizará para fabricar
  // o presentar una unidad del producto cotizado.
  final cantidadInsumoController = TextEditingController(text: '1');

  // Valor de la UF utilizado para convertir a pesos
  // los cargos fijos de las tarifas por tarjeta.

  final valorUfController = TextEditingController();

  // ========================================================
  // CONTROLADORES DE SUPUESTOS EDITABLES
  // ========================================================

  // Precio cobrado por cada kilowatt-hora consumido.
  // Debe obtenerse del cargo por energía de la boleta eléctrica.
  final costoKwhController = TextEditingController(text: '294');

  // Consumo promedio de la impresora durante una hora de trabajo.
  final consumoImpresoraKwhController = TextEditingController(text: '0.15');

  // Costo por hora destinado a desgaste, mantenimiento
  // y amortización de la impresora.
  final desgasteHoraController = TextEditingController(text: '125');

  // Porcentaje aplicado para cubrir fallas de impresión,
  // repeticiones y pérdidas de material.
  final margenErrorController = TextEditingController(text: '5');

  // Gastos financieros mensuales que se distribuyen
  // entre las unidades mensuales estimadas.
  final gastosFinancierosMensualesController = TextEditingController(
    text: '30500',
  );

  // Cantidad estimada de unidades vendidas durante el mes.
  // Se utiliza para distribuir los gastos financieros mensuales.
  final unidadesMensualesEstimadasController = TextEditingController(
    text: '100',
  );

  // IVA aplicado a la venta del producto.
  final ivaProductoController = TextEditingController(text: '19');

  // Tarifa conservadora utilizada para pagos con tarjeta.
  final comisionTarjetaController = TextEditingController(text: '1.44');

  // Componente fijo contractual de la comisión,
  // expresado en unidades de fomento.
  final cargoFijoTarjetaUfController = TextEditingController(text: '0.0018');

  // ========================================================
  // REPOSITORIO DE CONFIGURACIÓN
  // ========================================================

  /// Repositorio compartido utilizado para consultar y guardar
  /// los supuestos administrativos del cotizador.
  final ConfiguracionCotizadorRepository configuracionRepository =
      ConfiguracionCotizadorRepository.instancia;

  // ========================================================
  // REPOSITORIO DE INSUMOS
  // ========================================================

  /// Repositorio compartido utilizado para consultar los
  /// insumos activos registrados en MAELUX.
  final InsumosRepository insumosRepository = InsumosRepository.instancia;

  // ========================================================
  // INSUMOS UTILIZADOS EN LA COTIZACIÓN
  // ========================================================

  /// Insumos seleccionados para fabricar o presentar
  /// una unidad del producto cotizado.
  ///
  /// Cada registro conserva el insumo y la cantidad utilizada.
  final List<InsumoCotizacion> insumosSeleccionados = [];

  // Insumo activo seleccionado en el desplegable.
  //
  // El valor se mantiene separado de insumosSeleccionados
  // hasta que el usuario confirma su incorporación.
  Insumo? insumoPendiente;

  /// Devuelve únicamente los insumos que están disponibles
  /// actualmente para utilizar en el cotizador.
  List<Insumo> get insumosActivos {
    return insumosRepository.obtenerActivos();
  }

  // ========================================================
  // OPCIONES SELECCIONABLES
  // ========================================================

  // El primer material de la lista se utiliza como selección inicial.

  Material3D materialSeleccionado = materialesDemo.first;

  // Multiplicadores comerciales disponibles durante el desarrollo.
  // Posteriormente, solo el administrador podrá modificarlos.

  final List<double> multiplicadores = [2, 3, 5];

  double multiplicadorComercial = 3;

  // Medios de pago presentados al usuario.
  //
  // La opción Tarjeta utiliza la tarifa de crédito nacional como
  // criterio conservador para débito, crédito y prepago nacionales.
  final List<String> mediosPago = ['Efectivo', 'Transferencia', 'Tarjeta'];

  String medioPagoSeleccionado = 'Efectivo';

  // ========================================================
  // RESULTADOS DE FABRICACIÓN
  // ========================================================

  double costoMaterial = 0;
  double costoElectricidad = 0;
  double costoDesgaste = 0;
  double costoMargenError = 0;
  double subtotalFabricacion = 0;

  // ========================================================
  // RESULTADOS OPERACIONALES
  // ========================================================

  double costoInsumos = 0;
  double costoGastosBancarios = 0;
  double subtotalOperacional = 0;
  // ========================================================
  // RESULTADOS COMERCIALES
  // ========================================================

  double costoEmpresa = 0;
  double precioSugerido = 0;

  // Comisión total asociada al pago con tarjeta.
  // El valor incorpora internamente el IVA del servicio financiero.
  double costoComisionTarjeta = 0;

  // IVA del producto incluido en la boleta o factura.
  double costoIvaVenta = 0;

  // Valores finales listos para comunicar o cobrar.
  double precioFinalUnitario = 0;
  double precioFinalPedido = 0;

  // ========================================================
  // RESULTADOS GENERALES DE LA COTIZACIÓN
  // ========================================================

  // Nombre correspondiente a la última cotización calculada.
  String nombreDisenoCotizado = '';

  // Tiempo total expresado en formato decimal.
  // Ejemplo: 11 horas y 50 minutos equivalen a 11,83 horas.

  double tiempoDecimalHoras = 0;

  int cantidadUnidades = 1;

  // Total preliminar del pedido antes de IVA y ajustes finales.

  double precioTotalNeto = 0;

  // ========================================================
  // INICIALIZACIÓN DEL COTIZADOR
  // ========================================================

  @override
  void initState() {
    super.initState();

    _cargarConfiguracionGuardada();
  }
  // ========================================================
  // GUARDADO DE LA CONFIGURACIÓN
  // ========================================================

  /// Valida y guarda los supuestos administrativos
  /// introducidos en el cotizador.
  Future<void> _guardarConfiguracionCotizador() async {
    final double costoKwh =
        double.tryParse(costoKwhController.text.replaceAll(',', '.')) ?? 0;

    final double consumoImpresoraKwh =
        double.tryParse(
          consumoImpresoraKwhController.text.replaceAll(',', '.'),
        ) ??
        0;

    final double desgasteHora =
        double.tryParse(desgasteHoraController.text.replaceAll(',', '.')) ?? -1;

    final double margenErrorPorcentaje =
        double.tryParse(margenErrorController.text.replaceAll(',', '.')) ?? -1;

    final double gastosBancariosMensuales =
        double.tryParse(
          gastosFinancierosMensualesController.text.replaceAll(',', '.'),
        ) ??
        -1;

    final int unidadesMensualesEstimadas =
        int.tryParse(unidadesMensualesEstimadasController.text) ?? 0;

    final double ivaProductoPorcentaje =
        double.tryParse(ivaProductoController.text.replaceAll(',', '.')) ?? -1;

    final double comisionTarjetaPorcentaje =
        double.tryParse(comisionTarjetaController.text.replaceAll(',', '.')) ??
        -1;

    final double cargoFijoTarjetaUf =
        double.tryParse(
          cargoFijoTarjetaUfController.text.replaceAll(',', '.'),
        ) ??
        -1;

    final double valorUf =
        double.tryParse(valorUfController.text.replaceAll(',', '.')) ?? 0;

    // Los valores productivos obligatorios deben ser positivos.
    if (costoKwh <= 0 ||
        consumoImpresoraKwh <= 0 ||
        desgasteHora < 0 ||
        margenErrorPorcentaje < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa los supuestos de producción antes de guardar.'),
        ),
      );

      return;
    }

    // Los gastos pueden ser cero, pero la cantidad mensual
    // estimada siempre debe ser mayor que cero.
    if (gastosBancariosMensuales < 0 || unidadesMensualesEstimadas <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Revisa los gastos bancarios y las unidades mensuales.',
          ),
        ),
      );

      return;
    }

    // Los porcentajes deben mantenerse dentro de un rango válido.
    if (ivaProductoPorcentaje < 0 ||
        ivaProductoPorcentaje >= 100 ||
        comisionTarjetaPorcentaje < 0 ||
        comisionTarjetaPorcentaje >= 100 ||
        cargoFijoTarjetaUf < 0 ||
        valorUf < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa los valores tributarios, de tarjeta y UF.'),
        ),
      );

      return;
    }

    final ConfiguracionCotizador nuevaConfiguracion = ConfiguracionCotizador(
      costoKwh: costoKwh,
      consumoImpresoraKwh: consumoImpresoraKwh,
      desgasteHora: desgasteHora,
      margenErrorPorcentaje: margenErrorPorcentaje,
      gastosBancariosMensuales: gastosBancariosMensuales,
      unidadesMensualesEstimadas: unidadesMensualesEstimadas,
      ivaProductoPorcentaje: ivaProductoPorcentaje,
      comisionTarjetaPorcentaje: comisionTarjetaPorcentaje,
      cargoFijoTarjetaUf: cargoFijoTarjetaUf,
      valorUf: valorUf,
    );

    await configuracionRepository.actualizar(nuevaConfiguracion);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración del cotizador guardada correctamente.'),
      ),
    );
  }

  /// Carga en los controladores los valores recuperados
  /// desde el almacenamiento local.
  void _cargarConfiguracionGuardada() {
    final ConfiguracionCotizador configuracion =
        configuracionRepository.configuracion;

    costoKwhController.text = _numeroComoTexto(configuracion.costoKwh);

    consumoImpresoraKwhController.text = _numeroComoTexto(
      configuracion.consumoImpresoraKwh,
    );

    desgasteHoraController.text = _numeroComoTexto(configuracion.desgasteHora);

    margenErrorController.text = _numeroComoTexto(
      configuracion.margenErrorPorcentaje,
    );

    gastosFinancierosMensualesController.text = _numeroComoTexto(
      configuracion.gastosBancariosMensuales,
    );

    unidadesMensualesEstimadasController.text = configuracion
        .unidadesMensualesEstimadas
        .toString();

    ivaProductoController.text = _numeroComoTexto(
      configuracion.ivaProductoPorcentaje,
    );

    comisionTarjetaController.text = _numeroComoTexto(
      configuracion.comisionTarjetaPorcentaje,
    );

    cargoFijoTarjetaUfController.text = _numeroComoTexto(
      configuracion.cargoFijoTarjetaUf,
    );

    valorUfController.text = configuracion.valorUf > 0
        ? _numeroComoTexto(configuracion.valorUf)
        : '';
  }

  /// Convierte un número en texto sin añadir decimales
  /// innecesarios a los valores enteros.
  String _numeroComoTexto(double valor) {
    if (valor == valor.truncateToDouble()) {
      return valor.toStringAsFixed(0);
    }

    return valor.toString();
  }

  // ========================================================
  // GESTIÓN DE INSUMOS DE LA COTIZACIÓN
  // ========================================================

  /// Agrega el insumo seleccionado a la cotización.
  ///
  /// La cantidad representa el consumo necesario para fabricar
  /// o presentar una unidad del producto cotizado.
  void _agregarInsumoCotizacion() {
    final Insumo? insumo = insumoPendiente;

    final double cantidadUtilizada =
        double.tryParse(cantidadInsumoController.text.replaceAll(',', '.')) ??
        0;

    // Se requiere seleccionar un insumo activo.
    if (insumo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un insumo antes de agregarlo.'),
        ),
      );

      return;
    }

    // La cantidad utilizada debe ser mayor que cero.
    if (cantidadUtilizada <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce una cantidad de insumo mayor que cero.'),
        ),
      );

      return;
    }

    // Se comprueba si el insumo ya fue agregado.
    final int indiceExistente = insumosSeleccionados.indexWhere((seleccion) {
      return seleccion.insumo.id == insumo.id;
    });

    setState(() {
      if (indiceExistente >= 0) {
        // Si ya existe, se reemplaza la cantidad anterior.
        insumosSeleccionados[indiceExistente] =
            insumosSeleccionados[indiceExistente].copiarCon(
              cantidadUtilizada: cantidadUtilizada,
            );
      } else {
        // Si todavía no existe, se incorpora como una
        // nueva selección de la cotización.
        insumosSeleccionados.add(
          InsumoCotizacion(
            insumo: insumo,
            cantidadUtilizada: cantidadUtilizada,
          ),
        );
      }

      // Se limpia la selección temporal para permitir
      // añadir otro insumo.
      insumoPendiente = null;
      cantidadInsumoController.text = '1';
    });
  }

  /// Elimina un insumo de la cotización sin borrarlo
  /// del repositorio general de MAELUX.
  void _eliminarInsumoCotizacion(int indice) {
    if (indice < 0 || indice >= insumosSeleccionados.length) {
      return;
    }

    setState(() {
      insumosSeleccionados.removeAt(indice);
    });
  }

  /// Suma el coste de todos los insumos seleccionados
  /// para una unidad del producto cotizado.
  double get costoInsumosPorUnidad {
    return insumosSeleccionados.fold(0, (total, seleccion) {
      return total + seleccion.costoTotal;
    });
  }

  // ========================================================
  // CÁLCULO DE LA COTIZACIÓN
  // ========================================================

  void calcularCosto() {
    // ------------------------------------------------------
    // LECTURA Y CONVERSIÓN DE DATOS
    // ------------------------------------------------------

    final String nombreDiseno = nombreDisenoController.text.trim();

    final double gramos =
        double.tryParse(gramosController.text.replaceAll(',', '.')) ?? 0;

    final double horas =
        double.tryParse(horasController.text.replaceAll(',', '.')) ?? 0;

    final double minutos =
        double.tryParse(minutosController.text.replaceAll(',', '.')) ?? 0;

    final int cantidad = int.tryParse(cantidadController.text) ?? 1;

    // La UF permite convertir a pesos los cargos fijos
    // establecidos en las tarifas por tarjeta.
    final double valorUf =
        double.tryParse(valorUfController.text.replaceAll(',', '.')) ?? 0;

    // ------------------------------------------------------
    // LECTURA DE SUPUESTOS DE PRODUCCIÓN
    // ------------------------------------------------------

    // Precio cobrado por cada kilowatt-hora consumido.
    final double costoKwh =
        double.tryParse(costoKwhController.text.replaceAll(',', '.')) ?? 0;

    // Consumo promedio de la impresora por cada hora de trabajo.
    final double consumoImpresoraKwh =
        double.tryParse(
          consumoImpresoraKwhController.text.replaceAll(',', '.'),
        ) ??
        0;

    // Costo por hora destinado al desgaste y mantenimiento.
    final double desgasteHora =
        double.tryParse(desgasteHoraController.text.replaceAll(',', '.')) ?? 0;

    // Porcentaje destinado a cubrir fallas y repeticiones.
    final double porcentajeMargenError =
        double.tryParse(margenErrorController.text.replaceAll(',', '.')) ?? 0;

    // ------------------------------------------------------
    // LECTURA DE SUPUESTOS FINANCIEROS
    // ------------------------------------------------------

    // Total mensual destinado a cubrir servicios bancarios
    // y otros gastos financieros recurrentes.
    final double gastosFinancierosMensuales =
        double.tryParse(
          gastosFinancierosMensualesController.text.replaceAll(',', '.'),
        ) ??
        0;

    // Cantidad estimada de unidades entre las cuales se
    // distribuirán los gastos financieros mensuales.
    final int unidadesMensualesEstimadas =
        int.tryParse(unidadesMensualesEstimadasController.text) ?? 0;

    // ------------------------------------------------------
    // LECTURA DE SUPUESTOS TRIBUTARIOS Y DE TARJETA
    // ------------------------------------------------------

    // IVA aplicado al precio de venta del producto.
    final double porcentajeIva =
        double.tryParse(ivaProductoController.text.replaceAll(',', '.')) ?? 0;

    // Comisión porcentual aplicada al pago con tarjeta.
    final double porcentajeComisionTarjeta =
        double.tryParse(comisionTarjetaController.text.replaceAll(',', '.')) ??
        0;

    // Cargo fijo contractual por cada transacción con tarjeta.
    final double cargoFijoTarjetaUf =
        double.tryParse(
          cargoFijoTarjetaUfController.text.replaceAll(',', '.'),
        ) ??
        0;

    // Convierte los porcentajes escritos por el administrador
    // al formato decimal utilizado por las fórmulas.
    final double ivaDecimal = porcentajeIva / 100;

    final double comisionTarjetaDecimal = porcentajeComisionTarjeta / 100;

    // ------------------------------------------------------
    // CONVERSIÓN DEL TIEMPO DE IMPRESIÓN
    // ------------------------------------------------------

    // Convierte las horas y los minutos ingresados
    // en una única duración expresada en minutos.
    final double minutosTotales = (horas * 60) + minutos;

    // Convierte la duración a horas decimales.
    // Ejemplo: 11 horas y 50 minutos equivalen a 11,83 horas.
    final double tiempoDecimal = horas + (minutos / 60);

    // ------------------------------------------------------
    // VALIDACIÓN DEL FORMULARIO
    // ------------------------------------------------------

    if (nombreDiseno.isEmpty ||
        gramos <= 0 ||
        minutosTotales <= 0 ||
        cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa el nombre, los gramos, el tiempo y la cantidad.',
          ),
        ),
      );

      return;
    }

    if (costoKwh <= 0 ||
        consumoImpresoraKwh <= 0 ||
        desgasteHora < 0 ||
        porcentajeMargenError < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Revisa el costo eléctrico, el consumo y los supuestos de producción.',
          ),
        ),
      );

      return;
    }

    // Los gastos pueden ser cero, pero no negativos.
    // La cantidad de unidades siempre debe ser mayor que cero.
    if (gastosFinancierosMensuales < 0 || unidadesMensualesEstimadas <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Revisa los gastos financieros y las unidades mensuales estimadas.',
          ),
        ),
      );

      return;
    }

    // El IVA debe encontrarse dentro de un rango válido.
    // La comisión y el cargo fijo pueden ser cero, pero no negativos.
    if (porcentajeIva < 0 ||
        porcentajeIva >= 100 ||
        porcentajeComisionTarjeta < 0 ||
        porcentajeComisionTarjeta >= 100 ||
        cargoFijoTarjetaUf < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Revisa el IVA y los valores configurados para tarjeta.',
          ),
        ),
      );

      return;
    }

    // La UF es necesaria únicamente cuando se selecciona
    // Tarjeta como medio de pago.
    final bool usaTarjeta = medioPagoSeleccionado == 'Tarjeta';

    // La UF solo es obligatoria cuando el pago utiliza tarjeta.
    if (usaTarjeta && valorUf <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Introduce un valor UF válido para calcular la comisión.',
          ),
        ),
      );

      return;
    }

    // ------------------------------------------------------
    // COSTOS DE FABRICACIÓN POR UNIDAD
    // ------------------------------------------------------

    final double material = CostosService.calcularMaterial(
      gramos,
      materialSeleccionado,
    );

    final double electricidad = CostosService.calcularElectricidad(
      minutos: minutosTotales,
      costoKwh: costoKwh,
      consumoKwhHora: consumoImpresoraKwh,
    );

    final double desgaste = CostosService.calcularDesgaste(
      minutos: minutosTotales,
      desgasteHora: desgasteHora,
    );

    // Convierte el porcentaje escrito por el administrador
    // desde formato porcentual a formato decimal.
    //
    // Ejemplo: 5 % se transforma en 0,05.
    final double margenError =
        (material + electricidad + desgaste) * (porcentajeMargenError / 100);
    final double fabricacion = material + electricidad + desgaste + margenError;

    // ------------------------------------------------------
    // COSTOS OPERACIONALES POR UNIDAD
    // ------------------------------------------------------

    // El coste de los insumos corresponde a la suma de los
    // elementos seleccionados para una unidad del producto.
    final double insumos = costoInsumosPorUnidad;

    final double gastosBancarios = CostosService.calcularGastosBancarios(
      gastosMensuales: gastosFinancierosMensuales,
      unidadesMensualesEstimadas: unidadesMensualesEstimadas,
    );

    // El subtotal operacional por unidad se forma con los
    // insumos seleccionados y los gastos financieros prorrateados.
    final double operacional = insumos + gastosBancarios;

    // ------------------------------------------------------
    // COSTO BASE Y PRECIO SUGERIDO
    // ------------------------------------------------------

    final double empresa = fabricacion + operacional;

    // El multiplicador genera un precio neto estimativo.
    // No representa todavía el precio final con IVA.

    final double sugerido = empresa * multiplicadorComercial;

    // Total neto preliminar para todas las unidades solicitadas.

    final double totalNeto = sugerido * cantidad;

    // ------------------------------------------------------
    // IVA, COMISIÓN Y PRECIO FINAL
    // ------------------------------------------------------

    // El precio final incorpora el IVA del producto en todos
    // los medios de pago.
    //
    // Cuando se utiliza tarjeta, la fórmula también protege
    // el ingreso frente a la comisión financiera del pedido.
    final double finalPedido = CostosService.calcularPrecioFinalPedido(
      medioPago: medioPagoSeleccionado,
      montoNetoObjetivo: totalNeto,
      valorUf: valorUf,
      porcentajeIva: ivaDecimal,
      porcentajeComision: comisionTarjetaDecimal,
      cargoFijoUf: cargoFijoTarjetaUf,
    );

    // Extrae únicamente el IVA de la venta del producto.
    // Este es el IVA que mostraremos en la vista comercial.
    final double ivaVenta = CostosService.extraerIvaVenta(
      precioFinal: finalPedido,
      porcentajeIva: ivaDecimal,
    );

    // Calcula la comisión definitiva sobre el importe
    // que efectivamente pagará el cliente.
    final double comisionTarjeta = CostosService.calcularComisionPorMedioPago(
      medioPago: medioPagoSeleccionado,
      montoTransaccion: finalPedido,
      valorUf: valorUf,
      porcentajeComision: comisionTarjetaDecimal,
      cargoFijoUf: cargoFijoTarjetaUf,
      porcentajeIvaComision: ivaDecimal,
    );

    // Divide el precio total entre las unidades solicitadas.
    final double finalUnitario = cantidad > 0 ? finalPedido / cantidad : 0;

    // ------------------------------------------------------
    // ACTUALIZACIÓN DE LA INTERFAZ
    // ------------------------------------------------------

    setState(() {
      costoMaterial = material;
      costoElectricidad = electricidad;
      costoDesgaste = desgaste;
      costoMargenError = margenError;
      subtotalFabricacion = fabricacion;

      costoInsumos = insumos;
      costoGastosBancarios = gastosBancarios;
      subtotalOperacional = operacional;

      costoEmpresa = empresa;
      precioSugerido = sugerido;
      costoComisionTarjeta = comisionTarjeta;

      costoIvaVenta = ivaVenta;
      precioFinalUnitario = finalUnitario;
      precioFinalPedido = finalPedido;

      nombreDisenoCotizado = nombreDiseno;
      tiempoDecimalHoras = tiempoDecimal;
      cantidadUnidades = cantidad;
      precioTotalNeto = totalNeto;
    });
  }

  // ========================================================
  // COMPONENTES AUXILIARES DE LA INTERFAZ
  // ========================================================

  // ========================================================
  // FORMATO DE CANTIDADES E IMPORTES
  // ========================================================

  /// Normaliza pequeñas diferencias de precisión generadas
  /// por cálculos con números decimales.
  double _normalizarPrecision(double valor) {
    return double.parse(valor.toStringAsFixed(6));
  }

  /// Presenta una cantidad sin decimales innecesarios.
  ///
  /// Ejemplos:
  ///
  /// `1.0` se presenta como `1`.
  ///
  /// `2.5` se presenta como `2,5`.
  ///
  /// `0.75` se presenta como `0,75`.
  String _formatearCantidad(double cantidad) {
    final double cantidadNormalizada = _normalizarPrecision(cantidad);

    if (cantidadNormalizada == cantidadNormalizada.truncateToDouble()) {
      return cantidadNormalizada.toStringAsFixed(0);
    }

    String texto = cantidadNormalizada.toStringAsFixed(6);

    // Se eliminan los ceros innecesarios situados
    // al final de la parte decimal.
    texto = texto.replaceFirst(RegExp(r'0+$'), '');

    // Se elimina el punto si ya no quedan decimales.
    texto = texto.replaceFirst(RegExp(r'\.$'), '');

    return texto.replaceAll('.', ',');
  }

  /// Presenta la unidad de medida en singular o plural.
  ///
  /// Las unidades antiguas que no aparecen en el listado
  /// se conservan sin modificaciones.
  String _formatearUnidad(double cantidad, String unidad) {
    if (_normalizarPrecision(cantidad) == 1.0) {
      return unidad;
    }

    const Map<String, String> plurales = {
      'unidad': 'unidades',
      'metro': 'metros',
      'centímetro': 'centímetros',
      'kilogramo': 'kilogramos',
      'gramo': 'gramos',
      'litro': 'litros',
      'mililitro': 'mililitros',
      'rollo': 'rollos',
      'paquete': 'paquetes',
      'hoja': 'hojas',
    };

    return plurales[unidad] ?? unidad;
  }

  /// Presenta un importe utilizando el formato habitual
  /// de pesos chilenos.
  ///
  /// Los valores enteros se muestran sin decimales.
  /// Los valores fraccionarios conservan dos decimales.
  String _formatearPesos(double monto) {
    if (!monto.isFinite) {
      return '\$0';
    }

    final bool tieneDecimales = monto != monto.truncateToDouble();

    final String texto = monto.toStringAsFixed(tieneDecimales ? 2 : 0);

    final List<String> partes = texto.split('.');

    // Se utilizan puntos como separadores de miles.
    final String enteros = partes[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (coincidencia) => '${coincidencia[1]}.',
    );

    // La parte decimal se separa mediante una coma.
    final String decimales = partes.length > 1 ? ',${partes[1]}' : '';

    return '\$$enteros$decimales';
  }

  /// Construye un dato compacto para el resumen comercial.
  ///
  /// Este componente evita repetir estilos y mantiene una
  /// presentación uniforme para los valores listos para cobrar.
  Widget _datoResumen({required String etiqueta, required String valor}) {
    return Column(
      children: [
        Text(
          etiqueta,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        ),

        const SizedBox(height: 4),

        Text(
          valor,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Construye la sección utilizada para seleccionar los insumos
  /// aplicados a una unidad del producto cotizado.
  ///
  /// Los insumos disponibles proceden del repositorio compartido.
  /// Los insumos desactivados no aparecen en el selector.
  Widget _construirInsumosProducto() {
    final List<Insumo> disponibles = insumosActivos;

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        title: const Text(
          'Insumos del producto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          insumosSeleccionados.isEmpty
              ? 'No hay insumos seleccionados'
              : '${insumosSeleccionados.length} '
                    'insumo(s) seleccionado(s)',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),

          const SizedBox(height: 8),

          // --------------------------------------------------
          // SELECCIÓN DEL INSUMO
          // --------------------------------------------------
          if (disponibles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No hay insumos activos disponibles. '
                'Activa o registra un insumo desde Gestión de insumos.',
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            DropdownButtonFormField<Insumo>(
              initialValue: insumoPendiente,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Insumo disponible',
                border: OutlineInputBorder(),
              ),
              items: disponibles.map((insumo) {
                return DropdownMenuItem<Insumo>(
                  value: insumo,
                  child: Text(
                    '${insumo.nombre} - '
                    '${_formatearPesos(insumo.costoUnitario)} '
                    'por ${insumo.unidadMedida}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (insumo) {
                setState(() {
                  insumoPendiente = insumo;
                });
              },
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // CANTIDAD UTILIZADA POR PRODUCTO
            // --------------------------------------------------
            TextField(
              controller: cantidadInsumoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Cantidad utilizada por producto',
                suffixText: insumoPendiente?.unidadMedida ?? 'cantidad',
                helperText:
                    'Indica cuánto insumo utiliza una unidad del producto.',
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _agregarInsumoCotizacion,
                icon: const Icon(Icons.add),
                label: const Text('AGREGAR INSUMO'),
              ),
            ),
          ],

          // --------------------------------------------------
          // INSUMOS SELECCIONADOS
          // --------------------------------------------------
          if (insumosSeleccionados.isNotEmpty) ...[
            const Divider(height: 32),

            const Text(
              'INSUMOS SELECCIONADOS',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            ...insumosSeleccionados.asMap().entries.map((entrada) {
              final int indice = entrada.key;
              final InsumoCotizacion seleccion = entrada.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(seleccion.insumo.nombre),
                  subtitle: Text(
                    '${_formatearCantidad(seleccion.cantidadUtilizada)} '
                    '${_formatearUnidad(seleccion.cantidadUtilizada, seleccion.insumo.unidadMedida)} × '
                    '${_formatearPesos(seleccion.insumo.costoUnitario)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatearPesos(seleccion.costoTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      IconButton(
                        onPressed: () {
                          _eliminarInsumoCotizacion(indice);
                        },
                        tooltip: 'Quitar de la cotización',
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const Divider(height: 24),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Costo total de insumos por unidad',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Text(
                  _formatearPesos(costoInsumosPorUnidad),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          const Text(
            'Los insumos seleccionados se incorporan al cálculo '
            'cuando se pulsa el botón Calcular.',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  /// Construye el desglose interno utilizado para revisar
  /// los costos y las fórmulas de la cotización.
  ///
  /// Posteriormente, este contenido estará disponible
  /// únicamente para usuarios con rol administrador.
  Widget _construirDetalleAdministrativo() {
    return Card(
      child: ExpansionTile(
        title: const Text(
          'Ver detalle administrativo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Costos, comisión y cálculo interno'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          // --------------------------------------------------
          // COSTOS DE FABRICACIÓN
          // --------------------------------------------------
          const Divider(),

          const Text(
            'FABRICACIÓN',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Material: '
            '\$${costoMaterial.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
          ),

          Text(
            'Electricidad: '
            '\$${costoElectricidad.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
          ),

          Text(
            'Desgaste: '
            '\$${costoDesgaste.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
          ),

          Text(
            'Margen de error: '
            '\$${costoMargenError.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Subtotal fabricación: '
            '\$${subtotalFabricacion.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------
          // COSTOS OPERACIONALES
          // --------------------------------------------------
          const Divider(),

          const Text(
            'OPERACIÓN',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Insumos seleccionados: '
            '\$${costoInsumos.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
          ),

          Text(
            'Gastos bancarios: '
            '\$${costoGastosBancarios.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Subtotal operación: '
            '\$${subtotalOperacional.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------
          // COSTO BASE DE MAELUX
          // --------------------------------------------------
          const Divider(),

          Text(
            'Costo base MAELUX: '
            '\$${costoEmpresa.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------
          // PRECIO NETO ESTIMATIVO
          // --------------------------------------------------
          const Divider(),

          const Text(
            'PRECIO ESTIMATIVO',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Multiplicador aplicado: '
            'x${multiplicadorComercial.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
          ),

          Text(
            'Precio sugerido neto por unidad: '
            '\$${precioSugerido.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          Text('Cantidad: $cantidadUnidades', textAlign: TextAlign.center),

          Text(
            'Total neto preliminar: '
            '\$${precioTotalNeto.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          Text(
            'Tiempo decimal: '
            '${tiempoDecimalHoras.toStringAsFixed(2)} horas',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------
          // IMPUESTOS Y COMISIÓN
          // --------------------------------------------------
          const Divider(),

          const Text(
            'IMPUESTOS Y COMISIÓN',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Medio de pago: $medioPagoSeleccionado',
            textAlign: TextAlign.center,
          ),

          Text(
            'Comisión de tarjeta del pedido: '
            '\$${costoComisionTarjeta.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
          ),

          Text(
            'IVA del producto: '
            '\$${costoIvaVenta.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------
          // RESULTADOS FINALES
          // --------------------------------------------------
          const Divider(),

          const Text(
            'RESULTADOS FINALES',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Precio final por unidad: '
            '\$${precioFinalUnitario.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          Text(
            'Total final del pedido: '
            '\$${precioFinalPedido.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Construye la configuración interna utilizada por MAELUX.
  ///
  /// Estos valores permitirán modificar las reglas de producción,
  /// operación, tributación y comisión sin editar el código.
  ///
  /// Los valores configurados en esta sección se aplican
  /// cuando se genera una nueva cotización.
  Widget _construirSupuestosEditables() {
    return Card(
      child: ExpansionTile(
        title: const Text(
          'Supuestos editables',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Configuración productiva y financiera'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          // --------------------------------------------------
          // SUPUESTOS DE PRODUCCIÓN
          // --------------------------------------------------
          const Divider(),

          const Text(
            'PRODUCCIÓN',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: costoKwhController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Costo de electricidad',
              prefixText: '\$ ',
              suffixText: 'por kWh',
              helperText: 'Utiliza el cargo por energía indicado en la boleta.',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: consumoImpresoraKwhController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Consumo promedio de la impresora',
              suffixText: 'kWh/h',
              helperText: 'Ejemplo: 0,15 kWh por cada hora de impresión.',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: desgasteHoraController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Desgaste y mantenimiento por hora',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: margenErrorController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Margen de error',
              suffixText: '%',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          // --------------------------------------------------
          // SUPUESTOS FINANCIEROS
          // --------------------------------------------------
          const Divider(),

          const Text(
            'GASTOS FINANCIEROS',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: gastosFinancierosMensualesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Gastos financieros mensuales',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: unidadesMensualesEstimadasController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Unidades mensuales estimadas',
              suffixText: 'unidades',
              helperText:
                  'Cantidad aproximada de unidades vendidas durante el mes.',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          // --------------------------------------------------
          // SUPUESTOS TRIBUTARIOS
          // --------------------------------------------------
          const Divider(),

          const Text(
            'TRIBUTACIÓN',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: ivaProductoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'IVA del producto',
              suffixText: '%',
              helperText: 'Parámetro sensible. Valor actual: 19 %.',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          // --------------------------------------------------
          // SUPUESTOS DE TARJETA
          // --------------------------------------------------
          const Divider(),

          const Text(
            'PAGO CON TARJETA',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: comisionTarjetaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Comisión porcentual',
              suffixText: '%',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: cargoFijoTarjetaUfController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cargo fijo por transacción',
              suffixText: 'UF',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: valorUfController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor UF de respaldo',
              prefixText: '\$ ',
              helperText:
                  'Se reemplazará posteriormente por actualización automática.',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Los valores configurados en esta sección se aplican '
            'al realizar una nueva cotización.',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _guardarConfiguracionCotizador,
              icon: const Icon(Icons.save_outlined),
              label: const Text('GUARDAR CONFIGURACIÓN'),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // LIBERACIÓN DE RECURSOS
  // ========================================================

  @override
  void dispose() {
    // Controladores utilizados en cada cotización.
    nombreDisenoController.dispose();
    gramosController.dispose();
    horasController.dispose();
    minutosController.dispose();
    cantidadController.dispose();
    cantidadInsumoController.dispose();
    valorUfController.dispose();

    // Controladores de supuestos productivos.
    costoKwhController.dispose();
    consumoImpresoraKwhController.dispose();
    desgasteHoraController.dispose();
    margenErrorController.dispose();

    // Controladores de supuestos financieros y tributarios.
    gastosFinancierosMensualesController.dispose();
    unidadesMensualesEstimadasController.dispose();
    ivaProductoController.dispose();
    comisionTarjetaController.dispose();
    cargoFijoTarjetaUfController.dispose();

    super.dispose();
  }

  // ========================================================
  // INTERFAZ DEL COTIZADOR
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cotizador MAELUX')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ------------------------------------------------
                // DATOS DE LA PIEZA
                // ------------------------------------------------
                const Text(
                  'DATOS DE LA PIEZA',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: nombreDisenoController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del diseño',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<Material3D>(
                  initialValue: materialSeleccionado,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de filamento',
                    border: OutlineInputBorder(),
                  ),
                  items: materialesDemo.map((material) {
                    return DropdownMenuItem<Material3D>(
                      value: material,
                      child: Text(
                        '${material.nombre} - '
                        '\$${material.precioKg.toStringAsFixed(0)}/kg',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (nuevoMaterial) {
                    if (nuevoMaterial == null) {
                      return;
                    }

                    setState(() {
                      materialSeleccionado = nuevoMaterial;
                    });
                  },
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: gramosController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Gramos totales de filamento',
                    helperText:
                        'Incluye modelo, soportes, purga y torre de limpieza.',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Las horas y los minutos se ingresan por separado.
                // La aplicación los transforma en minutos totales.
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: horasController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Horas',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: TextField(
                        controller: minutosController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minutos',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de unidades',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // INSUMOS DEL PRODUCTO
                // ------------------------------------------------
                _construirInsumosProducto(),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // CONFIGURACIÓN COMERCIAL
                // ------------------------------------------------
                const Text(
                  'CONFIGURACIÓN COMERCIAL',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<double>(
                  initialValue: multiplicadorComercial,
                  decoration: const InputDecoration(
                    labelText: 'Multiplicador comercial',
                    border: OutlineInputBorder(),
                  ),
                  items: multiplicadores.map((multiplicador) {
                    return DropdownMenuItem<double>(
                      value: multiplicador,
                      child: Text('x${multiplicador.toStringAsFixed(0)}'),
                    );
                  }).toList(),
                  onChanged: (nuevoMultiplicador) {
                    if (nuevoMultiplicador == null) {
                      return;
                    }

                    setState(() {
                      multiplicadorComercial = nuevoMultiplicador;
                    });
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: medioPagoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Medio de pago',
                    border: OutlineInputBorder(),
                  ),
                  items: mediosPago.map((medioPago) {
                    return DropdownMenuItem<String>(
                      value: medioPago,
                      child: Text(medioPago),
                    );
                  }).toList(),
                  onChanged: (nuevoMedioPago) {
                    if (nuevoMedioPago == null) {
                      return;
                    }

                    setState(() {
                      medioPagoSeleccionado = nuevoMedioPago;
                    });
                  },
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: calcularCosto,
                  child: const Text('Calcular'),
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // RESUMEN RÁPIDO DE LA COTIZACIÓN
                // ------------------------------------------------
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'RESUMEN PARA COBRAR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          nombreDisenoCotizado.isEmpty
                              ? 'Producto sin calcular'
                              : nombreDisenoCotizado,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _datoResumen(
                                etiqueta: 'Cantidad',
                                valor: '$cantidadUnidades',
                              ),
                            ),
                            Expanded(
                              child: _datoResumen(
                                etiqueta: 'Medio de pago',
                                valor: medioPagoSeleccionado,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _datoResumen(
                                etiqueta: 'Precio unitario',
                                valor:
                                    '\$${precioFinalUnitario.toStringAsFixed(0)}',
                              ),
                            ),
                            Expanded(
                              child: _datoResumen(
                                etiqueta: 'IVA total del pedido',
                                valor: '\$${costoIvaVenta.toStringAsFixed(0)}',
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 32),

                        const Text(
                          'TOTAL FINAL DEL PEDIDO',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '\$${precioFinalPedido.toStringAsFixed(0)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'IVA del producto incluido',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // DETALLE ADMINISTRATIVO
                // ------------------------------------------------
                _construirDetalleAdministrativo(),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // SUPUESTOS EDITABLES
                // ------------------------------------------------
                _construirSupuestosEditables(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
