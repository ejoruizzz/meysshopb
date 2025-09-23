const { body, param } = require('express-validator');

// Crear cliente
const crearClienteRules = [
  body('nombre').isString().isLength({ min: 2 }).withMessage('Nombre requerido (mín 2)'),
  body('apellido').isString().isLength({ min: 2 }).withMessage('Apellido requerido (mín 2)'),
  body('email').optional({ nullable: true }).isEmail().withMessage('Email inválido'),
  body('telefono').optional({ nullable: true }).isString(),
  body('direccion').optional({ nullable: true }).isString(),
  body('price').isFloat({ gt: 0 }).withMessage('Precio inválido'),
  body('cantidad').isInt({ min: 0 }).withMessage('Cantidad inválida'),
  body('estado').optional({ nullable: true }).isString().isLength({ min: 1, max: 50 }),
];

// Actualizar cliente
const actualizarClienteRules = [
  param('id').isInt({ min: 1 }).withMessage('ID inválido'),
  body('email').optional({ nullable: true }).isEmail().withMessage('Email inválido'),
  body('price').optional({ nullable: true }).isFloat({ gt: 0 }).withMessage('Precio inválido'),
  body('cantidad').optional({ nullable: true }).isInt({ min: 0 }).withMessage('Cantidad inválida'),
  body('estado').optional({ nullable: true }).isString().isLength({ min: 1, max: 50 }),
];

// Eliminar cliente
const eliminarClienteRules = [
  param('id').isInt({ min: 1 }).withMessage('ID inválido')
];

module.exports = { crearClienteRules, actualizarClienteRules, eliminarClienteRules };
