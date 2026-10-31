import 'package:flutter/material.dart';

import '../models/insumo.dart';

// ==========================================================
// TARJETA REUTILIZABLE DE INSUMO
// ==========================================================

/// Presenta la información principal de un insumo registrado.
///
/// La tarjeta no modifica directamente los datos. Las acciones
/// de edición, eliminación y cambio de estado se reciben desde
/// la pantalla encargada de administrar la lista de insumos.
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

  /// Acción ejecutada cuando cambia la disponibilidad
  /// del insumo dentro del cotizador.
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

  /// Convierte una cantidad numérica en un texto legible.
  ///
  /// Los valores enteros se muestran sin decimales y los
  /// valores fraccionarios utilizan coma como separador.
  ///
  /// Ejemplos:
  ///
  /// `100.0` se presenta como `100`.
  ///
  /// `2.5` se presenta como `2,5`.
  ///
  /// `0.75` se presenta como `0,75`.
  ///
  /// Esta función modifica únicamente la presentación.
  /// El valor almacenado en el modelo permanece intacto.
  String _formatearCantidad(double cantidad) {
    final String texto = cantidad.toString();

    // Si el valor termina en .0, corresponde a una cantidad
    // entera y se elimina esa parte decimal.
    if (texto.endsWith('.0')) {
      return texto.substring(0, texto.length - 2);
    }

    // Las cantidades fraccionarias utilizan coma decimal
    // para mantener el formato habitual en Chile.
    return texto.replaceAll('.', ',');
  }

  // ========================================================
  // FORMATO DE UNIDADES DE MEDIDA
  // ========================================================

  /// Presenta la unidad de medida en singular o plural
  /// según la cantidad comprada.
  ///
  /// Las unidades antiguas que no aparecen en el mapa se
  /// conservan sin modificaciones para evitar generar
  /// nombres incorrectos.
  ///
  /// Esta función modifica únicamente la presentación.
  /// La unidad almacenada en el modelo no cambia.
  String _formatearUnidad(double cantidad, String unidad) {
    // Si la cantidad es exactamente una, se conserva
    // la unidad registrada en singular.
    if (cantidad == 1.0) {
      return unidad;
    }

    // Plurales definidos para las unidades oficiales
    // utilizadas por MAELUX.
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

    // Si la unidad no pertenece al listado oficial,
    // se mantiene exactamente el valor original.
    return plurales[unidad] ?? unidad;
  }

  // ========================================================
  // FORMATO DE VALORES MONETARIOS
  // ========================================================

  /// Presenta un importe utilizando el formato habitual
  /// de pesos chilenos.
  ///
  /// Los valores enteros se muestran sin decimales.
  /// Los valores fraccionarios conservan dos decimales.
  ///
  /// Ejemplos:
  ///
  /// `3000` se presenta como `$3.000`.
  ///
  /// `1200` se presenta como `$1.200`.
  ///
  /// `1250.50` se presenta como `$1.250,50`.
  ///
  /// Esta función no modifica el importe original.
  String _formatearPesos(double monto) {
    // Se evita mostrar valores matemáticos inválidos.
    if (!monto.isFinite) {
      return '\$0';
    }

    final bool tieneDecimales = monto != monto.truncateToDouble();

    // Los importes fraccionarios conservan dos decimales.
    final String texto = monto.toStringAsFixed(tieneDecimales ? 2 : 0);

    // Se separa la parte entera de la parte decimal.
    final List<String> partes = texto.split('.');

    // Se incorpora un punto como separador de miles.
    final String enteros = partes[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (coincidencia) => '${coincidencia[1]}.',
    );

    // Los decimales se muestran separados mediante una coma.
    final String decimales = partes.length > 1 ? ',${partes[1]}' : '';

    return '\$$enteros$decimales';
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
            // IDENTIFICACIÓN Y ACCIONES
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
              valor: _formatearPesos(insumo.costoCompra),
            ),

            const SizedBox(height: 8),

            // La cantidad conserva sus decimales y la unidad
            // se muestra en singular o plural.
            _DatoInsumo(
              etiqueta: 'Cantidad comprada',
              valor:
                  '${_formatearCantidad(insumo.cantidadComprada)} '
                  '${_formatearUnidad(insumo.cantidadComprada, insumo.unidadMedida)}',
            ),

            const SizedBox(height: 8),

            // El coste unitario utiliza siempre la unidad
            // registrada en singular.
            _DatoInsumo(
              etiqueta: 'Costo unitario',
              valor:
                  '${_formatearPesos(insumo.costoUnitario)} '
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

/// Presenta una etiqueta y su valor mediante una distribución
/// uniforme dentro de la tarjeta.
///
/// El valor utiliza un espacio flexible para reducir el riesgo
/// de desbordamientos en pantallas pequeñas.
class _DatoInsumo extends StatelessWidget {
  // ========================================================
  // DATOS DEL COMPONENTE
  // ========================================================

  final String etiqueta;
  final String valor;
  final bool destacado;

  const _DatoInsumo({
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  // ========================================================
  // INTERFAZ DEL COMPONENTE
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(etiqueta)),

        const SizedBox(width: 16),

        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
