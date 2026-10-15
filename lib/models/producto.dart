class Producto {
  final String nombre;
  final String categoria;
  final String material;

  final double gramos;
  final double horas;
  final double minutos;

  final double costoProduccion;
  final double precioVenta;

  Producto({
    required this.nombre,
    required this.categoria,
    required this.material,
    required this.gramos,
    required this.horas,
    required this.minutos,
    required this.costoProduccion,
    required this.precioVenta,
  });
}
