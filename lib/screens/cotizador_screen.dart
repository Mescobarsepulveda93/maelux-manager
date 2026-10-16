import 'package:flutter/material.dart';
import '../services/costos_service.dart';

class CotizadorScreen extends StatefulWidget {
  const CotizadorScreen({super.key});

  @override
  State<CotizadorScreen> createState() => _CotizadorScreenState();
}

class _CotizadorScreenState extends State<CotizadorScreen> {
  final gramosController = TextEditingController();
  final minutosController = TextEditingController();

  double costoTotal = 0;

  void calcularCosto() {
    double gramos = double.tryParse(gramosController.text) ?? 0;

    double minutos = double.tryParse(minutosController.text) ?? 0;

    double costoMaterial = CostosService.calcularMaterial(gramos, 10000);

    double costoTiempo = CostosService.calcularTiempo(minutos);

    setState(() {
      costoTotal = CostosService.calcularTotal(costoMaterial, costoTiempo);
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

            Text(
              "Costo Total: \$${costoTotal.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
