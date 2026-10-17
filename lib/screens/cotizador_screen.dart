import 'package:flutter/material.dart';
import '../data/materiales_demo.dart';
import '../models/material_3d.dart';
import '../services/costos_service.dart';

class CotizadorScreen extends StatefulWidget {
  const CotizadorScreen({super.key});
  @override
  State<CotizadorScreen> createState() => _CotizadorScreenState();
}

class _CotizadorScreenState extends State<CotizadorScreen> {
  final gramosController = TextEditingController();
  final minutosController = TextEditingController();
  Material3D materialSeleccionado = materialesDemo.first;
  final List<double> multiplicadores = [2, 3, 5];
  double multiplicadorComercial = 3;
  double costoMaterial = 0;
  double costoElectricidad = 0;
  double costoDesgaste = 0;
  double costoMargenError = 0;
  double costoPackaging = 0;
  double costoGastosBancarios = 0;
  double subtotalFabricacion = 0;
  double subtotalOperacional = 0;
  double costoEmpresa = 0;
  double precioSugerido = 0;
  double costoGetnet = 0;
  void calcularCosto() {
    final double gramos =
        double.tryParse(gramosController.text.replaceAll(',', '.')) ?? 0;
    final double minutos =
        double.tryParse(minutosController.text.replaceAll(',', '.')) ?? 0;
    if (gramos <= 0 || minutos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Introduce una cantidad de gramos y minutos mayor que cero.',
          ),
        ),
      );
      return;
    }
    final double material = CostosService.calcularMaterial(
      gramos,
      materialSeleccionado,
    );
    final double electricidad = CostosService.calcularElectricidad(minutos);
    final double desgaste = CostosService.calcularDesgaste(minutos);
    final double margenError = (material + electricidad + desgaste) * 0.05;
    final double packaging = CostosService.calcularPackaging();
    final double gastosBancarios = CostosService.calcularGastosBancarios();
    final double fabricacion = material + electricidad + desgaste + margenError;
    final double operacional = packaging + gastosBancarios;
    final double empresa = fabricacion + operacional;
    final double sugerido = empresa * multiplicadorComercial;
    final double getnet = CostosService.calcularGetnet(sugerido);
    setState(() {
      costoMaterial = material;
      costoElectricidad = electricidad;
      costoDesgaste = desgaste;
      costoMargenError = margenError;
      costoPackaging = packaging;
      costoGastosBancarios = gastosBancarios;
      subtotalFabricacion = fabricacion;
      subtotalOperacional = operacional;
      costoEmpresa = empresa;
      precioSugerido = sugerido;
      costoGetnet = getnet;
    });
  }

  @override
  void dispose() {
    gramosController.dispose();
    minutosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cotizador MAELUX')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Material3D>(
              initialValue: materialSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Tipo de filamento',
                border: OutlineInputBorder(),
              ),
              items: materialesDemo.map((material) {
                return DropdownMenuItem<Material3D>(
                  value: material,
                  child: Text(
                    '${material.nombre} - '
                    '\$${material.precioKg.toStringAsFixed(0)}/kg',
                  ),
                );
              }).toList(),
              onChanged: (nuevoMaterial) {
                if (nuevoMaterial == null) {
                  return;
                }
                setState(() {
                  materialSeleccionado = nuevoMaterial;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: gramosController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Gramos de filamento',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: minutosController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Tiempo total en minutos',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<double>(
              initialValue: multiplicadorComercial,
              decoration: const InputDecoration(
                labelText: 'Multiplicador comercial',
                border: OutlineInputBorder(),
              ),
              items: multiplicadores.map((multiplicador) {
                return DropdownMenuItem<double>(
                  value: multiplicador,
                  child: Text('x${multiplicador.toStringAsFixed(0)}'),
                );
              }).toList(),
              onChanged: (nuevoMultiplicador) {
                if (nuevoMultiplicador == null) {
                  return;
                }
                setState(() {
                  multiplicadorComercial = nuevoMultiplicador;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: calcularCosto,
              child: const Text('Calcular'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'FABRICACIÓN',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Material: \$${costoMaterial.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
            ),
            Text(
              'Electricidad: '
              '\$${costoElectricidad.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
            ),
            Text(
              'Desgaste: \$${costoDesgaste.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
            ),
            Text(
              'Margen de error: '
              '\$${costoMargenError.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Subtotal fabricación: '
              '\$${subtotalFabricacion.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text(
              'OPERACIÓN',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Packaging: \$${costoPackaging.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
            ),
            Text(
              'Gastos bancarios: '
              '\$${costoGastosBancarios.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Subtotal operación: '
              '\$${subtotalOperacional.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Text(
              'Costo base MAELUX: '
              '\$${costoEmpresa.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text(
              'PRECIO ESTIMATIVO',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Multiplicador aplicado: '
              'x${multiplicadorComercial.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
            ),
            Text(
              'Precio sugerido neto: '
              '\$${precioSugerido.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text(
              'COMISIÓN ESTIMADA',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Getnet estimado: '
              '\$${costoGetnet.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'El precio sugerido todavía no incluye el IVA final.',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
