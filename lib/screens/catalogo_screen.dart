import 'package:flutter/material.dart';

import '../data/productos_repository.dart';
import '../models/producto.dart';
import '../widgets/producto_card.dart';
import 'producto_form_screen.dart';

// ==========================================================
// PANTALLA PRINCIPAL DEL CATÁLOGO
// ==========================================================

/// Permite consultar y administrar los productos registrados
/// en el catálogo interno de MAELUX.
///
/// La pantalla utiliza [ProductosRepository] como fuente
/// compartida y persistente de información.
///
/// Permite crear, editar, activar, desactivar y eliminar
/// productos del catálogo.
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  // ========================================================
  // REPOSITORIO COMPARTIDO
  // ========================================================

  /// Repositorio utilizado para consultar y modificar
  /// los productos almacenados localmente.
  final ProductosRepository repositorio = ProductosRepository.instancia;

  // ========================================================
  // SINCRONIZACIÓN REACTIVA
  // ========================================================

  @override
  void initState() {
    super.initState();

    // Reconstruye el catálogo cada vez que Firestore
    // comunica un cambio al repositorio compartido.
    repositorio.addListener(_actualizarDesdeRepositorio);
  }

  /// Muestra inmediatamente el último catálogo conocido.
  void _actualizarDesdeRepositorio() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    // Evita mantener una referencia a esta pantalla
    // después de cerrarla.
    repositorio.removeListener(_actualizarDesdeRepositorio);

    super.dispose();
  }

  // ========================================================
  // VALORES CALCULADOS
  // ========================================================

  /// Devuelve la cantidad de productos disponibles
  /// actualmente dentro del catálogo.
  int get cantidadProductosActivos {
    return repositorio.cantidadActivos;
  }

  // ========================================================
  // CREACIÓN DE PRODUCTOS
  // ========================================================

  /// Abre el formulario vacío y añade al repositorio
  /// el producto devuelto después de guardar.
  Future<void> _agregarProducto() async {
    final Producto? nuevoProducto = await Navigator.push<Producto>(
      context,
      MaterialPageRoute(builder: (context) => const ProductoFormScreen()),
    );

    // Si el usuario regresa sin guardar, el formulario
    // devuelve un valor nulo y el catálogo no se modifica.
    if (nuevoProducto == null || !mounted) {
      return;
    }

    await repositorio.agregar(nuevoProducto);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Producto "${nuevoProducto.nombre}" '
          'agregado correctamente.',
        ),
      ),
    );
  }

  // ========================================================
  // EDICIÓN DE PRODUCTOS
  // ========================================================

  /// Abre el formulario con el producto más reciente
  /// identificado mediante su UUID.
  Future<void> _editarProducto(Producto producto) async {
    final Producto? productoActual = repositorio.buscarPorId(producto.id);

    if (productoActual == null) {
      return;
    }

    final Producto? productoEditado = await Navigator.push<Producto>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductoFormScreen(productoInicial: productoActual),
      ),
    );

    if (productoEditado == null || !mounted) {
      return;
    }

    // Otro dispositivo podría haber eliminado el producto
    // mientras el formulario permanecía abierto.
    if (repositorio.buscarPorId(producto.id) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El producto ya no está disponible.')),
      );

      return;
    }

    await repositorio.actualizarPorId(productoEditado);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Producto "${productoEditado.nombre}" '
          'actualizado correctamente.',
        ),
      ),
    );
  }
  // ========================================================
  // CAMBIO DE ESTADO
  // ========================================================

  /// Activa o desactiva un producto mediante su UUID.
  Future<void> _cambiarEstadoProducto({
    required String productoId,
    required bool activo,
  }) async {
    await repositorio.cambiarEstadoPorId(
      productoId: productoId,
      activo: activo,
    );
  }

  // ========================================================
  // ELIMINACIÓN DE PRODUCTOS
  // ========================================================

  /// Solicita confirmación antes de eliminar definitivamente
  /// un producto del catálogo.
  Future<void> _confirmarEliminacion(Producto producto) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar producto'),
          content: Text(
            '¿Deseas eliminar "${producto.nombre}"? '
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('ELIMINAR'),
            ),
          ],
        );
      },
    );

    // Si se cancela o se cierra el cuadro de diálogo,
    // la colección permanece sin modificaciones.
    if (confirmar != true || !mounted) {
      return;
    }

    // La eliminación utiliza el identificador porque es
    // más estable que depender de la posición en la lista.
    await repositorio.eliminarPorId(producto.id);

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Producto "${producto.nombre}" eliminado.')),
    );
  }

  // ========================================================
  // INTERFAZ DEL CATÁLOGO
  // ========================================================

  @override
  Widget build(BuildContext context) {
    // Se obtiene una copia actualizada para construir
    // la interfaz durante esta reconstrucción.
    final List<Producto> productosActuales = repositorio.obtenerTodos();

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: Column(
        children: [
          // ------------------------------------------------
          // RESUMEN DEL CATÁLOGO
          // ------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Productos disponibles',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          '$cantidadProductosActivos '
                          'de ${repositorio.cantidadTotal}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ------------------------------------------------
          // LISTA DE PRODUCTOS
          // ------------------------------------------------
          Expanded(
            child: productosActuales.isEmpty
                ? const Center(child: Text('No hay productos registrados.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: productosActuales.length,
                    itemBuilder: (context, indice) {
                      final Producto producto = productosActuales[indice];

                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: ProductoCard(
                            producto: producto,

                            // Abre el formulario con los datos
                            // actuales del producto.
                            alEditar: () {
                              _editarProducto(producto);
                            },

                            // Solicita confirmación antes
                            // de eliminar el producto.
                            alEliminar: () {
                              _confirmarEliminacion(producto);
                            },

                            // Modifica la disponibilidad
                            // y persiste el nuevo estado.
                            alCambiarEstado: (activo) {
                              _cambiarEstadoProducto(
                                productoId: producto.id,
                                activo: activo,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Abre el formulario vacío para registrar
      // un producto nuevo.
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarProducto,
        tooltip: 'Agregar producto',
        child: const Icon(Icons.add),
      ),
    );
  }
}
