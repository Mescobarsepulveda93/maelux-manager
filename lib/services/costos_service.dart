import '../models/material_3d.dart';

class CostosService {
  static double calcularMaterial(double gramos, Material3D material) {
    return (gramos / 1000) * material.precioKg;
  }

  static double calcularTiempo(double minutos) {
    return minutos * 2;
  }

  static double calcularTotal(double material, double tiempo) {
    return material + tiempo;
  }
}
