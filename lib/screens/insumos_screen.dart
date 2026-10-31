import 'package:flutter/material.dart';

import '../data/insumos_repository.dart';
import '../models/insumo.dart';
import '../widgets/insumo_card.dart';
import 'insumo_form_screen.dart';

// ==========================================================
// PANTALLA DE GESTIÓN DE INSUMOS
// ==========================================================

/// Permite consultar y administrar los insumos utilizados
/// en la fabricación y presentación de productos MAELUX.
///
/// La pantalla utiliza [InsumosRepository] como fuente
/// compartida de datos. Esto permite que Gestión de insumos
/// y el Cotizador accedan a la misma colección.
///
/// Durante esta fase, los cambios permanecen disponibles
/// mientras la aplicación continúa ejecutándose.
class InsumosScreen extends StatefulWidget {
  const InsumosScreen({super.key});

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  // ========================================================
  // REPOSITORIO COMPARTIDO
  // ========================================================

  /// Repositorio único utilizado para consultar y modificar
  /// los insumos registrados durante la sesión.
  final InsumosRepository repositorio = InsumosRepository.instancia;

  // ========================================================
  // VALORES CALCULADOS
  // ========================================================

  /// Devuelve la cantidad de insumos disponibles
  /// para su futura selección en el cotizador.
  int get cantidadInsumosActivos {
    return repositorio.cantidadActivos;
  }

  // ========================================================
  // CREACIÓN DE INSUMOS
  // ========================================================

  /// Abre el formulario vacío y agrega al repositorio
  /// el insumo devuelto por el formulario.
  Future<void> _agregarInsumo() async {
    final Insumo? nuevoInsumo = await Navigator.push<Insumo>(
      context,
      MaterialPageRoute(builder: (context) => const InsumoFormScreen()),
    );

    // Si el usuario regresa sin guardar, el formulario
    // devuelve un valor nulo y no se modifica el repositorio.
    if (nuevoInsumo == null || !mounted) {
      return;
    }

    setState(() {
      repositorio.agregar(nuevoInsumo);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Insumo "${nuevoInsumo.nombre}" '
          'agregado correctamente.',
        ),
      ),
    );
  }

  // ========================================================
  // EDICIÓN DE INSUMOS
  // ========================================================

  /// Abre el formulario con los datos del insumo seleccionado
  /// y actualiza el registro cuando se guardan los cambios.
  Future<void> _editarInsumo(int indice) async {
    final List<Insumo> insumosActuales = repositorio.obtenerTodos();

    if (indice < 0 || indice >= insumosActuales.length) {
      return;
    }

    final Insumo insumoActual = insumosActuales[indice];

    final Insumo? insumoEditado = await Navigator.push<Insumo>(
      context,
      MaterialPageRoute(
        builder: (context) => InsumoFormScreen(insumoInicial: insumoActual),
      ),
    );

    // Si se regresa sin guardar, se conserva
    // el registro original.
    if (insumoEditado == null || !mounted) {
      return;
    }

    setState(() {
      repositorio.actualizar(indice: indice, insumo: insumoEditado);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Insumo "${insumoEditado.nombre}" '
          'actualizado correctamente.',
        ),
      ),
    );
  }

  // ========================================================
  // CAMBIO DE ESTADO
  // ========================================================

  /// Activa o desactiva un insumo sin eliminarlo.
  ///
  /// Un insumo desactivado continúa registrado, pero no
  /// será entregado por la consulta de insumos activos.
  void _cambiarEstadoInsumo({required int indice, required bool activo}) {
    setState(() {
      repositorio.cambiarEstado(indice: indice, activo: activo);
    });
  }

  // ========================================================
  // ELIMINACIÓN DE INSUMOS
  // ========================================================

  /// Solicita confirmación antes de eliminar definitivamente
  /// un insumo del repositorio compartido.
  Future<void> _confirmarEliminacion(int indice) async {
    final List<Insumo> insumosActuales = repositorio.obtenerTodos();

    if (indice < 0 || indice >= insumosActuales.length) {
      return;
    }

    final Insumo insumo = insumosActuales[indice];

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar insumo'),
          content: Text(
            '¿Deseas eliminar "${insumo.nombre}"? '
            'Esta acción no puede deshacerse durante '
            'la sesión actual.',
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

    // Si se cancela la operación o se cierra el cuadro
    // de diálogo, el repositorio no se modifica.
    if (confirmar != true || !mounted) {
      return;
    }

    setState(() {
      repositorio.eliminar(indice);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Insumo "${insumo.nombre}" eliminado.')),
    );
  }

  // ========================================================
  // INTERFAZ DE LA PANTALLA
  // ========================================================

  @override
  Widget build(BuildContext context) {
    // Se obtiene una copia actualizada para construir
    // la lista visible durante esta reconstrucción.
    final List<Insumo> insumosActuales = repositorio.obtenerTodos();

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de insumos')),
      body: Column(
        children: [
          // ------------------------------------------------
          // RESUMEN DE INSUMOS
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
                            'Insumos disponibles',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          '$cantidadInsumosActivos '
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
          // LISTA DE INSUMOS
          // ------------------------------------------------
          Expanded(
            child: insumosActuales.isEmpty
                ? const Center(child: Text('No hay insumos registrados.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: insumosActuales.length,
                    itemBuilder: (context, indice) {
                      final Insumo insumo = insumosActuales[indice];

                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: InsumoCard(
                            insumo: insumo,

                            // Abre el formulario con los datos actuales
                            // del insumo seleccionado.
                            alEditar: () {
                              _editarInsumo(indice);
                            },

                            // Solicita confirmación antes de eliminar
                            // definitivamente el registro.
                            alEliminar: () {
                              _confirmarEliminacion(indice);
                            },

                            // Actualiza la disponibilidad del insumo.
                            alCambiarEstado: (activo) {
                              _cambiarEstadoInsumo(
                                indice: indice,
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
      // un insumo nuevo.
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarInsumo,
        tooltip: 'Agregar insumo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
