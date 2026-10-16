import 'package:flutter/material.dart';
import '../services/costos_service.dart';
import '../models/material_3d.dart';
import '../data/materiales_demo.dart';

class CotizadorScreen extends StatefulWidget {
  const CotizadorScreen({super.key});

  @override
  State<CotizadorScreen> createState() => _CotizadorScreenState();
}

class _CotizadorScreenState extends State<CotizadorScreen> {
  final gramosController = TextEditingController();
  final minutosController = TextEditingController();
  Material3D materialSeleccionado = materialesDemo.first;

  double costoMaterial = 0;
  double costoTiempo = 0;
  double costoTotal = 0;

  void calcularCosto() {
    double gramos = double.tryParse(gramosController.text) ?? 0;

    double minutos = double.tryParse(minutosController.text) ?? 0;

    double material = CostosService.calcularMaterial(
      gramos,
      materialSeleccionado,
    );

    double tiempo = CostosService.calcularTiempo(minutos);

    setState(() {
      costoMaterial = material;

      costoTiempo = tiempo;

      costoTotal = CostosService.calcularTotal(material, tiempo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cotizador MAELUX")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<Material3D>(
              value: materialSeleccionado,
              isExpanded: true,
              items: materialesDemo.map((material) {
                return DropdownMenuItem<Material3D>(
                  value: material,
                  child: Text("${material.nombre} - \$${material.precioKg}"),
                );
              }).toList(),
              onChanged: (nuevoMaterial) {
                setState(() {
                  materialSeleccionado = nuevoMaterial!;
                });
              },
            ),
            TextField(
              controller: gramosController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Gramos"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: minutosController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Minutos"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: calcularCosto,
              child: const Text("Calcular"),
            ),

            const SizedBox(height: 20),

            Text("Material: \$${costoMaterial.toStringAsFixed(0)}"),

            const SizedBox(height: 10),

            Text("Tiempo: \$${costoTiempo.toStringAsFixed(0)}"),

            const Divider(),

            Text(
              "Total: \$${costoTotal.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
