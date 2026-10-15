import 'package:flutter/material.dart';

import '../data/productos_demo.dart';

class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Catálogo")),
      body: ListView.builder(
        itemCount: productosDemo.length,
        itemBuilder: (context, index) {
          final producto = productosDemo[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(producto.nombre),
              subtitle: Text(
                "${producto.material}\n"
                "${producto.gramos} g\n"
                "${producto.minutos} min",
              ),
              trailing: Text(
                "\$${producto.precioVenta.toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
