import 'package:flutter/material.dart';

import '../data/materiales_demo.dart';
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

  // Gastos financieros mensuales que posteriormente se
  // prorratean entre las ventas estimadas del mes.
  final gastosFinancierosMensualesController = TextEditingController(
    text: '30500',
  );

  // Cantidad de ventas utilizada para calcular el gasto
  // financiero correspondiente a cada unidad.
  final ventasMensualesEstimadasController = TextEditingController(text: '100');

  // IVA aplicado a la venta del producto.
  final ivaProductoController = TextEditingController(text: '19');

  // Tarifa conservadora utilizada para pagos con tarjeta.
  final comisionTarjetaController = TextEditingController(text: '1.44');

  // Componente fijo contractual de la comisión,
  // expresado en unidades de fomento.
  final cargoFijoTarjetaUfController = TextEditingController(text: '0.0018');

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

  double costoPackaging = 0;
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

    final double packaging = CostosService.calcularPackaging();

    final double gastosBancarios = CostosService.calcularGastosBancarios();

    final double operacional = packaging + gastosBancarios;

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
    );

    // Extrae únicamente el IVA de la venta del producto.
    // Este es el IVA que mostraremos en la vista comercial.
    final double ivaVenta = CostosService.extraerIvaVenta(
      precioFinal: finalPedido,
    );

    // Calcula la comisión definitiva sobre el importe
    // que efectivamente pagará el cliente.
    final double comisionTarjeta = CostosService.calcularComisionPorMedioPago(
      medioPago: medioPagoSeleccionado,
      montoTransaccion: finalPedido,
      valorUf: valorUf,
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

      costoPackaging = packaging;
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
            'Packaging: '
            '\$${costoPackaging.toStringAsFixed(0)}',
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
            'IVA del producto (19 %): '
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
  /// Durante esta fase los campos se muestran en la interfaz,
  /// pero se conectarán progresivamente con las fórmulas.
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
            controller: ventasMensualesEstimadasController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ventas mensuales estimadas',
              suffixText: 'ventas',
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
            'Electricidad, consumo, desgaste y margen de error '
            'ya se aplican al cálculo. Los supuestos financieros, '
            'tributarios y de tarjeta se conectarán progresivamente.',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
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
    valorUfController.dispose();

    // Controladores de supuestos productivos.
    costoKwhController.dispose();
    consumoImpresoraKwhController.dispose();
    desgasteHoraController.dispose();
    margenErrorController.dispose();

    // Controladores de supuestos financieros y tributarios.
    gastosFinancierosMensualesController.dispose();
    ventasMensualesEstimadasController.dispose();
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
                labelText: 'Gramos de filamento',
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
    );
  }
}
