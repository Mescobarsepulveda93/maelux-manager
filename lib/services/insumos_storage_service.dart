import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/insumo.dart';

// ==========================================================
// SERVICIO DE ALMACENAMIENTO LOCAL DE INSUMOS
// ==========================================================

/// Gestiona la persistencia local de los insumos de MAELUX.
///
/// Los registros se convierten a JSON antes de almacenarse
/// y se reconstruyen como objetos [Insumo] al recuperarlos.
///
/// Este almacenamiento corresponde a una etapa local inicial.
/// Posteriormente podrá sustituirse por una base de datos
/// sin modificar las pantallas de la aplicación.
class InsumosStorageService {
  // ========================================================
  // CLAVES DE ALMACENAMIENTO
  // ========================================================

  /// Clave utilizada para guardar la colección completa.
  static const String _claveInsumos = 'maelux_insumos';

  // ========================================================
  // ACCESO AL ALMACENAMIENTO
  // ========================================================

  /// API asíncrona utilizada para leer y escribir preferencias.
  final SharedPreferencesAsync _preferencias = SharedPreferencesAsync();

  // ========================================================
  // GUARDADO
  // ========================================================

  /// Guarda la colección completa de insumos.
  ///
  /// Cada registro se convierte primero a un mapa y después
  /// la lista completa se serializa como una cadena JSON.
  Future<void> guardarInsumos(List<Insumo> insumos) async {
    final List<Map<String, dynamic>> mapas = insumos
        .map((insumo) => insumo.toMap())
        .toList();

    final String contenidoJson = jsonEncode(mapas);

    await _preferencias.setString(_claveInsumos, contenidoJson);
  }

  // ========================================================
  // RECUPERACIÓN
  // ========================================================

  /// Recupera todos los insumos guardados localmente.
  ///
  /// Si todavía no existen datos o el contenido no puede
  /// interpretarse, devuelve una lista vacía.
  Future<List<Insumo>> cargarInsumos() async {
    final String? contenidoJson = await _preferencias.getString(_claveInsumos);

    if (contenidoJson == null || contenidoJson.trim().isEmpty) {
      return [];
    }

    try {
      final dynamic contenidoDecodificado = jsonDecode(contenidoJson);

      if (contenidoDecodificado is! List) {
        return [];
      }

      final List<Insumo> insumos = [];

      for (final dynamic elemento in contenidoDecodificado) {
        if (elemento is! Map) {
          continue;
        }

        final Map<String, dynamic> mapa = Map<String, dynamic>.from(elemento);

        final Insumo insumo = Insumo.fromMap(mapa);

        // Se descartan registros que no puedan identificarse.
        if (insumo.id.trim().isEmpty) {
          continue;
        }

        insumos.add(insumo);
      }

      return insumos;
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  // ========================================================
  // COMPROBACIÓN DEL ALMACENAMIENTO
  // ========================================================

  /// Indica si la aplicación ya posee una colección guardada.
  ///
  /// Esta comprobación permitirá utilizar los datos
  /// demostrativos únicamente durante la primera ejecución.
  Future<bool> existenInsumosGuardados() async {
    return _preferencias.containsKey(_claveInsumos);
  }

  // ========================================================
  // LIMPIEZA
  // ========================================================

  /// Elimina exclusivamente la colección local de insumos.
  ///
  /// Este método quedará disponible para pruebas, migraciones
  /// o una futura opción administrativa de restablecimiento.
  Future<void> eliminarInsumosGuardados() async {
    await _preferencias.remove(_claveInsumos);
  }
}
