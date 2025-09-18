const { validationResult } = require('express-validator');

module.exports = (req, res, next) => {
  const errors = validationResult(req);
  if (errors.isEmpty()) return next();

  const first = errors.array()[0];
  return res.status(400).json({
    error: first.msg || 'Datos inválidos',
    field: first.path
  });
};
