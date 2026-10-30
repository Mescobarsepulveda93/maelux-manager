import 'package:flutter/material.dart';

import '../data/insumos_demo.dart';
import '../models/insumo.dart';
import '../widgets/insumo_card.dart';
import 'insumo_form_screen.dart';

// ==========================================================
// PANTALLA DE GESTIÓN DE INSUMOS
// ==========================================================

/// Permite consultar y administrar los insumos utilizados
/// en la fabricación y presentación de productos MAELUX.
///
/// Durante esta fase, los cambios se conservan mientras
/// la pantalla permanece abierta. El almacenamiento permanente
/// se incorporará posteriormente.
class InsumosScreen extends StatefulWidget {
  const InsumosScreen({super.key});

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  // ========================================================
  // ESTADO DE LA PANTALLA
  // ========================================================

  /// Copia modificable de los insumos demostrativos.
  ///
  /// Esta lista permite agregar, editar, activar y desactivar
  /// registros sin modificar directamente la lista original.
  late final List<Insumo> insumos;

  // ========================================================
  // INICIALIZACIÓN DE LA PANTALLA
  // ========================================================

  @override
  void initState() {
    super.initState();

    insumos = List<Insumo>.from(insumosDemo);
  }

  // ========================================================
  // VALORES CALCULADOS
  // ========================================================

  /// Devuelve la cantidad de insumos que se encuentran
  /// disponibles para su futura selección en el cotizador.
  int get cantidadInsumosActivos {
    return insumos.where((insumo) => insumo.activo).length;
  }

  // ========================================================
  // CREACIÓN DE INSUMOS
  // ========================================================

  /// Abre el formulario vacío y agrega el insumo devuelto
  /// cuando el usuario completa correctamente el registro.
  Future<void> _agregarInsumo() async {
    final Insumo? nuevoInsumo = await Navigator.push<Insumo>(
      context,
      MaterialPageRoute(builder: (context) => const InsumoFormScreen()),
    );

    // Si el usuario regresa sin guardar, el resultado será nulo
    // y la lista debe mantenerse sin modificaciones.
    if (nuevoInsumo == null || !mounted) {
      return;
    }

    setState(() {
      insumos.add(nuevoInsumo);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Insumo "${nuevoInsumo.nombre}" agregado correctamente.'),
      ),
    );
  }

  // ========================================================
  // EDICIÓN DE INSUMOS
  // ========================================================

  /// Abre el formulario con los datos del insumo seleccionado
  /// y reemplaza el registro cuando se guardan los cambios.
  Future<void> _editarInsumo(int indice) async {
    final Insumo insumoActual = insumos[indice];

    final Insumo? insumoEditado = await Navigator.push<Insumo>(
      context,
      MaterialPageRoute(
        builder: (context) => InsumoFormScreen(insumoInicial: insumoActual),
      ),
    );

    // Si el usuario regresa con la flecha sin guardar,
    // se conserva el registro original.
    if (insumoEditado == null || !mounted) {
      return;
    }

    setState(() {
      insumos[indice] = insumoEditado;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Insumo "${insumoEditado.nombre}" actualizado correctamente.',
        ),
      ),
    );
  }

  // ========================================================
  // ELIMINACIÓN DE INSUMOS
  // ========================================================

  /// Solicita confirmación antes de eliminar un insumo.
  ///
  /// El cuadro de diálogo permite cancelar la operación
  /// para evitar eliminaciones accidentales.
  Future<void> _confirmarEliminacion(int indice) async {
    final Insumo insumo = insumos[indice];

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar insumo'),
          content: Text(
            '¿Deseas eliminar "${insumo.nombre}"? '
            'Esta acción no se puede deshacer durante esta sesión.',
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

    // Si el usuario cancela, cierra el diálogo o la pantalla
    // deja de estar disponible, la lista no se modifica.
    if (confirmar != true || !mounted) {
      return;
    }

    setState(() {
      insumos.removeAt(indice);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Insumo "${insumo.nombre}" eliminado.')),
    );
  }

  // ========================================================
  // ESTADO DE LOS INSUMOS
  // ========================================================

  /// Activa o desactiva un insumo sin eliminarlo de la lista.
  ///
  /// Los insumos desactivados permanecerán registrados,
  /// pero no estarán disponibles posteriormente en el cotizador.
  void _cambiarEstadoInsumo({required int indice, required bool activo}) {
    setState(() {
      insumos[indice] = insumos[indice].copiarCon(activo: activo);
    });
  }

  // ========================================================
  // INTERFAZ DE LA PANTALLA
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de insumos')),
      body: Column(
        children: [
          // ------------------------------------------------
          // RESUMEN DE INSUMOS
          // ------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                      'de ${insumos.length}',
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

          // ------------------------------------------------
          // LISTA DE INSUMOS
          // ------------------------------------------------
          Expanded(
            child: insumos.isEmpty
                ? const Center(child: Text('No hay insumos registrados.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: insumos.length,
                    itemBuilder: (context, indice) {
                      final Insumo insumo = insumos[indice];

                      return InsumoCard(
                        insumo: insumo,

                        // Abre el formulario con los datos actuales.
                        alEditar: () {
                          _editarInsumo(indice);
                        },

                        // Solicita confirmación antes de eliminar.
                        alEliminar: () {
                          _confirmarEliminacion(indice);
                        },

                        // Cambia la disponibilidad del insumo.
                        alCambiarEstado: (activo) {
                          _cambiarEstadoInsumo(indice: indice, activo: activo);
                        },
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
