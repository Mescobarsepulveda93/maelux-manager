import 'package:flutter/material.dart';

import '../data/productos_demo.dart';
import '../widgets/producto_card.dart';

// ==========================================================
// PANTALLA PRINCIPAL DEL CATÁLOGO
// ==========================================================

/// Muestra los productos disponibles en el catálogo interno
/// de MAELUX.
///
/// Actualmente utiliza datos temporales almacenados en
/// `productos_demo.dart`. Posteriormente, los productos
/// procederán del almacenamiento local o de la base de datos.
///
class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({super.key});

  // ========================================================
  // ACCIONES DEL CATÁLOGO
  // ========================================================

  /// Informa temporalmente que el formulario para registrar
  /// productos todavía no ha sido implementado.
  ///
  /// Esta acción se reemplazará posteriormente por la navegación
  /// hacia la pantalla de creación de productos.
  ///
  void _mostrarFuncionPendiente(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'La creación de productos estará disponible próximamente.',
        ),
      ),
    );
  }

  // ========================================================
  // INTERFAZ DEL CATÁLOGO
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),

      // La lista se genera dinámicamente a partir de los
      // productos disponibles en la fuente de datos actual.
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: productosDemo.length,
        itemBuilder: (context, index) {
          final producto = productosDemo[index];

          return ProductoCard(producto: producto);
        },
      ),

      // Este botón abrirá posteriormente el formulario
      // utilizado para registrar un producto nuevo.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarFuncionPendiente(context);
        },
        tooltip: 'Agregar producto',
        child: const Icon(Icons.add),
      ),
    );
  }
}
