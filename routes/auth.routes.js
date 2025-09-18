const express = require('express');
const adapter = require('../adapters/authAdapter');

// Middlewares
const validate = require('../middleware/validate');
const { requiereAuth } = require('../middleware/authJwt');
const requireRefreshToken = require('../middleware/requireRefreshToken');
const { checkDuplicateEmail } = require('../middleware/verifySignUp');

// Reglas de validación
const {
  loginRules,
  refreshRules,
  registerRules
} = require('../middleware/validaciones/login');

const r = express.Router();

// Registro (valida campos + evita email duplicado)
r.post('/register', registerRules, validate, checkDuplicateEmail, adapter.register);

// Login (valida credenciales)
r.post('/login', loginRules, validate, adapter.login);

// Refresh (valida body con express-validator y además verifica JWT de refresh)
r.post('/refresh', refreshRules, validate, requireRefreshToken, adapter.refresh);

// Logout: exige refresh token válido para revocar esa sesión
r.post('/logout', requireRefreshToken, adapter.logout);

// Logout de todas las sesiones (requiere access token válido)
r.post('/logout-all', requiereAuth, adapter.logoutAll);

module.exports = r;
