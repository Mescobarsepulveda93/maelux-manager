import 'package:flutter/material.dart';
import '../data/productos_demo.dart';
import '../widgets/producto_card.dart';

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

          return ProductoCard(producto: producto);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Agregar producto");
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
