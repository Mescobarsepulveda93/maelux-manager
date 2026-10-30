import 'package:flutter/material.dart';

// Importamos las categorías disponibles para los insumos.
import '../data/categorias_insumos.dart';

// Importamos las unidades de medida estandarizadas.
import '../data/unidades_medida.dart';

// Importamos el modelo que representa cada insumo.
import '../models/insumo.dart';

// ==========================================================
// FORMULARIO PARA CREAR Y EDITAR INSUMOS
// ==========================================================

/// Permite registrar un insumo nuevo o modificar uno existente.
///
/// Si [insumoInicial] contiene un valor, el formulario carga
/// sus datos actuales y funciona en modo edición.
///
/// Si [insumoInicial] es nulo, el formulario comienza vacío
/// y permite registrar un insumo nuevo.
class InsumoFormScreen extends StatefulWidget {
  // ========================================================
  // DATOS RECIBIDOS POR EL FORMULARIO
  // ========================================================

  /// Insumo que se desea editar.
  ///
  /// Cuando el valor es nulo, el formulario funciona
  /// en modo creación.
  final Insumo? insumoInicial;

  const InsumoFormScreen({super.key, this.insumoInicial});

  @override
  State<InsumoFormScreen> createState() => _InsumoFormScreenState();
}

class _InsumoFormScreenState extends State<InsumoFormScreen> {
  // ========================================================
  // CLAVE DE VALIDACIÓN
  // ========================================================

  /// Permite validar conjuntamente todos los campos
  /// antes de construir y devolver el insumo.
  final _formKey = GlobalKey<FormState>();

  // ========================================================
  // CONTROLADORES DEL FORMULARIO
  // ========================================================

  final nombreController = TextEditingController();
  final costoCompraController = TextEditingController();
  final cantidadCompradaController = TextEditingController();

  // ========================================================
  // OPCIONES SELECCIONABLES
  // ========================================================

  // La primera categoría disponible se utiliza inicialmente
  // cuando se registra un insumo nuevo.
  String categoriaSeleccionada = categoriasInsumos.first;

  /// Unidad de medida seleccionada inicialmente.
  ///
  /// Para insumos nuevos se utiliza "unidad".
  /// Para insumos existentes se recupera su valor guardado.
  String unidadMedidaSeleccionada = unidadesMedida.first;

  // Los insumos nuevos quedan disponibles en el cotizador
  // de forma predeterminada.
  bool insumoActivo = true;

  // ========================================================
  // RESULTADOS CALCULADOS
  // ========================================================

  // Almacena el coste correspondiente a una unidad
  // del insumo registrado.
  double costoUnitarioCalculado = 0;

  // ========================================================
  // ESTADO DEL FORMULARIO
  // ========================================================

  /// Indica si el formulario está modificando
  /// un insumo existente.
  bool get estaEditando {
    return widget.insumoInicial != null;
  }

  // ========================================================
  // INICIALIZACIÓN DEL FORMULARIO
  // ========================================================

  @override
  void initState() {
    super.initState();

    final Insumo? insumo = widget.insumoInicial;

    // Si se recibió un insumo existente, se cargan sus datos
    // en los campos para permitir su modificación.
    if (insumo != null) {
      nombreController.text = insumo.nombre;

      costoCompraController.text = insumo.costoCompra.toString();

      cantidadCompradaController.text = insumo.cantidadComprada.toString();

      // Solo se utiliza la categoría guardada si continúa
      // existiendo dentro de las categorías disponibles.
      if (categoriasInsumos.contains(insumo.categoria)) {
        categoriaSeleccionada = insumo.categoria;
      }

      // Conservamos exactamente la unidad registrada.
      //
      // Si pertenece a una versión antigua del sistema,
      // no se reemplaza automáticamente.
      //
      // Ejemplo:
      // Si el insumo tiene "frasco", se mantendrá "frasco"
      // hasta que el usuario seleccione otra unidad.
      unidadMedidaSeleccionada = insumo.unidadMedida;

      insumoActivo = insumo.activo;
      costoUnitarioCalculado = insumo.costoUnitario;
    }

    // El coste unitario se recalcula cuando cambia
    // el coste total de compra.
    costoCompraController.addListener(_actualizarCostoUnitario);

    // El coste unitario también se recalcula cuando cambia
    // la cantidad comprada.
    cantidadCompradaController.addListener(_actualizarCostoUnitario);
  }

  // ========================================================
  // CONVERSIÓN DE VALORES NUMÉRICOS
  // ========================================================

  /// Convierte el texto ingresado en un número decimal.
  ///
  /// Acepta valores escritos con punto o coma decimal.
  /// Si el texto no representa un número finito, devuelve cero.
  ///
  /// No deben introducirse separadores de miles. Por ejemplo,
  /// para cinco mil se debe escribir `5000` y no `5.000`.
  double _leerNumero(String texto) {
    final String textoNormalizado = texto.trim().replaceAll(',', '.');

    final double? numero = double.tryParse(textoNormalizado);

    if (numero == null || !numero.isFinite) {
      return 0;
    }

    return numero;
  }

  // ========================================================
  // CÁLCULO DEL COSTO UNITARIO
  // ========================================================

  /// Calcula automáticamente el coste correspondiente
  /// a una unidad del insumo.
  ///
  /// La fórmula utilizada es:
  ///
  /// coste total de compra ÷ cantidad comprada.
  void _actualizarCostoUnitario() {
    final double costoCompra = _leerNumero(costoCompraController.text);

    final double cantidadComprada = _leerNumero(
      cantidadCompradaController.text,
    );

    // La división solo se realiza cuando la cantidad
    // comprada es mayor que cero.
    final double nuevoCostoUnitario = cantidadComprada > 0
        ? costoCompra / cantidadComprada
        : 0;

    // Se evita mostrar resultados matemáticos inválidos.
    final double resultado = nuevoCostoUnitario.isFinite
        ? nuevoCostoUnitario
        : 0;

    // No es necesario reconstruir la interfaz si el resultado
    // calculado no ha cambiado.
    if (resultado == costoUnitarioCalculado) {
      return;
    }

    setState(() {
      costoUnitarioCalculado = resultado;
    });
  }

  // ========================================================
  // VALIDACIONES DEL FORMULARIO
  // ========================================================

  /// Comprueba que el campo contenga un número válido
  /// y que su valor sea mayor que cero.
  ///
  /// Devuelve `null` cuando el campo es correcto.
  /// En caso contrario, devuelve el mensaje que deberá
  /// mostrarse debajo del campo.
  String? _validarNumeroPositivo(String? valor, {required String nombreCampo}) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Completa $nombreCampo.';
    }

    final double? numero = double.tryParse(texto.replaceAll(',', '.'));

    if (numero == null || !numero.isFinite) {
      return 'Introduce un número válido.';
    }

    if (numero <= 0) {
      return 'El valor debe ser mayor que cero.';
    }

    return null;
  }

  // ========================================================
  // GUARDADO DEL INSUMO
  // ========================================================

  /// Valida los campos, construye el insumo y devuelve
  /// el resultado a la pantalla de gestión.
  void _guardarInsumo() {
    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    // El guardado se detiene si alguno de los campos
    // contiene un error de validación.
    if (!formularioValido) {
      return;
    }

    final double costoCompra = _leerNumero(costoCompraController.text);

    final double cantidadComprada = _leerNumero(
      cantidadCompradaController.text,
    );

    // Se construye un objeto nuevo tanto en creación como
    // en edición. La pantalla anterior decidirá si debe
    // agregarlo o reemplazar otro registro.
    final Insumo insumoGuardado = Insumo(
      nombre: nombreController.text.trim(),
      categoria: categoriaSeleccionada,
      unidadMedida: unidadMedidaSeleccionada,
      costoCompra: costoCompra,
      cantidadComprada: cantidadComprada,
      activo: insumoActivo,
    );

    // El formulario se cierra y devuelve el insumo creado
    // o modificado a InsumosScreen.
    Navigator.pop(context, insumoGuardado);
  }

  // ========================================================
  // LIBERACIÓN DE RECURSOS
  // ========================================================

  @override
  void dispose() {
    // Se eliminan primero las funciones que escuchan
    // los cambios de los controladores.
    costoCompraController.removeListener(_actualizarCostoUnitario);

    cantidadCompradaController.removeListener(_actualizarCostoUnitario);

    // Se liberan todos los controladores utilizados
    // por el formulario.
    nombreController.dispose();
    costoCompraController.dispose();
    cantidadCompradaController.dispose();

    super.dispose();
  }

  // ========================================================
  // INTERFAZ DEL FORMULARIO
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ------------------------------------------------------
      // BARRA SUPERIOR
      // ------------------------------------------------------
      appBar: AppBar(
        title: Text(estaEditando ? 'Editar insumo' : 'Agregar insumo'),
      ),

      // ------------------------------------------------------
      // CONTENIDO DESPLAZABLE
      // ------------------------------------------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ------------------------------------------------
              // IDENTIFICACIÓN DEL INSUMO
              // ------------------------------------------------
              const Text(
                'IDENTIFICACIÓN',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: nombreController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre del insumo',
                  hintText: 'Ejemplo: Bolsa transparente',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Introduce el nombre del insumo.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: categoriasInsumos.map((categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (categoria) {
                  if (categoria == null) {
                    return;
                  }

                  setState(() {
                    categoriaSeleccionada = categoria;
                  });
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: unidadMedidaSeleccionada,

                // Permite que el contenido aproveche el ancho disponible
                // y evita desbordamientos en unidades con nombres largos.
                isExpanded: true,

                decoration: const InputDecoration(
                  labelText: 'Unidad de medida',
                  helperText:
                      'Selecciona cómo se controlará el consumo del insumo.',
                  border: OutlineInputBorder(),
                ),

                items: [
                  // Si la unidad guardada ya no pertenece a la lista oficial,
                  // se incorpora temporalmente al desplegable.
                  //
                  // Esto permite conservar unidades de versiones anteriores
                  // sin modificar accidentalmente los registros existentes.
                  if (!unidadesMedida.contains(unidadMedidaSeleccionada))
                    DropdownMenuItem<String>(
                      value: unidadMedidaSeleccionada,
                      child: Text(
                        '$unidadMedidaSeleccionada (unidad antigua)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Se agregan todas las unidades oficiales definidas
                  // en unidades_medida.dart.
                  ...unidadesMedida.map((unidad) {
                    return DropdownMenuItem<String>(
                      value: unidad,
                      child: Text(unidad, overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],

                onChanged: (unidad) {
                  if (unidad == null) {
                    return;
                  }

                  setState(() {
                    unidadMedidaSeleccionada = unidad;
                  });
                },
              ),

              // Si la unidad no existe en el listado oficial,
              // se informa al usuario sin obligarlo a cambiarla.
              //
              // No se realiza ninguna conversión automática porque
              // podría alterar el significado de la cantidad registrada.
              if (!unidadesMedida.contains(unidadMedidaSeleccionada))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Esta unidad pertenece a un registro antiguo. '
                    'Puedes conservarla o seleccionar otra.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // INFORMACIÓN DE COMPRA
              // ------------------------------------------------
              const Text(
                'INFORMACIÓN DE COMPRA',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: costoCompraController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Costo total de compra',
                  hintText: 'Ejemplo: 5000',
                  prefixText: '\$ ',
                  helperText: 'Introduce el valor sin separadores de miles.',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  return _validarNumeroPositivo(
                    valor,
                    nombreCampo: 'el costo total de compra',
                  );
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: cantidadCompradaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Cantidad comprada',
                  hintText: 'Ejemplo: 100 o 2,5',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  return _validarNumeroPositivo(
                    valor,
                    nombreCampo: 'la cantidad comprada',
                  );
                },
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // COSTO UNITARIO CALCULADO
              // ------------------------------------------------
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'COSTO UNITARIO CALCULADO',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '\$${costoUnitarioCalculado.toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'por $unidadMedidaSeleccionada',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // DISPONIBILIDAD DEL INSUMO
              // ------------------------------------------------
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Disponible en el cotizador'),
                subtitle: Text(
                  insumoActivo
                      ? 'El insumo estará activo.'
                      : 'El insumo estará desactivado.',
                ),
                value: insumoActivo,
                onChanged: (activo) {
                  setState(() {
                    insumoActivo = activo;
                  });
                },
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // ACCIÓN PRINCIPAL
              // ------------------------------------------------
              ElevatedButton.icon(
                onPressed: _guardarInsumo,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  estaEditando ? 'GUARDAR CAMBIOS' : 'AGREGAR INSUMO',
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
