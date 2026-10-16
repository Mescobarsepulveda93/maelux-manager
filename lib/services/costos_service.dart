class CostosService {
  static double calcularMaterial(double gramos, double precioKg) {
    return (gramos / 1000) * precioKg;
  }

  static double calcularTiempo(double minutos) {
    return minutos * 2;
  }

  static double calcularTotal(double material, double tiempo) {
    return material + tiempo;
  }
}
