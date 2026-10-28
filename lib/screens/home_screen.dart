import 'package:flutter/material.dart';

import 'catalogo_screen.dart';
import 'cotizador_screen.dart';
import 'insumos_screen.dart';

// ==========================================================
// PANTALLA PRINCIPAL DE MAELUX MANAGER
// ==========================================================

/// Presenta un resumen general del negocio y permite acceder
/// a los módulos principales de la aplicación.
///
/// Durante esta fase, los indicadores financieros utilizan
/// valores demostrativos. Posteriormente se calcularán con
/// información almacenada por la aplicación.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ========================================================
  // NAVEGACIÓN PRINCIPAL
  // ========================================================

  /// Abre la pantalla indicada y mantiene disponible
  /// la opción de regresar a la pantalla principal.
  void _abrirPantalla(BuildContext context, Widget pantalla) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => pantalla));
  }

  // ========================================================
  // INTERFAZ PRINCIPAL
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MAELUX Manager')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ------------------------------------------------
            // RESUMEN FINANCIERO
            // ------------------------------------------------
            const Text(
              'RESUMEN FINANCIERO',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            _construirTarjetaResumen(
              titulo: 'Capital inicial',
              valor: '\$1.000.000',
              icono: Icons.savings,
            ),

            _construirTarjetaResumen(
              titulo: 'Capital recuperado',
              valor: '\$0',
              icono: Icons.trending_up,
            ),

            _construirTarjetaResumen(
              titulo: 'Ganancia empresa',
              valor: '\$0',
              icono: Icons.business_center,
            ),

            _construirTarjetaResumen(
              titulo: 'Ganancia personal',
              valor: '\$0',
              icono: Icons.person,
            ),

            const SizedBox(height: 24),

            // ------------------------------------------------
            // MÓDULOS PRINCIPALES
            // ------------------------------------------------
            const Text(
              'MÓDULOS',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            _construirBotonModulo(
              texto: 'CATÁLOGO',
              icono: Icons.inventory_2_outlined,
              alPresionar: () {
                _abrirPantalla(context, const CatalogoScreen());
              },
            ),

            const SizedBox(height: 12),

            _construirBotonModulo(
              texto: 'COTIZADOR',
              icono: Icons.calculate_outlined,
              alPresionar: () {
                _abrirPantalla(context, const CotizadorScreen());
              },
            ),

            const SizedBox(height: 12),

            _construirBotonModulo(
              texto: 'GESTIÓN DE INSUMOS',
              icono: Icons.category_outlined,
              alPresionar: () {
                _abrirPantalla(context, const InsumosScreen());
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // COMPONENTES AUXILIARES DE LA INTERFAZ
  // ========================================================

  /// Construye una tarjeta para mostrar un indicador financiero
  /// dentro de la pantalla principal.
  Widget _construirTarjetaResumen({
    required String titulo,
    required String valor,
    required IconData icono,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icono, size: 32),
        title: Text(titulo),
        subtitle: Text(
          valor,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Construye un botón uniforme para acceder a uno
  /// de los módulos principales de MAELUX Manager.
  Widget _construirBotonModulo({
    required String texto,
    required IconData icono,
    required VoidCallback alPresionar,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: alPresionar,
        icon: Icon(icono),
        label: Text(texto),
      ),
    );
  }
}
