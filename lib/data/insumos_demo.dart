import '../models/insumo.dart';

// ==========================================================
// INSUMOS TEMPORALES PARA DESARROLLO
// ==========================================================

/// Lista provisional utilizada para desarrollar y probar
/// la pantalla de gestión de insumos.
///
/// Posteriormente, estos registros procederán del
/// almacenamiento local o de una base de datos.
const List<Insumo> insumosDemo = [
  Insumo(
    nombre: 'Bolsa transparente pequeña',
    categoria: 'Packaging',
    unidadMedida: 'unidad',
    costoCompra: 5000,
    cantidadComprada: 100,
  ),
  Insumo(
    nombre: 'Caja de cartón pequeña',
    categoria: 'Packaging',
    unidadMedida: 'unidad',
    costoCompra: 12000,
    cantidadComprada: 50,
  ),
  Insumo(
    nombre: 'Sticker MAELUX',
    categoria: 'Stickers y etiquetas',
    unidadMedida: 'unidad',
    costoCompra: 8000,
    cantidadComprada: 200,
  ),
  Insumo(
    nombre: 'Argolla metálica',
    categoria: 'Argollas',
    unidadMedida: 'unidad',
    costoCompra: 7000,
    cantidadComprada: 100,
  ),
  Insumo(
    nombre: 'Imán circular',
    categoria: 'Imanes',
    unidadMedida: 'unidad',
    costoCompra: 9000,
    cantidadComprada: 100,
  ),
  Insumo(
    nombre: 'Pegamento instantáneo',
    categoria: 'Adhesivos',
    unidadMedida: 'mililitro',
    costoCompra: 4500,
    cantidadComprada: 20,
  ),
];
