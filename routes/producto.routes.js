const express = require('express');
const adapter = require('../adapters/clienteAdapter');
const validate = require('../middleware/validate');
const { requiereAuth, requiereAdmin } = require('../middleware/authJwt');
const { handleSingle } = require('../middleware/uploadProductImage');
const {
  crearClienteRules,
  actualizarClienteRules,
  eliminarClienteRules,
} = require('../middleware/validaciones/cliente');

const r = express.Router();

r.get('/', adapter.listar);

r.post(
  '/',
  requiereAuth,
  requiereAdmin,
  handleSingle('imagen'),
  crearClienteRules,
  validate,
  adapter.crear,
);

r.put(
  '/:id',
  requiereAuth,
  requiereAdmin,
  handleSingle('imagen'),
  actualizarClienteRules,
  validate,
  adapter.actualizar,
);

r.delete(
  '/:id',
  requiereAuth,
  requiereAdmin,
  eliminarClienteRules,
  validate,
  adapter.eliminar,
);

module.exports = r;
