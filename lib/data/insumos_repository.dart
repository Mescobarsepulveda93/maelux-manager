import '../models/insumo.dart';
import '../services/insumos_storage_service.dart';
import 'insumos_demo.dart';

// ==========================================================
// REPOSITORIO COMPARTIDO DE INSUMOS
// ==========================================================

/// Centraliza la colección de insumos utilizada por MAELUX.
///
/// El repositorio conserva una copia en memoria para que las
/// pantallas trabajen con la misma información y utiliza
/// [InsumosStorageService] para guardar los cambios localmente.
///
/// Durante la primera ejecución se cargan los datos demostrativos.
/// En ejecuciones posteriores se recuperan los datos guardados.
class InsumosRepository {
  // ========================================================
  // INSTANCIA COMPARTIDA
  // ========================================================

  /// Instancia única utilizada por todas las pantallas.
  static final InsumosRepository instancia = InsumosRepository._interno();

  /// Constructor privado que evita crear repositorios
  /// independientes accidentalmente.
  InsumosRepository._interno();

  // ========================================================
  // SERVICIO DE ALMACENAMIENTO
  // ========================================================

  /// Servicio responsable de guardar y recuperar los insumos.
  final InsumosStorageService _storageService = InsumosStorageService();

  // ========================================================
  // ESTADO INTERNO
  // ========================================================

  /// Colección modificable mantenida en memoria.
  final List<Insumo> _insumos = [];

  /// Indica si el repositorio ya completó su carga inicial.
  bool _inicializado = false;

  /// Indica si el repositorio está ejecutando la inicialización.
  Future<void>? _inicializacionEnCurso;

  // ========================================================
  // INICIALIZACIÓN
  // ========================================================

  /// Carga los insumos guardados o utiliza los datos
  /// demostrativos durante la primera ejecución.
  ///
  /// Las llamadas adicionales esperan la misma operación
  /// y no duplican la inicialización.
  Future<void> inicializar() {
    if (_inicializado) {
      return Future<void>.value();
    }

    final Future<void>? inicializacionActual = _inicializacionEnCurso;

    if (inicializacionActual != null) {
      return inicializacionActual;
    }

    final Future<void> nuevaInicializacion = _cargarDatosIniciales();

    _inicializacionEnCurso = nuevaInicializacion;

    return nuevaInicializacion;
  }

  /// Ejecuta internamente la carga inicial del repositorio.
  Future<void> _cargarDatosIniciales() async {
    try {
      final bool existenDatos = await _storageService.existenInsumosGuardados();

      _insumos.clear();

      if (existenDatos) {
        final List<Insumo> insumosGuardados = await _storageService
            .cargarInsumos();

        _insumos.addAll(insumosGuardados);
      } else {
        // Los datos demostrativos se utilizan solamente
        // durante la primera ejecución.
        _insumos.addAll(insumosDemo);

        await _guardarEstadoActual();
      }

      _inicializado = true;
    } finally {
      _inicializacionEnCurso = null;
    }
  }

  // ========================================================
  // ESTADO DEL REPOSITORIO
  // ========================================================

  /// Indica si la carga inicial ya terminó correctamente.
  bool get estaInicializado {
    return _inicializado;
  }

  // ========================================================
  // CONSULTAS
  // ========================================================

  /// Devuelve una copia no modificable de todos los insumos.
  List<Insumo> obtenerTodos() {
    return List<Insumo>.unmodifiable(_insumos);
  }

  /// Devuelve únicamente los insumos disponibles
  /// para seleccionar dentro del cotizador.
  List<Insumo> obtenerActivos() {
    return List<Insumo>.unmodifiable(_insumos.where((insumo) => insumo.activo));
  }

  /// Devuelve la cantidad total de insumos registrados.
  int get cantidadTotal {
    return _insumos.length;
  }

  /// Devuelve la cantidad de insumos activos.
  int get cantidadActivos {
    return _insumos.where((insumo) => insumo.activo).length;
  }

  // ========================================================
  // CREACIÓN
  // ========================================================

  /// Agrega un insumo y guarda la colección actualizada.
  Future<void> agregar(Insumo insumo) async {
    _insumos.add(insumo);

    await _guardarEstadoActual();
  }

  // ========================================================
  // EDICIÓN
  // ========================================================

  /// Reemplaza un insumo y guarda la colección actualizada.
  ///
  /// Si el índice no existe, la operación no modifica los datos.
  Future<void> actualizar({required int indice, required Insumo insumo}) async {
    if (!_indiceValido(indice)) {
      return;
    }

    _insumos[indice] = insumo;

    await _guardarEstadoActual();
  }

  // ========================================================
  // CAMBIO DE ESTADO
  // ========================================================

  /// Activa o desactiva un insumo y persiste el cambio.
  Future<void> cambiarEstado({
    required int indice,
    required bool activo,
  }) async {
    if (!_indiceValido(indice)) {
      return;
    }

    _insumos[indice] = _insumos[indice].copiarCon(activo: activo);

    await _guardarEstadoActual();
  }

  // ========================================================
  // ELIMINACIÓN
  // ========================================================

  /// Elimina un insumo y guarda la colección actualizada.
  ///
  /// Si el índice no existe, la operación no modifica los datos.
  Future<void> eliminar(int indice) async {
    if (!_indiceValido(indice)) {
      return;
    }

    _insumos.removeAt(indice);

    await _guardarEstadoActual();
  }

  // ========================================================
  // PERSISTENCIA INTERNA
  // ========================================================

  /// Guarda una copia completa del estado actual.
  Future<void> _guardarEstadoActual() async {
    await _storageService.guardarInsumos(_insumos);
  }

  // ========================================================
  // VALIDACIONES INTERNAS
  // ========================================================

  /// Comprueba que el índice corresponda a un registro existente.
  bool _indiceValido(int indice) {
    return indice >= 0 && indice < _insumos.length;
  }
}
