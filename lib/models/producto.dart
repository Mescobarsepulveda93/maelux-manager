// ==========================================================
// MODELO DE PRODUCTO
// ==========================================================

/// Representa un producto perteneciente al catálogo de MAELUX.
///
/// Cada producto posee un identificador estable que permite
/// editarlo, eliminarlo o relacionarlo con otros registros
/// sin depender de su nombre.
///
/// El modelo también está preparado para almacenamiento local
/// y para incorporar una imagen principal.
class Producto {
  // ========================================================
  // IDENTIFICACIÓN
  // ========================================================

  /// Identificador único y permanente del producto.
  final String id;

  /// Nombre comercial o descriptivo del producto.
  final String nombre;

  /// Categoría utilizada para organizar el catálogo.
  final String categoria;

  /// Descripción comercial o administrativa del producto.
  final String descripcion;

  // ========================================================
  // IMAGEN DEL PRODUCTO
  // ========================================================

  /// Referencia opcional a la imagen principal del producto.
  ///
  /// Durante la primera implementación podrá contener una ruta,
  /// URL local o identificador del recurso almacenado.
  ///
  /// Si el valor es nulo o está vacío, la interfaz deberá
  /// mostrar una imagen o icono de reemplazo.
  final String? imagenPrincipal;

  // ========================================================
  // INFORMACIÓN DE FABRICACIÓN
  // ========================================================

  /// Nombre del material utilizado para fabricar el producto.
  final String material;

  /// Cantidad total de filamento utilizada, expresada en gramos.
  final double gramos;

  /// Horas completas necesarias para fabricar el producto.
  final double horas;

  /// Minutos adicionales necesarios para fabricar el producto.
  final double minutos;

  // ========================================================
  // INFORMACIÓN ECONÓMICA
  // ========================================================

  /// Coste interno estimado para fabricar una unidad.
  final double costoProduccion;

  /// Precio de venta definido para una unidad.
  final double precioVenta;

  // ========================================================
  // ESTADO DEL PRODUCTO
  // ========================================================

  /// Indica si el producto debe aparecer como disponible
  /// dentro del catálogo.
  final bool activo;

  const Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.material,
    required this.gramos,
    required this.horas,
    required this.minutos,
    required this.costoProduccion,
    required this.precioVenta,
    this.descripcion = '',
    this.imagenPrincipal,
    this.activo = true,
  });

  // ========================================================
  // VALORES CALCULADOS
  // ========================================================

  /// Devuelve el tiempo total de fabricación expresado
  /// en minutos.
  double get tiempoTotalMinutos {
    return (horas * 60) + minutos;
  }

  /// Devuelve el tiempo de fabricación expresado
  /// en horas decimales.
  ///
  /// Ejemplo:
  ///
  /// 1 hora y 30 minutos equivalen a 1,5 horas.
  double get tiempoDecimalHoras {
    return horas + (minutos / 60);
  }

  /// Indica si el producto tiene una referencia válida
  /// para su imagen principal.
  bool get tieneImagen {
    return imagenPrincipal != null && imagenPrincipal!.trim().isNotEmpty;
  }

  // ========================================================
  // SERIALIZACIÓN
  // ========================================================

  /// Convierte el producto en un mapa que puede serializarse
  /// y guardarse en el almacenamiento local.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'descripcion': descripcion,
      'imagenPrincipal': imagenPrincipal,
      'material': material,
      'gramos': gramos,
      'horas': horas,
      'minutos': minutos,
      'costoProduccion': costoProduccion,
      'precioVenta': precioVenta,
      'activo': activo,
    };
  }

  /// Construye un producto desde un mapa recuperado
  /// del almacenamiento local.
  ///
  /// Se aplican valores seguros cuando un campo opcional
  /// no está disponible.
  factory Producto.fromMap(Map<String, dynamic> mapa) {
    return Producto(
      id: mapa['id']?.toString() ?? '',
      nombre: mapa['nombre']?.toString() ?? '',
      categoria: mapa['categoria']?.toString() ?? 'Otros',
      descripcion: mapa['descripcion']?.toString() ?? '',
      imagenPrincipal: _convertirAImagen(mapa['imagenPrincipal']),
      material: mapa['material']?.toString() ?? '',
      gramos: _convertirADouble(mapa['gramos']),
      horas: _convertirADouble(mapa['horas']),
      minutos: _convertirADouble(mapa['minutos']),
      costoProduccion: _convertirADouble(mapa['costoProduccion']),
      precioVenta: _convertirADouble(mapa['precioVenta']),
      activo: mapa['activo'] is bool ? mapa['activo'] as bool : true,
    );
  }

  // ========================================================
  // COPIA Y ACTUALIZACIÓN
  // ========================================================

  /// Genera una copia del producto reemplazando únicamente
  /// los valores indicados.
  ///
  /// El identificador se conserva de forma predeterminada.
  Producto copiarCon({
    String? id,
    String? nombre,
    String? categoria,
    String? descripcion,
    String? imagenPrincipal,
    bool eliminarImagen = false,
    String? material,
    double? gramos,
    double? horas,
    double? minutos,
    double? costoProduccion,
    double? precioVenta,
    bool? activo,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
      imagenPrincipal: eliminarImagen
          ? null
          : imagenPrincipal ?? this.imagenPrincipal,
      material: material ?? this.material,
      gramos: gramos ?? this.gramos,
      horas: horas ?? this.horas,
      minutos: minutos ?? this.minutos,
      costoProduccion: costoProduccion ?? this.costoProduccion,
      precioVenta: precioVenta ?? this.precioVenta,
      activo: activo ?? this.activo,
    );
  }

  // ========================================================
  // CONVERSIONES INTERNAS
  // ========================================================

  /// Convierte un valor dinámico en un número decimal.
  ///
  /// Permite recuperar valores almacenados como `int`,
  /// `double`, otros tipos numéricos o texto.
  static double _convertirADouble(dynamic valor) {
    if (valor is num) {
      return valor.toDouble();
    }

    if (valor is String) {
      return double.tryParse(valor.replaceAll(',', '.')) ?? 0;
    }

    return 0;
  }

  /// Convierte una referencia de imagen en un valor válido.
  ///
  /// Los textos vacíos se interpretan como ausencia de imagen.
  static String? _convertirAImagen(dynamic valor) {
    final String? texto = valor?.toString();

    if (texto == null || texto.trim().isEmpty) {
      return null;
    }

    return texto;
  }
}
