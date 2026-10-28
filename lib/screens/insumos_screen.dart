import 'package:flutter/material.dart';

import '../data/insumos_demo.dart';
import '../models/insumo.dart';
import '../widgets/insumo_card.dart';

// ==========================================================
// PANTALLA DE GESTIÓN DE INSUMOS
// ==========================================================

/// Permite consultar y administrar los insumos utilizados
/// en la fabricación y presentación de productos MAELUX.
///
/// Durante esta fase, la pantalla utiliza datos demostrativos.
/// Posteriormente, los insumos se guardarán localmente o en
/// la base de datos de la aplicación.
class InsumosScreen extends StatefulWidget {
  const InsumosScreen({super.key});

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  // ========================================================
  // ESTADO DE LA PANTALLA
  // ========================================================

  /// Copia modificable de los datos demostrativos.
  ///
  /// La lista original no se modifica. Esto permite activar
  /// o desactivar insumos durante las pruebas de desarrollo.
  late final List<Insumo> insumos;

  // ========================================================
  // INICIALIZACIÓN
  // ========================================================

  @override
  void initState() {
    super.initState();

    insumos = List<Insumo>.from(insumosDemo);
  }

  // ========================================================
  // ACCIONES DE LOS INSUMOS
  // ========================================================

  /// Cambia la disponibilidad del insumo indicado.
  ///
  /// Un insumo desactivado permanece registrado, pero no
  /// podrá seleccionarse posteriormente en el cotizador.
  void _cambiarEstadoInsumo({required int indice, required bool activo}) {
    setState(() {
      insumos[indice] = insumos[indice].copiarCon(activo: activo);
    });
  }

  /// Informa temporalmente que la edición del insumo
  /// se implementará en la siguiente etapa.
  void _mostrarEdicionPendiente(Insumo insumo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'La edición de "${insumo.nombre}" '
          'estará disponible próximamente.',
        ),
      ),
    );
  }

  /// Informa temporalmente que el formulario para registrar
  /// insumos se implementará en la siguiente etapa.
  void _mostrarCreacionPendiente() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'El formulario para agregar insumos '
          'estará disponible próximamente.',
        ),
      ),
    );
  }

  // ========================================================
  // VALORES CALCULADOS DE LA PANTALLA
  // ========================================================

  /// Cantidad de insumos actualmente disponibles
  /// para su futura selección en el cotizador.
  int get cantidadInsumosActivos {
    return insumos.where((insumo) => insumo.activo).length;
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
                        alEditar: () {
                          _mostrarEdicionPendiente(insumo);
                        },
                        alCambiarEstado: (activo) {
                          _cambiarEstadoInsumo(indice: indice, activo: activo);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),

      // Este botón abrirá posteriormente el formulario
      // utilizado para registrar un insumo nuevo.
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarCreacionPendiente,
        tooltip: 'Agregar insumo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
