import 'package:flutter/material.dart';

import '../models/producto.dart';

class ProductoCard extends StatelessWidget {
  final Producto producto;

  const ProductoCard({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        title: Text(producto.nombre),

        subtitle: Text(
          "Categoría: ${producto.categoria}\n"
          "Material: ${producto.material}\n"
          "Peso: ${producto.gramos} g\n"
          "Tiempo: ${producto.minutos} min",
        ),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Precio", style: TextStyle(fontSize: 12)),
            Text(
              "\$${producto.precioVenta.toStringAsFixed(0)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
