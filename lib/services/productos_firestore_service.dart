import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/producto.dart';

// ==========================================================
// SERVICIO CLOUD FIRESTORE DE PRODUCTOS
// ==========================================================

/// Gestiona la persistencia compartida del catálogo
/// de productos mediante Cloud Firestore.
///
/// Cada producto utiliza su UUID como identificador:
///
/// `productos/{producto.id}`
class ProductosFirestoreService {
  // ========================================================
  // INSTANCIA COMPARTIDA
  // ========================================================

  /// Instancia única utilizada por el repositorio.
  static final ProductosFirestoreService instancia =
      ProductosFirestoreService._interno();

  /// Constructor privado que evita crear instancias
  /// independientes accidentalmente.
  ProductosFirestoreService._interno();

  // ========================================================
  // FIRESTORE
  // ========================================================

  /// Instancia compartida de Cloud Firestore.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Nombre de la colección remota.
  static const String _nombreColeccion = 'productos';

  /// Referencia tipada a la colección de productos.
  CollectionReference<Map<String, dynamic>> get _coleccion {
    return _firestore.collection(_nombreColeccion);
  }

  // ========================================================
  // COMPROBACIÓN
  // ========================================================

  /// Indica si Firestore ya contiene al menos
  /// un producto registrado.
  Future<bool> existenProductos() async {
    final QuerySnapshot<Map<String, dynamic>> resultado = await _coleccion
        .limit(1)
        .get();

    return resultado.docs.isNotEmpty;
  }

  // ========================================================
  // RECUPERACIÓN
  // ========================================================

  /// Recupera todos los productos almacenados
  /// actualmente en Firestore.
  Future<List<Producto>> obtenerTodos() async {
    final QuerySnapshot<Map<String, dynamic>> resultado = await _coleccion
        .get();

    return _convertirDocumentos(resultado.docs);
  }

  // ========================================================
  // SINCRONIZACIÓN EN TIEMPO REAL
  // ========================================================

  /// Emite una colección actualizada cada vez que Firestore
  /// detecta cambios en el catálogo compartido.
  Stream<List<Producto>> observarCambios() {
    return _coleccion.snapshots().map((snapshot) {
      return _convertirDocumentos(snapshot.docs);
    });
  }

  // ========================================================
  // CREACIÓN Y ACTUALIZACIÓN
  // ========================================================

  /// Crea o reemplaza un producto utilizando su UUID
  /// como identificador del documento remoto.
  Future<void> guardar(Producto producto) async {
    final String idLimpio = producto.id.trim();

    if (idLimpio.isEmpty) {
      throw ArgumentError('El producto debe tener un identificador válido.');
    }

    await _coleccion.doc(idLimpio).set(producto.toMap());
  }

  /// Guarda una colección completa mediante una escritura
  /// por lotes.
  ///
  /// Se utilizará para la primera migración del catálogo
  /// local a Cloud Firestore.
  Future<void> guardarTodos(List<Producto> productos) async {
    if (productos.isEmpty) {
      return;
    }

    final WriteBatch lote = _firestore.batch();

    int cantidadValida = 0;

    for (final Producto producto in productos) {
      final String idLimpio = producto.id.trim();

      if (idLimpio.isEmpty || producto.nombre.trim().isEmpty) {
        continue;
      }

      lote.set(_coleccion.doc(idLimpio), producto.toMap());

      cantidadValida++;
    }

    if (cantidadValida == 0) {
      return;
    }

    await lote.commit();
  }

  // ========================================================
  // ELIMINACIÓN
  // ========================================================

  /// Elimina un producto mediante su UUID.
  Future<void> eliminar(String productoId) async {
    final String idLimpio = productoId.trim();

    if (idLimpio.isEmpty) {
      return;
    }

    await _coleccion.doc(idLimpio).delete();
  }

  // ========================================================
  // CONVERSIONES INTERNAS
  // ========================================================

  /// Convierte documentos de Firestore en productos.
  ///
  /// El identificador real del documento tiene prioridad
  /// sobre cualquier campo `id` almacenado en el mapa.
  List<Producto> _convertirDocumentos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documentos,
  ) {
    final List<Producto> productos = [];

    for (final documento in documentos) {
      final Map<String, dynamic> datos = {
        ...documento.data(),
        'id': documento.id,
      };

      final Producto producto = Producto.fromMap(datos);

      if (producto.id.trim().isEmpty || producto.nombre.trim().isEmpty) {
        continue;
      }

      productos.add(producto);
    }

    productos.sort(
      (primero, segundo) =>
          primero.nombre.toLowerCase().compareTo(segundo.nombre.toLowerCase()),
    );

    return productos;
  }
}
