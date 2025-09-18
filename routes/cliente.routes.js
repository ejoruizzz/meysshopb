const express = require('express');
const adapter = require('../adapters/clienteAdapter');
const validate = require('../middleware/validate');
const { requiereAuth, requiereAdmin } = require('../middleware/authJwt');
const {
  crearClienteRules,
  actualizarClienteRules,
  eliminarClienteRules
} = require('../middleware/validaciones/cliente');

const r = express.Router();

// Listar (público; si quieres, protégelo con requiereAuth)
r.get('/', adapter.listar);

// Crear (solo admin)
r.post(
  '/',
  requiereAuth,
  requiereAdmin,
  crearClienteRules,
  validate,
  adapter.crear
);

// Actualizar (solo admin)
r.put(
  '/:id',
  requiereAuth,
  requiereAdmin,
  actualizarClienteRules,
  validate,
  adapter.actualizar
);

// Eliminar (solo admin)
r.delete(
  '/:id',
  requiereAuth,
  requiereAdmin,
  eliminarClienteRules,
  validate,
  adapter.eliminar
);

module.exports = r;
