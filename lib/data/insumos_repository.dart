import '../models/insumo.dart';
import 'insumos_demo.dart';

// ==========================================================
// REPOSITORIO COMPARTIDO DE INSUMOS
// ==========================================================

/// Centraliza temporalmente la lista de insumos de MAELUX.
///
/// Este repositorio permite que Gestión de insumos y el
/// Cotizador trabajen con la misma colección durante la
/// ejecución de la aplicación.
///
/// En una etapa posterior, este repositorio se conectará
/// con almacenamiento local o una base de datos.
class InsumosRepository {
  // ========================================================
  // INSTANCIA COMPARTIDA
  // ========================================================

  /// Instancia única utilizada por todas las pantallas.
  static final InsumosRepository instancia = InsumosRepository._interno();

  /// Constructor privado que impide crear repositorios
  /// independientes accidentalmente.
  InsumosRepository._interno();

  // ========================================================
  // ALMACENAMIENTO TEMPORAL
  // ========================================================

  /// Lista modificable inicializada con los datos demostrativos.
  ///
  /// Los cambios permanecerán disponibles mientras la aplicación
  /// continúe ejecutándose.
  final List<Insumo> _insumos = List<Insumo>.from(insumosDemo);

  // ========================================================
  // CONSULTAS
  // ========================================================

  /// Devuelve una copia de todos los insumos registrados.
  ///
  /// La copia evita que otras pantallas modifiquen directamente
  /// la lista interna del repositorio.
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

  /// Devuelve la cantidad de insumos actualmente activos.
  int get cantidadActivos {
    return _insumos.where((insumo) => insumo.activo).length;
  }

  // ========================================================
  // CREACIÓN
  // ========================================================

  /// Agrega un nuevo insumo al final de la lista.
  void agregar(Insumo insumo) {
    _insumos.add(insumo);
  }

  // ========================================================
  // EDICIÓN
  // ========================================================

  /// Reemplaza el insumo situado en la posición indicada.
  ///
  /// Si el índice no existe, la operación no modifica la lista.
  void actualizar({required int indice, required Insumo insumo}) {
    if (!_indiceValido(indice)) {
      return;
    }

    _insumos[indice] = insumo;
  }

  // ========================================================
  // CAMBIO DE ESTADO
  // ========================================================

  /// Activa o desactiva un insumo existente.
  ///
  /// El registro permanece guardado aunque quede desactivado.
  void cambiarEstado({required int indice, required bool activo}) {
    if (!_indiceValido(indice)) {
      return;
    }

    _insumos[indice] = _insumos[indice].copiarCon(activo: activo);
  }

  // ========================================================
  // ELIMINACIÓN
  // ========================================================

  /// Elimina el insumo situado en la posición indicada.
  ///
  /// Si el índice no existe, la lista permanece sin cambios.
  void eliminar(int indice) {
    if (!_indiceValido(indice)) {
      return;
    }

    _insumos.removeAt(indice);
  }

  // ========================================================
  // VALIDACIONES INTERNAS
  // ========================================================

  /// Comprueba que el índice recibido corresponda
  /// a un elemento existente dentro de la lista.
  bool _indiceValido(int indice) {
    return indice >= 0 && indice < _insumos.length;
  }
}
