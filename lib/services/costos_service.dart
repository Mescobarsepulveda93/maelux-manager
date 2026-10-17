import '../models/material_3d.dart';

class CostosService {
  static double calcularMaterial(double gramos, Material3D material) {
    return (gramos / 1000) * material.precioKg;
  }

  static double calcularElectricidad(double minutos) {
    const double costoHora = 27.5;

    return (minutos / 60) * costoHora;
  }

  static double calcularDesgaste(double minutos) {
    const double desgasteHora = 125;

    return (minutos / 60) * desgasteHora;
  }

  static double calcularPackaging() {
    return 50;
  }

  static double calcularGastosBancarios() {
    return 305;
  }

  static double calcularGetnet(double subtotal) {
    return subtotal * 0.0211;
  }
}
