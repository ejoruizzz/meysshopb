const { body, param } = require('express-validator');

// Crear cliente
const crearClienteRules = [
  body('nombre').isString().trim().isLength({ min: 2 }).withMessage('Nombre requerido (mín 2)'),
  body('apellido').isString().trim().isLength({ min: 2 }).withMessage('Apellido requerido (mín 2)'),
  body('email').optional({ nullable: true, checkFalsy: true }).isEmail().withMessage('Email inválido'),
  body('telefono').optional({ nullable: true, checkFalsy: true }).isString().isLength({ min: 3 }).withMessage('Teléfono inválido'),
  body('direccion').optional({ nullable: true, checkFalsy: true }).isString().isLength({ min: 3 }).withMessage('Dirección inválida'),
];

// Actualizar cliente
const actualizarClienteRules = [
  param('id').isInt({ min: 1 }).withMessage('ID inválido'),
  body('nombre').optional({ nullable: true, checkFalsy: true }).isString().trim().isLength({ min: 2 }).withMessage('Nombre requerido (mín 2)'),
  body('apellido').optional({ nullable: true, checkFalsy: true }).isString().trim().isLength({ min: 2 }).withMessage('Apellido requerido (mín 2)'),
  body('email').optional({ nullable: true, checkFalsy: true }).isEmail().withMessage('Email inválido'),
  body('telefono').optional({ nullable: true, checkFalsy: true }).isString().isLength({ min: 3 }).withMessage('Teléfono inválido'),
  body('direccion').optional({ nullable: true, checkFalsy: true }).isString().isLength({ min: 3 }).withMessage('Dirección inválida'),
];

// Eliminar cliente
const eliminarClienteRules = [
  param('id').isInt({ min: 1 }).withMessage('ID inválido')
];

module.exports = { crearClienteRules, actualizarClienteRules, eliminarClienteRules };
