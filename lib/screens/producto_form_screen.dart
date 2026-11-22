import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/categorias_productos.dart';
import '../data/materiales_demo.dart';
import '../models/producto.dart';

// ==========================================================
// FORMULARIO PARA CREAR Y EDITAR PRODUCTOS
// ==========================================================

/// Permite registrar un producto nuevo o modificar
/// un producto existente.
///
/// Si [productoInicial] es nulo, funciona en modo creación.
///
/// Si [productoInicial] contiene un producto, carga sus datos
/// y conserva su identificador durante la edición.
class ProductoFormScreen extends StatefulWidget {
  // ========================================================
  // DATOS RECIBIDOS
  // ========================================================

  /// Producto que se desea editar.
  final Producto? productoInicial;

  const ProductoFormScreen({super.key, this.productoInicial});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  // ========================================================
  // GENERACIÓN DE IDENTIFICADORES
  // ========================================================

  /// Generador utilizado para asignar un identificador
  /// único a cada producto nuevo.
  final Uuid _uuid = const Uuid();

  // ========================================================
  // CLAVE DE VALIDACIÓN
  // ========================================================

  /// Permite validar conjuntamente todos los campos.
  final _formKey = GlobalKey<FormState>();

  // ========================================================
  // CONTROLADORES DEL FORMULARIO
  // ========================================================

  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final imagenController = TextEditingController();
  final gramosController = TextEditingController();
  final horasController = TextEditingController();
  final minutosController = TextEditingController();
  final costoProduccionController = TextEditingController();
  final precioVentaController = TextEditingController();

  // ========================================================
  // OPCIONES SELECCIONABLES
  // ========================================================

  String categoriaSeleccionada = categoriasProductos.first;
  String materialSeleccionado = materialesDemo.first.nombre;
  bool productoActivo = true;

  // ========================================================
  // ESTADO DEL FORMULARIO
  // ========================================================

  /// Indica si se está modificando un producto existente.
  bool get estaEditando {
    return widget.productoInicial != null;
  }

  // ========================================================
  // INICIALIZACIÓN
  // ========================================================

  @override
  void initState() {
    super.initState();

    final Producto? producto = widget.productoInicial;

    if (producto == null) {
      return;
    }

    nombreController.text = producto.nombre;
    descripcionController.text = producto.descripcion;
    imagenController.text = producto.imagenPrincipal ?? '';
    gramosController.text = _numeroComoTexto(producto.gramos);
    horasController.text = _numeroComoTexto(producto.horas);
    minutosController.text = _numeroComoTexto(producto.minutos);
    costoProduccionController.text = _numeroComoTexto(producto.costoProduccion);
    precioVentaController.text = _numeroComoTexto(producto.precioVenta);

    // Las categorías antiguas se conservan temporalmente.
    categoriaSeleccionada = producto.categoria;

    final bool materialDisponible = materialesDemo.any(
      (material) => material.nombre == producto.material,
    );

    // El material guardado se utiliza si todavía se encuentra
    // dentro de la colección de materiales disponibles.
    if (materialDisponible) {
      materialSeleccionado = producto.material;
    }

    productoActivo = producto.activo;
  }

  // ========================================================
  // CONVERSIÓN DE NÚMEROS
  // ========================================================

  /// Convierte un valor en texto sin decimales innecesarios.
  String _numeroComoTexto(double valor) {
    if (valor == valor.truncateToDouble()) {
      return valor.toStringAsFixed(0);
    }

    return valor.toString();
  }

  /// Convierte el texto recibido en un número decimal.
  double _leerNumero(String texto) {
    return double.tryParse(texto.trim().replaceAll(',', '.')) ?? 0;
  }

  // ========================================================
  // VALIDACIONES
  // ========================================================

  /// Comprueba que el campo contenga un número válido
  /// igual o superior a cero.
  String? _validarNumeroNoNegativo(
    String? valor, {
    required String nombreCampo,
  }) {
    final String texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Completa $nombreCampo.';
    }

    final double? numero = double.tryParse(texto.replaceAll(',', '.'));

    if (numero == null || !numero.isFinite) {
      return 'Introduce un número válido.';
    }

    if (numero < 0) {
      return 'El valor no puede ser negativo.';
    }

    return null;
  }

  /// Comprueba que el campo contenga un número válido
  /// estrictamente mayor que cero.
  String? _validarNumeroPositivo(String? valor, {required String nombreCampo}) {
    final String? error = _validarNumeroNoNegativo(
      valor,
      nombreCampo: nombreCampo,
    );

    if (error != null) {
      return error;
    }

    final double numero = _leerNumero(valor ?? '');

    if (numero <= 0) {
      return 'El valor debe ser mayor que cero.';
    }

    return null;
  }

  // ========================================================
  // GUARDADO
  // ========================================================

  /// Valida los campos, construye el producto y devuelve
  /// el resultado a la pantalla del catálogo.
  void _guardarProducto() {
    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      return;
    }

    final double gramos = _leerNumero(gramosController.text);

    final double horas = _leerNumero(horasController.text);

    final double minutos = _leerNumero(minutosController.text);

    // El tiempo total debe ser mayor que cero.
    if ((horas * 60) + minutos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce un tiempo de fabricación mayor que cero.'),
        ),
      );

      return;
    }

    if (minutos >= 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Los minutos deben ser inferiores a 60. '
            'Utiliza el campo de horas para tiempos mayores.',
          ),
        ),
      );

      return;
    }

    final String referenciaImagen = imagenController.text.trim();

    final Producto productoGuardado = Producto(
      // En edición se conserva el identificador original.
      // En creación se genera un UUID nuevo.
      id: widget.productoInicial?.id ?? _uuid.v4(),
      nombre: nombreController.text.trim(),
      categoria: categoriaSeleccionada,
      descripcion: descripcionController.text.trim(),
      imagenPrincipal: referenciaImagen.isEmpty ? null : referenciaImagen,
      material: materialSeleccionado,
      gramos: gramos,
      horas: horas,
      minutos: minutos,
      costoProduccion: _leerNumero(costoProduccionController.text),
      precioVenta: _leerNumero(precioVentaController.text),
      activo: productoActivo,
    );

    Navigator.pop(context, productoGuardado);
  }

  // ========================================================
  // LIBERACIÓN DE RECURSOS
  // ========================================================

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    imagenController.dispose();
    gramosController.dispose();
    horasController.dispose();
    minutosController.dispose();
    costoProduccionController.dispose();
    precioVentaController.dispose();

    super.dispose();
  }

  // ========================================================
  // INTERFAZ DEL FORMULARIO
  // ========================================================

  @override
  Widget build(BuildContext context) {
    final List<String> categoriasDisponibles = [
      // Una categoría antigua se conserva temporalmente.
      if (!categoriasProductos.contains(categoriaSeleccionada))
        categoriaSeleccionada,

      ...categoriasProductos,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(estaEditando ? 'Editar producto' : 'Agregar producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ------------------------------------------
                  // IDENTIFICACIÓN
                  // ------------------------------------------
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
                      labelText: 'Nombre del producto',
                      hintText: 'Ejemplo: Llavero personalizado',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Introduce el nombre del producto.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: categoriaSeleccionada,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                    items: categoriasDisponibles.map((categoria) {
                      return DropdownMenuItem<String>(
                        value: categoria,
                        child: Text(categoria, overflow: TextOverflow.ellipsis),
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

                  TextFormField(
                    controller: descripcionController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Describe sus características principales.',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------
                  // IMAGEN PRINCIPAL
                  // ------------------------------------------
                  const Text(
                    'IMAGEN PRINCIPAL',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: imagenController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'URL de la imagen',
                      hintText: 'https://...',
                      helperText:
                          'Temporalmente se admite una URL web. '
                          'El selector de archivos se añadirá después.',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------
                  // FABRICACIÓN
                  // ------------------------------------------
                  const Text(
                    'FABRICACIÓN',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: materialSeleccionado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Material',
                      border: OutlineInputBorder(),
                    ),
                    items: materialesDemo.map((material) {
                      return DropdownMenuItem<String>(
                        value: material.nombre,
                        child: Text(material.nombre),
                      );
                    }).toList(),
                    onChanged: (material) {
                      if (material == null) {
                        return;
                      }

                      setState(() {
                        materialSeleccionado = material;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: gramosController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Gramos de filamento',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      return _validarNumeroPositivo(
                        valor,
                        nombreCampo: 'los gramos de filamento',
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: horasController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Horas',
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            return _validarNumeroNoNegativo(
                              valor,
                              nombreCampo: 'las horas',
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: TextFormField(
                          controller: minutosController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Minutos',
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            return _validarNumeroNoNegativo(
                              valor,
                              nombreCampo: 'los minutos',
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------
                  // INFORMACIÓN ECONÓMICA
                  // ------------------------------------------
                  const Text(
                    'INFORMACIÓN ECONÓMICA',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: costoProduccionController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Costo de producción',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      return _validarNumeroNoNegativo(
                        valor,
                        nombreCampo: 'el costo de producción',
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: precioVentaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio de venta',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      return _validarNumeroPositivo(
                        valor,
                        nombreCampo: 'el precio de venta',
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Disponible en el catálogo'),
                    subtitle: Text(
                      productoActivo
                          ? 'El producto estará activo.'
                          : 'El producto estará desactivado.',
                    ),
                    value: productoActivo,
                    onChanged: (activo) {
                      setState(() {
                        productoActivo = activo;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: _guardarProducto,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      estaEditando ? 'GUARDAR CAMBIOS' : 'AGREGAR PRODUCTO',
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
