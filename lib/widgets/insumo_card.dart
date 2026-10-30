import 'package:flutter/material.dart';

import '../models/insumo.dart';

// ==========================================================
// TARJETA REUTILIZABLE DE INSUMO
// ==========================================================

/// Presenta la información principal de un insumo registrado.
///
/// La tarjeta no modifica directamente los datos. Las acciones
/// de edición y cambio de estado se reciben desde la pantalla
/// que administra la lista de insumos.
class InsumoCard extends StatelessWidget {
  // ========================================================
  // DATOS Y ACCIONES
  // ========================================================

  /// Insumo que se mostrará dentro de la tarjeta.
  final Insumo insumo;

  /// Acción ejecutada cuando se solicita editar el insumo.
  final VoidCallback? alEditar;

  /// Acción ejecutada cuando se solicita eliminar el insumo.
  final VoidCallback? alEliminar;

  /// Acción ejecutada cuando cambia el estado del insumo.
  final ValueChanged<bool>? alCambiarEstado;

  const InsumoCard({
    super.key,
    required this.insumo,
    this.alEditar,
    this.alEliminar,
    this.alCambiarEstado,
  });

  // ========================================================
  // FORMATO DE CANTIDADES
  // ========================================================

  /// Convierte una cantidad numérica en texto legible.
  ///
  /// OBJETIVO:
  /// Mostrar cantidades sin perder sus decimales.
  ///
  /// EJEMPLOS:
  /// 100.0  → 100
  /// 2.5    → 2,5
  /// 0.75   → 0,75
  ///
  /// IMPORTANTE:
  /// Esta función solo modifica la presentación.
  /// No cambia el valor almacenado en el modelo.
  String _formatearCantidad(double cantidad) {
    // Convertimos el número original en texto.
    final String texto = cantidad.toString();

    // Si termina en .0, significa que es un
    // número entero y eliminamos ese decimal.
    if (texto.endsWith('.0')) {
      return texto.substring(0, texto.length - 2);
    }

    // Para cantidades decimales utilizamos coma,
    // siguiendo el formato habitual en Chile.
    return texto.replaceAll('.', ',');
  }

  // ========================================================
  // INTERFAZ DE LA TARJETA
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ------------------------------------------------
            // IDENTIFICACIÓN DEL INSUMO
            // ------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insumo.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        insumo.categoria,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: alEditar,
                  tooltip: 'Editar insumo',
                  icon: const Icon(Icons.edit_outlined),
                ),

                IconButton(
                  onPressed: alEliminar,
                  tooltip: 'Eliminar insumo',
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // ------------------------------------------------
            // INFORMACIÓN DE COMPRA
            // ------------------------------------------------
            _DatoInsumo(
              etiqueta: 'Costo de compra',
              valor: '\$${insumo.costoCompra.toStringAsFixed(0)}',
            ),

            const SizedBox(height: 8),

            // ------------------------------------------------
            // CANTIDAD COMPRADA
            // ------------------------------------------------

            /// Mostramos la cantidad con sus decimales
            /// originales, sin redondear.
            ///
            /// La unidad de medida se obtiene del modelo
            /// para conservar la información registrada.
            _DatoInsumo(
              etiqueta: 'Cantidad comprada',
              valor:
                  '${_formatearCantidad(insumo.cantidadComprada)} '
                  '${insumo.unidadMedida}',
            ),

            const SizedBox(height: 8),

            _DatoInsumo(
              etiqueta: 'Costo unitario',
              valor:
                  '\$${insumo.costoUnitario.toStringAsFixed(0)} '
                  'por ${insumo.unidadMedida}',
              destacado: true,
            ),

            const Divider(height: 24),

            // ------------------------------------------------
            // ESTADO DEL INSUMO
            // ------------------------------------------------
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Disponible en el cotizador'),
              subtitle: Text(
                insumo.activo ? 'Insumo activo' : 'Insumo desactivado',
              ),
              value: insumo.activo,
              onChanged: alCambiarEstado,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// DATO COMPACTO DEL INSUMO
// ==========================================================

/// Presenta una etiqueta y su valor manteniendo una
/// distribución uniforme dentro de la tarjeta.
class _DatoInsumo extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;

  const _DatoInsumo({
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(etiqueta)),

        const SizedBox(width: 16),

        Text(
          valor,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
