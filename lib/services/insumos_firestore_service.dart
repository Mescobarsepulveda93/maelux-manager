import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/insumo.dart';

// ==========================================================
// SERVICIO CLOUD FIRESTORE DE INSUMOS
// ==========================================================

/// Gestiona la persistencia compartida de los insumos
/// almacenados en Cloud Firestore.
///
/// Cada insumo utiliza su UUID como identificador estable:
///
/// `insumos/{insumo.id}`
///
/// De esta forma, todos los dispositivos consultan y
/// modifican exactamente el mismo registro.
class InsumosFirestoreService {
  // ========================================================
  // INSTANCIA COMPARTIDA
  // ========================================================

  /// Instancia única utilizada por el repositorio.
  static final InsumosFirestoreService instancia =
      InsumosFirestoreService._interno();

  /// Constructor privado para evitar instancias separadas.
  InsumosFirestoreService._interno();

  // ========================================================
  // FIRESTORE
  // ========================================================

  /// Instancia compartida de Cloud Firestore.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Nombre de la colección remota de insumos.
  static const String _nombreColeccion = 'insumos';

  /// Referencia tipada a la colección compartida.
  CollectionReference<Map<String, dynamic>> get _coleccion {
    return _firestore.collection(_nombreColeccion);
  }

  // ========================================================
  // COMPROBACIÓN DE DATOS
  // ========================================================

  /// Indica si Firestore ya contiene al menos un insumo.
  ///
  /// Se consulta únicamente un documento para reducir
  /// las lecturas necesarias durante la inicialización.
  Future<bool> existenInsumos() async {
    final QuerySnapshot<Map<String, dynamic>> resultado = await _coleccion
        .limit(1)
        .get();

    return resultado.docs.isNotEmpty;
  }

  // ========================================================
  // RECUPERACIÓN
  // ========================================================

  /// Recupera todos los insumos actualmente almacenados
  /// en Cloud Firestore.
  ///
  /// Los datos se ordenan localmente por nombre para evitar
  /// depender del orden interno de los documentos.
  Future<List<Insumo>> obtenerTodos() async {
    final QuerySnapshot<Map<String, dynamic>> resultado = await _coleccion
        .get();

    return _convertirDocumentos(resultado.docs);
  }

  // ========================================================
  // SINCRONIZACIÓN EN TIEMPO REAL
  // ========================================================

  /// Emite una colección actualizada cada vez que Firestore
  /// detecta un cambio en los insumos compartidos.
  ///
  /// Esto permite que un cambio realizado desde un ordenador
  /// aparezca posteriormente en los demás dispositivos.
  Stream<List<Insumo>> observarCambios() {
    return _coleccion.snapshots().map((snapshot) {
      return _convertirDocumentos(snapshot.docs);
    });
  }

  // ========================================================
  // CREACIÓN Y ACTUALIZACIÓN
  // ========================================================

  /// Crea o reemplaza un insumo utilizando su UUID
  /// como identificador del documento.
  Future<void> guardar(Insumo insumo) async {
    final String idLimpio = insumo.id.trim();

    if (idLimpio.isEmpty) {
      throw ArgumentError('El insumo debe tener un identificador válido.');
    }

    await _coleccion.doc(idLimpio).set(insumo.toMap());
  }

  /// Guarda una colección completa mediante una escritura
  /// por lotes.
  ///
  /// Este método se utilizará durante la primera migración
  /// de los insumos locales hacia Firestore.
  Future<void> guardarTodos(List<Insumo> insumos) async {
    if (insumos.isEmpty) {
      return;
    }

    final WriteBatch lote = _firestore.batch();

    int cantidadValida = 0;

    for (final Insumo insumo in insumos) {
      final String idLimpio = insumo.id.trim();

      if (idLimpio.isEmpty) {
        continue;
      }

      lote.set(_coleccion.doc(idLimpio), insumo.toMap());

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

  /// Elimina un insumo utilizando su UUID.
  Future<void> eliminar(String insumoId) async {
    final String idLimpio = insumoId.trim();

    if (idLimpio.isEmpty) {
      return;
    }

    await _coleccion.doc(idLimpio).delete();
  }

  // ========================================================
  // CONVERSIONES INTERNAS
  // ========================================================

  /// Convierte documentos de Firestore en objetos [Insumo].
  ///
  /// El ID del documento tiene prioridad para garantizar
  /// que el identificador remoto y el modelo coincidan.
  List<Insumo> _convertirDocumentos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documentos,
  ) {
    final List<Insumo> insumos = [];

    for (final documento in documentos) {
      final Map<String, dynamic> datos = {
        ...documento.data(),
        'id': documento.id,
      };

      final Insumo insumo = Insumo.fromMap(datos);

      if (insumo.id.trim().isEmpty) {
        continue;
      }

      insumos.add(insumo);
    }

    insumos.sort(
      (primero, segundo) =>
          primero.nombre.toLowerCase().compareTo(segundo.nombre.toLowerCase()),
    );

    return insumos;
  }
}
