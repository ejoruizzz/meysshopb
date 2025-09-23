const express = require('express');
const adapter = require('../adapters/productoAdapter');
const validate = require('../middleware/validate');
const { requiereAuth, requiereAdmin } = require('../middleware/authJwt');
const { handleSingle } = require('../middleware/uploadProductImage');
const {
  crearProductoRules,
  actualizarProductoRules,
  eliminarProductoRules,
} = require('../middleware/validaciones/producto');

const r = express.Router();

r.get('/', adapter.listar);

r.post(
  '/',
  requiereAuth,
  requiereAdmin,
  handleSingle('imagen'),
  crearProductoRules,
  validate,
  adapter.crear,
);

r.put(
  '/:id',
  requiereAuth,
  requiereAdmin,
  handleSingle('imagen'),
  actualizarProductoRules,
  validate,
  adapter.actualizar,
);

r.delete(
  '/:id',
  requiereAuth,
  requiereAdmin,
  eliminarProductoRules,
  validate,
  adapter.eliminar,
);

module.exports = r;
