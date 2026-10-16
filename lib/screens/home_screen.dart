import 'package:flutter/material.dart';
import 'catalogo_screen.dart';
import 'cotizador_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MAELUX Manager")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard("Capital Inicial", "\$1.000.000", Icons.savings),

            _buildCard("Capital Recuperado", "\$0", Icons.trending_up),

            _buildCard("Ganancia Empresa", "\$0", Icons.business_center),

            _buildCard("Ganancia Personal", "\$0", Icons.person),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CatalogoScreen(),
                    ),
                  );
                },
                child: const Text("CATÁLOGO"),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CotizadorScreen(),
                    ),
                  );
                },
                child: const Text("COTIZADOR"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String titulo, String valor, IconData icono) {
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
}
