import 'package:flutter/material.dart';

import '../services/auth_service.dart';
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
  // SERVICIO DE AUTENTICACIÓN
  // ========================================================

  /// Servicio utilizado para consultar y cerrar
  /// la sesión administrativa actual.
  AuthService get authService {
    return AuthService.instancia;
  }

  // ========================================================
  // NAVEGACIÓN PRINCIPAL
  // ========================================================

  /// Abre la pantalla indicada y mantiene disponible
  /// la opción de regresar a la pantalla principal.
  void _abrirPantalla(BuildContext context, Widget pantalla) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => pantalla));
  }

  // ========================================================
  // CIERRE DE SESIÓN
  // ========================================================

  /// Solicita confirmación antes de cerrar la sesión.
  ///
  /// Cuando Firebase complete el cierre, AuthGate detectará
  /// automáticamente que ya no existe un usuario autenticado
  /// y mostrará nuevamente la pantalla de acceso.
  Future<void> _confirmarCierreSesion(BuildContext context) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Deseas salir del área administrativa de MAELUX?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('CERRAR SESIÓN'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !context.mounted) {
      return;
    }

    final String? error = await authService.cerrarSesion();

    if (!context.mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  // ========================================================
  // INTERFAZ PRINCIPAL
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MAELUX Manager'),
        actions: [
          IconButton(
            onPressed: () {
              _confirmarCierreSesion(context);
            },
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ------------------------------------------------
                // SESIÓN ADMINISTRATIVA
                // ------------------------------------------------
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.account_circle_outlined,
                      size: 32,
                    ),
                    title: const Text('Sesión administrativa'),
                    subtitle: Text(
                      authService.usuarioActual?.email ?? 'Usuario autorizado',
                    ),
                    trailing: const Icon(Icons.verified_user_outlined),
                  ),
                ),

                const SizedBox(height: 24),
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
