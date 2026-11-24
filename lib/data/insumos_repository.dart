import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/insumo.dart';
import '../services/insumos_firestore_service.dart';
import '../services/insumos_storage_service.dart';
import 'insumos_demo.dart';

// ==========================================================
// REPOSITORIO COMPARTIDO DE INSUMOS
// ==========================================================

/// Centraliza los insumos utilizados por MAELUX.
///
/// Mantiene:
///
/// - Una colección compartida en Cloud Firestore.
/// - Una copia en memoria para la interfaz.
/// - Un respaldo local mediante SharedPreferences.
///
/// La conexión con Firestore se realiza únicamente después
/// de validar la sesión y el perfil administrativo.
class InsumosRepository extends ChangeNotifier {
  // ========================================================
  // INSTANCIA COMPARTIDA
  // ========================================================

  /// Instancia única utilizada por todas las pantallas.
  static final InsumosRepository instancia = InsumosRepository._interno();

  /// Constructor privado que evita crear repositorios
  /// independientes accidentalmente.
  InsumosRepository._interno();

  // ========================================================
  // SERVICIOS DE PERSISTENCIA
  // ========================================================

  /// Almacenamiento local utilizado como respaldo.
  final InsumosStorageService _storageService = InsumosStorageService();

  /// Servicio utilizado para sincronizar Cloud Firestore.
  final InsumosFirestoreService _firestoreService =
      InsumosFirestoreService.instancia;

  // ========================================================
  // ESTADO INTERNO
  // ========================================================

  /// Colección modificable mantenida en memoria.
  final List<Insumo> _insumos = [];

  /// Indica si la carga local inicial ya terminó.
  bool _inicializado = false;

  /// Inicialización local actualmente en curso.
  Future<void>? _inicializacionEnCurso;

  /// Indica si el repositorio está conectado a Firestore.
  bool _nubeConectada = false;

  /// Conexión con Firestore actualmente en curso.
  Future<void>? _conexionNubeEnCurso;

  /// Suscripción utilizada para recibir cambios remotos.
  StreamSubscription<List<Insumo>>? _suscripcionRemota;

  // ========================================================
  // INICIALIZACIÓN LOCAL
  // ========================================================

  /// Carga primero el respaldo local.
  ///
  /// Este método no consulta Firestore porque se ejecuta
  /// antes de que Authentication restaure la sesión.
  Future<void> inicializar() {
    if (_inicializado) {
      return Future<void>.value();
    }

    final Future<void>? inicializacionActual = _inicializacionEnCurso;

    if (inicializacionActual != null) {
      return inicializacionActual;
    }

    final Future<void> nuevaInicializacion = _cargarDatosLocales();

    _inicializacionEnCurso = nuevaInicializacion;

    return nuevaInicializacion;
  }

  /// Recupera los insumos locales o utiliza los datos
  /// demostrativos durante la primera ejecución.
  Future<void> _cargarDatosLocales() async {
    try {
      final bool existenDatos = await _storageService.existenInsumosGuardados();

      _insumos.clear();

      if (existenDatos) {
        final List<Insumo> insumosGuardados = await _storageService
            .cargarInsumos();

        _insumos.addAll(insumosGuardados);
      } else {
        _insumos.addAll(insumosDemo);

        await _guardarRespaldoLocal();
      }

      _inicializado = true;
    } finally {
      _inicializacionEnCurso = null;
    }
  }

  // ========================================================
  // CONEXIÓN CON FIRESTORE
  // ========================================================

  /// Conecta el repositorio con la colección compartida
  /// después de validar la autorización administrativa.
  ///
  /// Si Firestore está vacío, migra los datos locales.
  /// Si Firestore ya contiene datos, estos tienen prioridad.
  Future<void> conectarConNube() {
    if (_nubeConectada) {
      return Future<void>.value();
    }

    final Future<void>? conexionActual = _conexionNubeEnCurso;

    if (conexionActual != null) {
      return conexionActual;
    }

    final Future<void> nuevaConexion = _conectarConNubeInternamente();

    _conexionNubeEnCurso = nuevaConexion;

    return nuevaConexion;
  }

  /// Ejecuta la conexión y la migración inicial.
  Future<void> _conectarConNubeInternamente() async {
    try {
      if (!_inicializado) {
        await inicializar();
      }

      final bool existenDatosRemotos = await _firestoreService.existenInsumos();

      if (existenDatosRemotos) {
        final List<Insumo> insumosRemotos = await _firestoreService
            .obtenerTodos();

        await _reemplazarEstado(insumosRemotos);
      } else if (_insumos.isNotEmpty) {
        // Esta carga ocurre solamente cuando Firestore
        // todavía no contiene ningún insumo.
        await _firestoreService.guardarTodos(_insumos);
      }

      await _suscripcionRemota?.cancel();

      _suscripcionRemota = _firestoreService.observarCambios().listen(
        (insumosRemotos) {
          unawaited(_reemplazarEstado(insumosRemotos));
        },
        onError: (_) {
          // Si la sesión se cierra o Firestore rechaza
          // la escucha, se permitirá una nueva conexión
          // después del siguiente inicio de sesión.
          _nubeConectada = false;
          _suscripcionRemota = null;
        },
      );

      _nubeConectada = true;
    } finally {
      _conexionNubeEnCurso = null;
    }
  }

  /// Cancela la escucha remota.
  ///
  /// El respaldo local y la colección en memoria se conservan.
  Future<void> desconectarDeNube() async {
    await _suscripcionRemota?.cancel();

    _suscripcionRemota = null;
    _nubeConectada = false;
    _conexionNubeEnCurso = null;
  }

  // ========================================================
  // ESTADO DEL REPOSITORIO
  // ========================================================

  /// Indica si la carga inicial ya terminó.
  bool get estaInicializado {
    return _inicializado;
  }

  /// Indica si existe una escucha activa de Firestore.
  bool get estaConectadoConNube {
    return _nubeConectada;
  }

  // ========================================================
  // CONSULTAS
  // ========================================================

  /// Devuelve una copia no modificable de todos los insumos.
  List<Insumo> obtenerTodos() {
    return List<Insumo>.unmodifiable(_insumos);
  }

  /// Devuelve únicamente los insumos activos.
  List<Insumo> obtenerActivos() {
    return List<Insumo>.unmodifiable(_insumos.where((insumo) => insumo.activo));
  }

  /// Devuelve la cantidad total de insumos.
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

  /// Agrega un insumo al almacenamiento compartido.
  Future<void> agregar(Insumo insumo) async {
    if (_nubeConectada) {
      await _firestoreService.guardar(insumo);
    }

    final int indiceExistente = _buscarIndicePorId(insumo.id);

    if (indiceExistente >= 0) {
      _insumos[indiceExistente] = insumo;
    } else {
      _insumos.add(insumo);
    }

    await _ordenarGuardarYNotificar();
  }

  // ========================================================
  // EDICIÓN
  // ========================================================

  /// Actualiza un insumo conservando su UUID estable.
  ///
  /// El parámetro `indice` se conserva para mantener
  /// compatibilidad con las pantallas actuales.
  Future<void> actualizar({required int indice, required Insumo insumo}) async {
    if (!_indiceValido(indice)) {
      return;
    }

    final Insumo insumoActual = _insumos[indice];

    final Insumo insumoActualizado = insumo.copiarCon(id: insumoActual.id);

    if (_nubeConectada) {
      await _firestoreService.guardar(insumoActualizado);
    }

    _insumos[indice] = insumoActualizado;

    await _ordenarGuardarYNotificar();
  }

  // ========================================================
  // CAMBIO DE ESTADO
  // ========================================================

  /// Activa o desactiva un insumo.
  Future<void> cambiarEstado({
    required int indice,
    required bool activo,
  }) async {
    if (!_indiceValido(indice)) {
      return;
    }

    final Insumo insumoActualizado = _insumos[indice].copiarCon(activo: activo);

    if (_nubeConectada) {
      await _firestoreService.guardar(insumoActualizado);
    }

    _insumos[indice] = insumoActualizado;

    await _ordenarGuardarYNotificar();
  }

  // ========================================================
  // ELIMINACIÓN
  // ========================================================

  /// Elimina un insumo utilizando su UUID remoto.
  ///
  /// El índice se utiliza únicamente para localizar el
  /// registro dentro de la copia en memoria.
  Future<void> eliminar(int indice) async {
    if (!_indiceValido(indice)) {
      return;
    }

    final Insumo insumo = _insumos[indice];

    if (_nubeConectada) {
      await _firestoreService.eliminar(insumo.id);
    }

    _insumos.removeAt(indice);

    await _ordenarGuardarYNotificar();
  }

  // ========================================================
  // ACTUALIZACIÓN DEL ESTADO
  // ========================================================

  /// Reemplaza la colección en memoria con los datos
  /// recibidos desde Firestore.
  Future<void> _reemplazarEstado(List<Insumo> nuevosInsumos) async {
    _insumos
      ..clear()
      ..addAll(nuevosInsumos);

    await _ordenarGuardarYNotificar();
  }

  /// Ordena la colección, actualiza el respaldo local
  /// y notifica a las interfaces que estén escuchando.
  Future<void> _ordenarGuardarYNotificar() async {
    _insumos.sort(
      (primero, segundo) =>
          primero.nombre.toLowerCase().compareTo(segundo.nombre.toLowerCase()),
    );

    await _guardarRespaldoLocal();

    notifyListeners();
  }

  // ========================================================
  // RESPALDO LOCAL
  // ========================================================

  /// Guarda localmente el último estado conocido.
  Future<void> _guardarRespaldoLocal() async {
    await _storageService.guardarInsumos(_insumos);
  }

  // ========================================================
  // VALIDACIONES INTERNAS
  // ========================================================

  /// Busca un insumo mediante su UUID.
  int _buscarIndicePorId(String insumoId) {
    final String idLimpio = insumoId.trim();

    return _insumos.indexWhere((insumo) => insumo.id == idLimpio);
  }

  /// Comprueba que el índice corresponda a un registro.
  bool _indiceValido(int indice) {
    return indice >= 0 && indice < _insumos.length;
  }
}
