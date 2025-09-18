const { body } = require('express-validator');

// Para /auth/register
const registerRules = [
  body('nombre').isString().isLength({ min: 2 }).withMessage('Nombre inválido'),
  body('email').isEmail().withMessage('Email inválido'),
  body('password').isLength({ min: 6 }).withMessage('Password mínima 6')
];

// Para /auth/login
const loginRules = [
  body('email').isEmail().withMessage('Email inválido'),
  body('password').isString().withMessage('Password requerida')
];

// Para /auth/refresh
const refreshRules = [
  body('refresh').isString().withMessage('Refresh token requerido')
];

module.exports = { registerRules, loginRules, refreshRules };
