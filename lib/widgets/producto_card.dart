import 'package:flutter/material.dart';

import '../models/producto.dart';

// ==========================================================
// TARJETA REUTILIZABLE DE PRODUCTO
// ==========================================================

/// Presenta la información principal de un producto
/// registrado en el catálogo de MAELUX.
///
/// La tarjeta recibe desde la pantalla administradora las
/// acciones de edición, eliminación y cambio de estado.
class ProductoCard extends StatelessWidget {
  // ========================================================
  // DATOS Y ACCIONES
  // ========================================================

  /// Producto que se mostrará dentro de la tarjeta.
  final Producto producto;

  /// Acción ejecutada cuando se solicita editar el producto.
  final VoidCallback? alEditar;

  /// Acción ejecutada cuando se solicita eliminar el producto.
  final VoidCallback? alEliminar;

  /// Acción ejecutada cuando cambia la disponibilidad
  /// del producto dentro del catálogo.
  final ValueChanged<bool>? alCambiarEstado;

  const ProductoCard({
    super.key,
    required this.producto,
    this.alEditar,
    this.alEliminar,
    this.alCambiarEstado,
  });

  // ========================================================
  // FORMATO DE CANTIDADES
  // ========================================================

  /// Presenta una cantidad sin decimales innecesarios.
  ///
  /// Ejemplos:
  ///
  /// `12.0` se presenta como `12`.
  ///
  /// `12.5` se presenta como `12,5`.
  String _formatearCantidad(double cantidad) {
    if (cantidad == cantidad.truncateToDouble()) {
      return cantidad.toStringAsFixed(0);
    }

    String texto = cantidad.toStringAsFixed(2);

    texto = texto.replaceFirst(RegExp(r'0+$'), '');

    texto = texto.replaceFirst(RegExp(r'\.$'), '');

    return texto.replaceAll('.', ',');
  }

  // ========================================================
  // FORMATO DEL TIEMPO
  // ========================================================

  /// Presenta el tiempo de fabricación utilizando horas
  /// y minutos de forma legible.
  String _formatearTiempo() {
    final double horas = producto.horas;
    final double minutos = producto.minutos;

    final List<String> partes = [];

    if (horas > 0) {
      partes.add('${_formatearCantidad(horas)} h');
    }

    if (minutos > 0) {
      partes.add('${_formatearCantidad(minutos)} min');
    }

    if (partes.isEmpty) {
      return '0 min';
    }

    return partes.join(' ');
  }

  // ========================================================
  // FORMATO DE VALORES MONETARIOS
  // ========================================================

  /// Presenta un importe utilizando el formato habitual
  /// de pesos chilenos.
  ///
  /// Los valores enteros se muestran sin decimales.
  /// Los valores fraccionarios conservan dos decimales.
  String _formatearPesos(double monto) {
    if (!monto.isFinite) {
      return '\$0';
    }

    final bool tieneDecimales = monto != monto.truncateToDouble();

    final String texto = monto.toStringAsFixed(tieneDecimales ? 2 : 0);

    final List<String> partes = texto.split('.');

    final String enteros = partes[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (coincidencia) => '${coincidencia[1]}.',
    );

    final String decimales = partes.length > 1 ? ',${partes[1]}' : '';

    return '\$$enteros$decimales';
  }

  // ========================================================
  // IMAGEN DEL PRODUCTO
  // ========================================================

  /// Construye la representación visual principal del producto.
  ///
  /// Durante esta primera etapa se muestran directamente las
  /// imágenes cuya referencia sea una URL web válida.
  ///
  /// Si no existe una imagen o no puede cargarse, se presenta
  /// un marcador visual de reemplazo.
  Widget _construirImagen(BuildContext context) {
    final String? referencia = producto.imagenPrincipal?.trim();

    final bool esUrlWeb =
        referencia != null &&
        (referencia.startsWith('http://') || referencia.startsWith('https://'));

    if (esUrlWeb) {
      return Image.network(
        referencia,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _construirMarcadorImagen(context);
        },
      );
    }

    return _construirMarcadorImagen(context);
  }

  /// Construye el marcador utilizado cuando el producto
  /// todavía no posee una imagen principal disponible.
  Widget _construirMarcadorImagen(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),

          const SizedBox(height: 8),

          Text(
            producto.tieneImagen
                ? 'Imagen no disponible'
                : 'Sin imagen principal',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // INTERFAZ DE LA TARJETA
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ------------------------------------------------
          // IMAGEN PRINCIPAL
          // ------------------------------------------------
          _construirImagen(context),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --------------------------------------------
                // IDENTIFICACIÓN Y ACCIONES
                // --------------------------------------------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto.nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            producto.categoria,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: alEditar,
                      tooltip: 'Editar producto',
                      icon: const Icon(Icons.edit_outlined),
                    ),

                    IconButton(
                      onPressed: alEliminar,
                      tooltip: 'Eliminar producto',
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),

                // --------------------------------------------
                // DESCRIPCIÓN
                // --------------------------------------------
                if (producto.descripcion.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),

                  Text(
                    producto.descripcion,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],

                const Divider(height: 24),

                // --------------------------------------------
                // INFORMACIÓN DE FABRICACIÓN
                // --------------------------------------------
                _DatoProducto(etiqueta: 'Material', valor: producto.material),

                const SizedBox(height: 8),

                _DatoProducto(
                  etiqueta: 'Peso',
                  valor: '${_formatearCantidad(producto.gramos)} g',
                ),

                const SizedBox(height: 8),

                _DatoProducto(etiqueta: 'Tiempo', valor: _formatearTiempo()),

                const SizedBox(height: 8),

                _DatoProducto(
                  etiqueta: 'Costo de producción',
                  valor: _formatearPesos(producto.costoProduccion),
                ),

                const Divider(height: 24),

                // --------------------------------------------
                // PRECIO DE VENTA
                // --------------------------------------------
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Precio de venta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Text(
                      _formatearPesos(producto.precioVenta),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // --------------------------------------------
                // ESTADO DEL PRODUCTO
                // --------------------------------------------
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Disponible en el catálogo'),
                  subtitle: Text(
                    producto.activo
                        ? 'Producto activo'
                        : 'Producto desactivado',
                  ),
                  value: producto.activo,
                  onChanged: alCambiarEstado,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// DATO COMPACTO DEL PRODUCTO
// ==========================================================

/// Presenta una etiqueta y su valor dentro de la tarjeta
/// manteniendo una distribución uniforme.
class _DatoProducto extends StatelessWidget {
  // ========================================================
  // DATOS DEL COMPONENTE
  // ========================================================

  final String etiqueta;
  final String valor;

  const _DatoProducto({required this.etiqueta, required this.valor});

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
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
