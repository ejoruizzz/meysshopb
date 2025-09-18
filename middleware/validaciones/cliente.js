const { body, param } = require('express-validator');

// Crear cliente
const crearClienteRules = [
  body('nombre').isString().isLength({ min: 2 }).withMessage('Nombre requerido (mín 2)'),
  body('apellido').isString().isLength({ min: 2 }).withMessage('Apellido requerido (mín 2)'),
  body('email').optional({ nullable: true }).isEmail().withMessage('Email inválido'),
  body('telefono').optional({ nullable: true }).isString(),
  body('direccion').optional({ nullable: true }).isString()
];

// Actualizar cliente
const actualizarClienteRules = [
  param('id').isInt({ min: 1 }).withMessage('ID inválido'),
  body('email').optional({ nullable: true }).isEmail().withMessage('Email inválido')
];

// Eliminar cliente
const eliminarClienteRules = [
  param('id').isInt({ min: 1 }).withMessage('ID inválido')
];

module.exports = { crearClienteRules, actualizarClienteRules, eliminarClienteRules };
