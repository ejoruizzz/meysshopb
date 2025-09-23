const { body, param } = require('express-validator');

const getPrecioValor = (req) => (req.body.precio !== undefined ? req.body.precio : req.body.price);
const getStockValor = (req) => (req.body.stock !== undefined ? req.body.stock : req.body.cantidad);

const validarPrecioRequerido = (value, { req }) => {
  const raw = getPrecioValor(req);
  if (raw === undefined || raw === null || raw === '') {
    throw new Error('Precio inválido');
  }
  const parsed = Number.parseFloat(raw);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error('Precio inválido');
  }
  return true;
};

const validarPrecioOpcional = (value, { req }) => {
  const provided = req.body.precio !== undefined || req.body.price !== undefined;
  if (!provided) return true;
  const raw = getPrecioValor(req);
  if (raw === undefined || raw === null || raw === '') {
    throw new Error('Precio inválido');
  }
  const parsed = Number.parseFloat(raw);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error('Precio inválido');
  }
  return true;
};

const validarStockRequerido = (value, { req }) => {
  const raw = getStockValor(req);
  if (raw === undefined || raw === null || raw === '') {
    throw new Error('Stock inválido');
  }
  const parsed = Number.parseInt(raw, 10);
  if (!Number.isFinite(parsed) || parsed < 0) {
    throw new Error('Stock inválido');
  }
  return true;
};

const validarStockOpcional = (value, { req }) => {
  const provided = req.body.stock !== undefined || req.body.cantidad !== undefined;
  if (!provided) return true;
  const raw = getStockValor(req);
  if (raw === undefined || raw === null || raw === '') {
    throw new Error('Stock inválido');
  }
  const parsed = Number.parseInt(raw, 10);
  if (!Number.isFinite(parsed) || parsed < 0) {
    throw new Error('Stock inválido');
  }
  return true;
};

const crearProductoRules = [
  body('nombre').isString().trim().isLength({ min: 2 }).withMessage('Nombre requerido (mín 2)'),
  body('descripcion').isString().trim().isLength({ min: 5 }).withMessage('Descripción requerida (mín 5)'),
  body('categoria').isString().trim().isLength({ min: 2 }).withMessage('Categoría requerida (mín 2)'),
  body('precio').custom(validarPrecioRequerido),
  body('stock').custom(validarStockRequerido),
  body('estado').optional({ nullable: true }).isString().isLength({ min: 1, max: 50 })
];

const actualizarProductoRules = [
  param('id').isInt({ min: 1 }).withMessage('ID inválido'),
  body('nombre').optional({ nullable: true }).isString().trim().isLength({ min: 2 }).withMessage('Nombre requerido (mín 2)'),
  body('descripcion').optional({ nullable: true }).isString().trim().isLength({ min: 5 }).withMessage('Descripción inválida (mín 5)'),
  body('categoria').optional({ nullable: true }).isString().trim().isLength({ min: 2 }).withMessage('Categoría inválida (mín 2)'),
  body('precio').custom(validarPrecioOpcional),
  body('stock').custom(validarStockOpcional),
  body('estado').optional({ nullable: true }).isString().isLength({ min: 1, max: 50 })
];

const eliminarProductoRules = [
  param('id').isInt({ min: 1 }).withMessage('ID inválido')
];

module.exports = { crearProductoRules, actualizarProductoRules, eliminarProductoRules };
