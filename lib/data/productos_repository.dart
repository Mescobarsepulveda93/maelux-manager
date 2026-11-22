import '../models/producto.dart';
import '../services/productos_storage_service.dart';
import 'productos_demo.dart';

// ==========================================================
// REPOSITORIO COMPARTIDO DE PRODUCTOS
// ==========================================================

/// Centraliza la colección de productos del catálogo MAELUX.
///
/// El repositorio mantiene una copia de los productos en memoria
/// y utiliza [ProductosStorageService] para conservar los cambios
/// entre diferentes ejecuciones de la aplicación.
///
/// Durante la primera ejecución se utilizan los productos
/// demostrativos. En ejecuciones posteriores se recuperan
/// los productos almacenados localmente.
class ProductosRepository {
  // ========================================================
  // INSTANCIA COMPARTIDA
  // ========================================================

  /// Instancia única utilizada por todas las pantallas.
  static final ProductosRepository instancia = ProductosRepository._interno();

  /// Constructor privado que evita crear repositorios
  /// independientes accidentalmente.
  ProductosRepository._interno();

  // ========================================================
  // SERVICIO DE ALMACENAMIENTO
  // ========================================================

  /// Servicio responsable de guardar y recuperar
  /// la colección local de productos.
  final ProductosStorageService _storageService = ProductosStorageService();

  // ========================================================
  // ESTADO INTERNO
  // ========================================================

  /// Colección modificable mantenida en memoria.
  final List<Producto> _productos = [];

  /// Indica si el repositorio completó su carga inicial.
  bool _inicializado = false;

  /// Conserva la operación de inicialización activa para
  /// impedir que se ejecuten varias cargas simultáneas.
  Future<void>? _inicializacionEnCurso;

  // ========================================================
  // INICIALIZACIÓN
  // ========================================================

  /// Carga los productos almacenados localmente.
  ///
  /// Durante la primera ejecución utiliza los productos
  /// demostrativos y los guarda para futuras sesiones.
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

  /// Ejecuta internamente la carga inicial del catálogo.
  Future<void> _cargarDatosIniciales() async {
    try {
      final bool existenDatos = await _storageService
          .existenProductosGuardados();

      _productos.clear();

      if (existenDatos) {
        final List<Producto> productosGuardados = await _storageService
            .cargarProductos();

        _productos.addAll(productosGuardados);
      } else {
        // Los productos demostrativos se utilizan solamente
        // durante la primera ejecución.
        _productos.addAll(productosDemo);

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

  /// Indica si la carga inicial del catálogo ya terminó.
  bool get estaInicializado {
    return _inicializado;
  }

  // ========================================================
  // CONSULTAS
  // ========================================================

  /// Devuelve una copia no modificable de todos
  /// los productos registrados.
  List<Producto> obtenerTodos() {
    return List<Producto>.unmodifiable(_productos);
  }

  /// Devuelve únicamente los productos activos
  /// que deben aparecer disponibles en el catálogo.
  List<Producto> obtenerActivos() {
    return List<Producto>.unmodifiable(
      _productos.where((producto) => producto.activo),
    );
  }

  /// Devuelve la cantidad total de productos registrados.
  int get cantidadTotal {
    return _productos.length;
  }

  /// Devuelve la cantidad de productos activos.
  int get cantidadActivos {
    return _productos.where((producto) => producto.activo).length;
  }

  /// Busca un producto mediante su identificador.
  ///
  /// Devuelve `null` cuando el identificador no corresponde
  /// a ningún producto registrado.
  Producto? buscarPorId(String id) {
    for (final Producto producto in _productos) {
      if (producto.id == id) {
        return producto;
      }
    }

    return null;
  }

  // ========================================================
  // CREACIÓN
  // ========================================================

  /// Agrega un producto y guarda la colección actualizada.
  Future<void> agregar(Producto producto) async {
    _productos.add(producto);

    await _guardarEstadoActual();
  }

  // ========================================================
  // EDICIÓN
  // ========================================================

  /// Reemplaza el producto situado en la posición indicada.
  ///
  /// Si el índice no existe, la colección no se modifica.
  Future<void> actualizar({
    required int indice,
    required Producto producto,
  }) async {
    if (!_indiceValido(indice)) {
      return;
    }

    _productos[indice] = producto;

    await _guardarEstadoActual();
  }

  /// Actualiza un producto mediante su identificador.
  ///
  /// Este método es más estable que depender de la posición
  /// del producto dentro de la lista.
  Future<void> actualizarPorId(Producto producto) async {
    final int indice = _productos.indexWhere((productoActual) {
      return productoActual.id == producto.id;
    });

    if (!_indiceValido(indice)) {
      return;
    }

    _productos[indice] = producto;

    await _guardarEstadoActual();
  }

  // ========================================================
  // CAMBIO DE ESTADO
  // ========================================================

  /// Activa o desactiva un producto sin eliminarlo.
  Future<void> cambiarEstado({
    required int indice,
    required bool activo,
  }) async {
    if (!_indiceValido(indice)) {
      return;
    }

    _productos[indice] = _productos[indice].copiarCon(activo: activo);

    await _guardarEstadoActual();
  }

  // ========================================================
  // ELIMINACIÓN
  // ========================================================

  /// Elimina el producto situado en la posición indicada.
  ///
  /// Si el índice no existe, la colección permanece igual.
  Future<void> eliminar(int indice) async {
    if (!_indiceValido(indice)) {
      return;
    }

    _productos.removeAt(indice);

    await _guardarEstadoActual();
  }

  /// Elimina un producto mediante su identificador.
  Future<void> eliminarPorId(String id) async {
    final int indice = _productos.indexWhere((producto) {
      return producto.id == id;
    });

    if (!_indiceValido(indice)) {
      return;
    }

    _productos.removeAt(indice);

    await _guardarEstadoActual();
  }

  // ========================================================
  // PERSISTENCIA INTERNA
  // ========================================================

  /// Guarda una copia completa del catálogo actual.
  Future<void> _guardarEstadoActual() async {
    await _storageService.guardarProductos(_productos);
  }

  // ========================================================
  // VALIDACIONES INTERNAS
  // ========================================================

  /// Comprueba que el índice corresponda a un producto
  /// existente dentro de la colección.
  bool _indiceValido(int indice) {
    return indice >= 0 && indice < _productos.length;
  }
}
