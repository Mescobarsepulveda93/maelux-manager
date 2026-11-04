import '../models/configuracion_cotizador.dart';
import '../services/configuracion_cotizador_storage_service.dart';

// ==========================================================
// REPOSITORIO DE CONFIGURACIÓN DEL COTIZADOR
// ==========================================================

/// Centraliza los supuestos productivos, financieros
/// y tributarios utilizados por el cotizador de MAELUX.
///
/// El repositorio mantiene la configuración activa en memoria
/// y utiliza almacenamiento local para conservar los cambios
/// entre distintas ejecuciones de la aplicación.
class ConfiguracionCotizadorRepository {
  // ========================================================
  // INSTANCIA COMPARTIDA
  // ========================================================

  /// Instancia única utilizada por toda la aplicación.
  static final ConfiguracionCotizadorRepository instancia =
      ConfiguracionCotizadorRepository._interno();

  /// Constructor privado que evita crear repositorios
  /// independientes accidentalmente.
  ConfiguracionCotizadorRepository._interno();

  // ========================================================
  // SERVICIO DE ALMACENAMIENTO
  // ========================================================

  /// Servicio responsable de guardar y recuperar
  /// la configuración local del cotizador.
  final ConfiguracionCotizadorStorageService _storageService =
      ConfiguracionCotizadorStorageService();

  // ========================================================
  // ESTADO INTERNO
  // ========================================================

  /// Configuración utilizada actualmente por el cotizador.
  ConfiguracionCotizador _configuracion =
      ConfiguracionCotizador.predeterminada();

  /// Indica si el repositorio completó su carga inicial.
  bool _inicializado = false;

  /// Almacena la inicialización en curso para evitar
  /// ejecutar varias cargas simultáneamente.
  Future<void>? _inicializacionEnCurso;

  // ========================================================
  // INICIALIZACIÓN
  // ========================================================

  /// Recupera la configuración guardada localmente.
  ///
  /// Si no existe una configuración previa, utiliza
  /// los valores predeterminados y los guarda.
  Future<void> inicializar() {
    if (_inicializado) {
      return Future<void>.value();
    }

    final Future<void>? inicializacionActual = _inicializacionEnCurso;

    if (inicializacionActual != null) {
      return inicializacionActual;
    }

    final Future<void> nuevaInicializacion = _cargarConfiguracionInicial();

    _inicializacionEnCurso = nuevaInicializacion;

    return nuevaInicializacion;
  }

  /// Ejecuta internamente la recuperación de la configuración.
  Future<void> _cargarConfiguracionInicial() async {
    try {
      final bool existeConfiguracion = await _storageService
          .existeConfiguracionGuardada();

      if (existeConfiguracion) {
        _configuracion = await _storageService.cargarConfiguracion();
      } else {
        _configuracion = ConfiguracionCotizador.predeterminada();

        await _storageService.guardarConfiguracion(_configuracion);
      }

      _inicializado = true;
    } finally {
      _inicializacionEnCurso = null;
    }
  }

  // ========================================================
  // CONSULTAS
  // ========================================================

  /// Devuelve la configuración utilizada actualmente
  /// por el cotizador.
  ConfiguracionCotizador get configuracion {
    return _configuracion;
  }

  /// Indica si la carga inicial ya terminó.
  bool get estaInicializado {
    return _inicializado;
  }

  // ========================================================
  // ACTUALIZACIÓN
  // ========================================================

  /// Reemplaza la configuración actual y guarda
  /// inmediatamente los nuevos valores.
  Future<void> actualizar(ConfiguracionCotizador configuracion) async {
    _configuracion = configuracion;

    await _storageService.guardarConfiguracion(_configuracion);
  }

  // ========================================================
  // RESTABLECIMIENTO
  // ========================================================

  /// Restablece todos los supuestos a sus valores iniciales
  /// y guarda inmediatamente la configuración resultante.
  Future<void> restablecer() async {
    _configuracion = ConfiguracionCotizador.predeterminada();

    await _storageService.guardarConfiguracion(_configuracion);
  }
}
