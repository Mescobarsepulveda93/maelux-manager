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
  // SINCRONIZACIÓN REACTIVA
  // ========================================================

  @override
  void initState() {
    super.initState();

    // La pantalla se reconstruye cuando Firestore comunica
    // un cambio al repositorio compartido.
    repositorio.addListener(_actualizarDesdeRepositorio);
  }

  /// Reconstruye la interfaz con el último estado recibido.
  void _actualizarDesdeRepositorio() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    // Evita mantener referencias a una pantalla cerrada.
    repositorio.removeListener(_actualizarDesdeRepositorio);

    super.dispose();
  }

  // ========================================================
  // VALORES CALCULADOS
  // ========================================================

  /// Devuelve la cantidad de insumos disponibles
  /// para su futura selección en el cotizador.
  int get cantidadInsumosActivos {
    return repositorio.cantidadActivos;
  }

  // ========================================================
  // LOCALIZACIÓN DE REGISTROS
  // ========================================================

  /// Busca la posición actual de un insumo mediante su UUID.
  ///
  /// La posición puede cambiar cuando otro dispositivo
  /// modifica el nombre o Firestore actualiza la colección.
  int _buscarIndicePorId(String insumoId) {
    return repositorio.obtenerTodos().indexWhere(
      (insumo) => insumo.id == insumoId,
    );
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

    await repositorio.agregar(nuevoInsumo);

    if (!mounted) {
      return;
    }

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

  /// Abre el formulario con los datos actuales del insumo
  /// identificado mediante su UUID.
  Future<void> _editarInsumo(String insumoId) async {
    final int indiceInicial = _buscarIndicePorId(insumoId);

    final List<Insumo> insumosActuales = repositorio.obtenerTodos();

    if (indiceInicial < 0 || indiceInicial >= insumosActuales.length) {
      return;
    }

    final Insumo insumoActual = insumosActuales[indiceInicial];

    final Insumo? insumoEditado = await Navigator.push<Insumo>(
      context,
      MaterialPageRoute(
        builder: (context) => InsumoFormScreen(insumoInicial: insumoActual),
      ),
    );

    if (insumoEditado == null || !mounted) {
      return;
    }

    // La lista puede haber cambiado mientras el formulario
    // permanecía abierto, por lo que se localiza nuevamente
    // el registro mediante su UUID.
    final int indiceActual = _buscarIndicePorId(insumoId);

    if (indiceActual < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El insumo ya no está disponible.')),
      );

      return;
    }

    await repositorio.actualizar(indice: indiceActual, insumo: insumoEditado);

    if (!mounted) {
      return;
    }

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

  /// Activa o desactiva un insumo identificado por UUID.
  Future<void> _cambiarEstadoInsumo({
    required String insumoId,
    required bool activo,
  }) async {
    final int indiceActual = _buscarIndicePorId(insumoId);

    if (indiceActual < 0) {
      return;
    }

    await repositorio.cambiarEstado(indice: indiceActual, activo: activo);
  }

  // ========================================================
  // ELIMINACIÓN DE INSUMOS
  // ========================================================

  /// Solicita confirmación antes de eliminar definitivamente
  /// un insumo identificado mediante su UUID.
  Future<void> _confirmarEliminacion(String insumoId) async {
    final int indiceInicial = _buscarIndicePorId(insumoId);

    final List<Insumo> insumosActuales = repositorio.obtenerTodos();

    if (indiceInicial < 0 || indiceInicial >= insumosActuales.length) {
      return;
    }

    final Insumo insumo = insumosActuales[indiceInicial];

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar insumo'),
          content: Text(
            '¿Deseas eliminar "${insumo.nombre}"? '
            'Esta acción eliminará el registro compartido.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('ELIMINAR'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) {
      return;
    }

    // Se busca nuevamente porque otro dispositivo podría
    // haber modificado la lista mientras el diálogo estaba
    // abierto.
    final int indiceActual = _buscarIndicePorId(insumoId);

    if (indiceActual < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El insumo ya había sido eliminado.')),
      );

      return;
    }

    await repositorio.eliminar(indiceActual);

    if (!mounted) {
      return;
    }

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

                            alEditar: () {
                              _editarInsumo(insumo.id);
                            },

                            alEliminar: () {
                              _confirmarEliminacion(insumo.id);
                            },

                            alCambiarEstado: (activo) {
                              _cambiarEstadoInsumo(
                                insumoId: insumo.id,
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
