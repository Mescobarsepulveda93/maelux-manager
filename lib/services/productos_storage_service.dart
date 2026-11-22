import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/producto.dart';

// ==========================================================
// ALMACENAMIENTO LOCAL DE PRODUCTOS
// ==========================================================

/// Gestiona la persistencia local de los productos
/// pertenecientes al catálogo de MAELUX.
///
/// Los productos se convierten a JSON antes de guardarse
/// y se reconstruyen como objetos [Producto] al recuperarlos.
class ProductosStorageService {
  // ========================================================
  // CLAVES DE ALMACENAMIENTO
  // ========================================================

  /// Clave utilizada para guardar la colección completa
  /// de productos.
  static const String _claveProductos = 'maelux_productos';

  // ========================================================
  // ACCESO AL ALMACENAMIENTO
  // ========================================================

  /// API asíncrona utilizada para leer y escribir
  /// los productos en el almacenamiento local.
  final SharedPreferencesAsync _preferencias = SharedPreferencesAsync();

  // ========================================================
  // GUARDADO
  // ========================================================

  /// Guarda la colección completa de productos.
  ///
  /// Cada producto se convierte primero a un mapa.
  /// Después, la colección completa se serializa como JSON.
  Future<void> guardarProductos(List<Producto> productos) async {
    final List<Map<String, dynamic>> mapas = productos
        .map((producto) => producto.toMap())
        .toList();

    final String contenidoJson = jsonEncode(mapas);

    await _preferencias.setString(_claveProductos, contenidoJson);
  }

  // ========================================================
  // RECUPERACIÓN
  // ========================================================

  /// Recupera todos los productos guardados localmente.
  ///
  /// Si todavía no existen datos o el contenido no puede
  /// interpretarse correctamente, devuelve una lista vacía.
  Future<List<Producto>> cargarProductos() async {
    final String? contenidoJson = await _preferencias.getString(
      _claveProductos,
    );

    if (contenidoJson == null || contenidoJson.trim().isEmpty) {
      return [];
    }

    try {
      final dynamic contenidoDecodificado = jsonDecode(contenidoJson);

      if (contenidoDecodificado is! List) {
        return [];
      }

      final List<Producto> productos = [];

      for (final dynamic elemento in contenidoDecodificado) {
        if (elemento is! Map) {
          continue;
        }

        final Map<String, dynamic> mapa = Map<String, dynamic>.from(elemento);

        final Producto producto = Producto.fromMap(mapa);

        // Se descartan registros sin identificador
        // o sin nombre.
        if (producto.id.trim().isEmpty || producto.nombre.trim().isEmpty) {
          continue;
        }

        productos.add(producto);
      }

      return productos;
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  // ========================================================
  // COMPROBACIÓN DEL ALMACENAMIENTO
  // ========================================================

  /// Indica si la aplicación ya posee una colección
  /// de productos guardada.
  ///
  /// Esto permite utilizar los productos demostrativos
  /// únicamente durante la primera ejecución.
  Future<bool> existenProductosGuardados() async {
    return _preferencias.containsKey(_claveProductos);
  }

  // ========================================================
  // LIMPIEZA
  // ========================================================

  /// Elimina exclusivamente los productos almacenados.
  ///
  /// Este método podrá utilizarse posteriormente para
  /// pruebas, migraciones o restablecimiento administrativo.
  Future<void> eliminarProductosGuardados() async {
    await _preferencias.remove(_claveProductos);
  }
}
