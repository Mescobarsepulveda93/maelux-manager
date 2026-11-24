import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/producto.dart';
import '../services/productos_firestore_service.dart';
import '../services/productos_storage_service.dart';
import 'productos_demo.dart';

// ==========================================================
// REPOSITORIO COMPARTIDO DE PRODUCTOS
// ==========================================================

/// Centraliza el catálogo compartido de MAELUX.
///
/// Mantiene:
///
/// - Los productos compartidos en Cloud Firestore.
/// - Una copia en memoria para las pantallas.
/// - Un respaldo local mediante SharedPreferences.
class ProductosRepository extends ChangeNotifier {
  // ========================================================
  // INSTANCIA COMPARTIDA
  // ========================================================

  static final ProductosRepository instancia = ProductosRepository._interno();

  ProductosRepository._interno();

  // ========================================================
  // SERVICIOS DE PERSISTENCIA
  // ========================================================

  /// Respaldo local del último estado conocido.
  final ProductosStorageService _storageService = ProductosStorageService();

  /// Servicio encargado de la sincronización remota.
  final ProductosFirestoreService _firestoreService =
      ProductosFirestoreService.instancia;

  // ========================================================
  // ESTADO INTERNO
  // ========================================================

  final List<Producto> _productos = [];

  bool _inicializado = false;

  Future<void>? _inicializacionEnCurso;

  bool _nubeConectada = false;

  Future<void>? _conexionNubeEnCurso;

  StreamSubscription<List<Producto>>? _suscripcionRemota;

  // ========================================================
  // INICIALIZACIÓN LOCAL
  // ========================================================

  /// Recupera el respaldo local antes de que Authentication
  /// haya restaurado y validado la sesión.
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

  /// Carga productos locales o usa los demostrativos
  /// solamente durante la primera ejecución.
  Future<void> _cargarDatosLocales() async {
    try {
      final bool existenDatos = await _storageService
          .existenProductosGuardados();

      _productos.clear();

      if (existenDatos) {
        final List<Producto> productosGuardados = await _storageService
            .cargarProductos();

        _productos.addAll(productosGuardados);
      } else {
        _productos.addAll(productosDemo);

        await _guardarRespaldoLocal();
      }

      _ordenarProductos();
      _inicializado = true;
    } finally {
      _inicializacionEnCurso = null;
    }
  }

  // ========================================================
  // CONEXIÓN CON FIRESTORE
  // ========================================================

  /// Conecta el catálogo con Firestore después de validar
  /// la identidad, el perfil y el rol administrativo.
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

  /// Ejecuta la migración inicial y comienza la escucha
  /// en tiempo real del catálogo compartido.
  Future<void> _conectarConNubeInternamente() async {
    try {
      if (!_inicializado) {
        await inicializar();
      }

      final bool existenProductosRemotos = await _firestoreService
          .existenProductos();

      if (existenProductosRemotos) {
        final List<Producto> productosRemotos = await _firestoreService
            .obtenerTodos();

        await _reemplazarEstado(productosRemotos);
      } else if (_productos.isNotEmpty) {
        // La migración se realiza únicamente cuando
        // la colección remota todavía está vacía.
        await _firestoreService.guardarTodos(_productos);
      }

      await _suscripcionRemota?.cancel();

      _suscripcionRemota = _firestoreService.observarCambios().listen(
        (productosRemotos) {
          unawaited(_reemplazarEstado(productosRemotos));
        },
        onError: (_) {
          _nubeConectada = false;
          _suscripcionRemota = null;
        },
      );

      _nubeConectada = true;
    } finally {
      _conexionNubeEnCurso = null;
    }
  }

  /// Cancela la escucha remota sin eliminar el respaldo local.
  Future<void> desconectarDeNube() async {
    await _suscripcionRemota?.cancel();

    _suscripcionRemota = null;
    _nubeConectada = false;
    _conexionNubeEnCurso = null;
  }

  // ========================================================
  // ESTADO DEL REPOSITORIO
  // ========================================================

  bool get estaInicializado {
    return _inicializado;
  }

  bool get estaConectadoConNube {
    return _nubeConectada;
  }

  // ========================================================
  // CONSULTAS
  // ========================================================

  List<Producto> obtenerTodos() {
    return List<Producto>.unmodifiable(_productos);
  }

  List<Producto> obtenerActivos() {
    return List<Producto>.unmodifiable(
      _productos.where((producto) => producto.activo),
    );
  }

  int get cantidadTotal {
    return _productos.length;
  }

  int get cantidadActivos {
    return _productos.where((producto) => producto.activo).length;
  }

  Producto? buscarPorId(String id) {
    final int indice = _buscarIndicePorId(id);

    if (!_indiceValido(indice)) {
      return null;
    }

    return _productos[indice];
  }

  // ========================================================
  // CREACIÓN
  // ========================================================

  /// Crea un producto compartido usando su UUID.
  Future<void> agregar(Producto producto) async {
    if (_nubeConectada) {
      await _firestoreService.guardar(producto);
    }

    final int indiceExistente = _buscarIndicePorId(producto.id);

    if (indiceExistente >= 0) {
      _productos[indiceExistente] = producto;
    } else {
      _productos.add(producto);
    }

    await _ordenarGuardarYNotificar();
  }

  // ========================================================
  // EDICIÓN
  // ========================================================

  /// Conserva compatibilidad con las pantallas que todavía
  /// utilizan la posición dentro de la lista.
  Future<void> actualizar({
    required int indice,
    required Producto producto,
  }) async {
    if (!_indiceValido(indice)) {
      return;
    }

    final Producto productoActual = _productos[indice];

    final Producto productoActualizado = producto.copiarCon(
      id: productoActual.id,
    );

    await _guardarProductoActualizado(productoActualizado);
  }

  /// Actualiza un producto mediante su UUID estable.
  Future<void> actualizarPorId(Producto producto) async {
    final int indice = _buscarIndicePorId(producto.id);

    if (!_indiceValido(indice)) {
      return;
    }

    final Producto productoActualizado = producto.copiarCon(
      id: _productos[indice].id,
    );

    await _guardarProductoActualizado(productoActualizado);
  }

  /// Guarda una actualización remota y local.
  Future<void> _guardarProductoActualizado(Producto producto) async {
    final int indice = _buscarIndicePorId(producto.id);

    if (!_indiceValido(indice)) {
      return;
    }

    if (_nubeConectada) {
      await _firestoreService.guardar(producto);
    }

    _productos[indice] = producto;

    await _ordenarGuardarYNotificar();
  }

  // ========================================================
  // CAMBIO DE ESTADO
  // ========================================================

  /// Activa o desactiva un producto identificado
  /// inicialmente mediante su posición actual.
  Future<void> cambiarEstado({
    required int indice,
    required bool activo,
  }) async {
    if (!_indiceValido(indice)) {
      return;
    }

    final Producto productoActualizado = _productos[indice].copiarCon(
      activo: activo,
    );

    await _guardarProductoActualizado(productoActualizado);
  }

  /// Activa o desactiva un producto mediante UUID.
  Future<void> cambiarEstadoPorId({
    required String productoId,
    required bool activo,
  }) async {
    final int indice = _buscarIndicePorId(productoId);

    if (!_indiceValido(indice)) {
      return;
    }

    final Producto productoActualizado = _productos[indice].copiarCon(
      activo: activo,
    );

    await _guardarProductoActualizado(productoActualizado);
  }

  // ========================================================
  // ELIMINACIÓN
  // ========================================================

  Future<void> eliminar(int indice) async {
    if (!_indiceValido(indice)) {
      return;
    }

    await eliminarPorId(_productos[indice].id);
  }

  /// Elimina un producto remoto y local mediante UUID.
  Future<void> eliminarPorId(String id) async {
    final int indice = _buscarIndicePorId(id);

    if (!_indiceValido(indice)) {
      return;
    }

    final Producto producto = _productos[indice];

    if (_nubeConectada) {
      await _firestoreService.eliminar(producto.id);
    }

    _productos.removeAt(indice);

    await _ordenarGuardarYNotificar();
  }

  // ========================================================
  // ACTUALIZACIÓN DEL ESTADO
  // ========================================================

  /// Reemplaza el catálogo con el estado recibido
  /// desde Cloud Firestore.
  Future<void> _reemplazarEstado(List<Producto> nuevosProductos) async {
    _productos
      ..clear()
      ..addAll(nuevosProductos);

    await _ordenarGuardarYNotificar();
  }

  /// Ordena, respalda y notifica a las pantallas.
  Future<void> _ordenarGuardarYNotificar() async {
    _ordenarProductos();

    await _guardarRespaldoLocal();

    notifyListeners();
  }

  /// Ordena alfabéticamente el catálogo.
  void _ordenarProductos() {
    _productos.sort(
      (primero, segundo) =>
          primero.nombre.toLowerCase().compareTo(segundo.nombre.toLowerCase()),
    );
  }

  // ========================================================
  // RESPALDO LOCAL
  // ========================================================

  Future<void> _guardarRespaldoLocal() async {
    await _storageService.guardarProductos(_productos);
  }

  // ========================================================
  // VALIDACIONES INTERNAS
  // ========================================================

  int _buscarIndicePorId(String productoId) {
    final String idLimpio = productoId.trim();

    return _productos.indexWhere((producto) => producto.id == idLimpio);
  }

  bool _indiceValido(int indice) {
    return indice >= 0 && indice < _productos.length;
  }
}
