import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/configuracion_cotizador.dart';

// ==========================================================
// ALMACENAMIENTO LOCAL DE LA CONFIGURACIÓN DEL COTIZADOR
// ==========================================================

/// Gestiona la persistencia local de los supuestos utilizados
/// por el cotizador de MAELUX.
///
/// La configuración se convierte a JSON antes de guardarse
/// y se reconstruye como [ConfiguracionCotizador] al cargarla.
class ConfiguracionCotizadorStorageService {
  // ========================================================
  // CLAVES DE ALMACENAMIENTO
  // ========================================================

  /// Clave utilizada para guardar la configuración completa.
  static const String _claveConfiguracion = 'maelux_configuracion_cotizador';

  // ========================================================
  // ACCESO AL ALMACENAMIENTO
  // ========================================================

  /// API asíncrona utilizada para leer y escribir
  /// la configuración en el almacenamiento local.
  final SharedPreferencesAsync _preferencias = SharedPreferencesAsync();

  // ========================================================
  // GUARDADO
  // ========================================================

  /// Guarda la configuración completa del cotizador.
  ///
  /// El modelo se convierte primero a un mapa y después
  /// se serializa como una cadena JSON.
  Future<void> guardarConfiguracion(
    ConfiguracionCotizador configuracion,
  ) async {
    final Map<String, dynamic> mapa = configuracion.toMap();

    final String contenidoJson = jsonEncode(mapa);

    await _preferencias.setString(_claveConfiguracion, contenidoJson);
  }

  // ========================================================
  // RECUPERACIÓN
  // ========================================================

  /// Recupera la configuración almacenada localmente.
  ///
  /// Si todavía no existe una configuración guardada,
  /// devuelve los valores predeterminados.
  ///
  /// También utiliza la configuración predeterminada si el
  /// contenido almacenado está incompleto o dañado.
  Future<ConfiguracionCotizador> cargarConfiguracion() async {
    final String? contenidoJson = await _preferencias.getString(
      _claveConfiguracion,
    );

    if (contenidoJson == null || contenidoJson.trim().isEmpty) {
      return ConfiguracionCotizador.predeterminada();
    }

    try {
      final dynamic contenidoDecodificado = jsonDecode(contenidoJson);

      if (contenidoDecodificado is! Map) {
        return ConfiguracionCotizador.predeterminada();
      }

      final Map<String, dynamic> mapa = Map<String, dynamic>.from(
        contenidoDecodificado,
      );

      return ConfiguracionCotizador.fromMap(mapa);
    } on FormatException {
      return ConfiguracionCotizador.predeterminada();
    } on TypeError {
      return ConfiguracionCotizador.predeterminada();
    }
  }

  // ========================================================
  // COMPROBACIÓN DEL ALMACENAMIENTO
  // ========================================================

  /// Indica si ya existe una configuración guardada.
  Future<bool> existeConfiguracionGuardada() async {
    return _preferencias.containsKey(_claveConfiguracion);
  }

  // ========================================================
  // RESTABLECIMIENTO
  // ========================================================

  /// Elimina la configuración almacenada localmente.
  ///
  /// Después de eliminarla, la próxima carga utilizará
  /// los valores predeterminados definidos en el modelo.
  Future<void> eliminarConfiguracionGuardada() async {
    await _preferencias.remove(_claveConfiguracion);
  }
}
